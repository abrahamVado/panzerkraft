import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_providers.dart';
import '../../services/dashboard/dashboard_current_trip_service.dart';
import '../../services/dashboard/dashboard_metrics_service.dart';
import '../../router/app_router.dart';
import 'widgets/finance_overview.dart';

//1.1.- dashboardFinanceRangeProvider conserva el periodo mostrado en finanzas.
final dashboardFinanceRangeProvider =
    StateProvider<FinanceRange>((ref) => FinanceRange.week);

//1.- dashboardCreateRideButtonKey permite que las pruebas verifiquen el CTA principal.
const dashboardCreateRideButtonKey = Key('dashboard_create_ride_button');

//2.- DashboardScreen compone el tablero inicial posterior al login.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  //2.1.- _logout restablece la sesión y regresa a la pantalla de acceso.
  void _logout(BuildContext context, WidgetRef ref) {
    ref.read(signedInRiderProvider.notifier).state = null;
    context.goNamed(AppRoute.login.name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //3.- build observa el rider, métricas agregadas y viaje actual del tablero.
    final rider = ref.watch(signedInRiderProvider);
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final currentTripAsync = ref.watch(dashboardCurrentTripProvider);
    final selectedFinanceRange = ref.watch(dashboardFinanceRangeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de control'),
        actions: [
          IconButton(
            onPressed: () => _logout(context, ref),
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: rider == null
          ? const Center(child: Text('Inicia sesión para ver tu tablero.'))
          : metricsAsync.when(
              data: (metrics) {
                final currentTrip = currentTripAsync.asData?.value;
                final currentTripSection = currentTripAsync.when(
                  data: (trip) => _buildCurrentTrip(context, trip),
                  loading: () => const Text('Cargando viaje en curso...'),
                  error: (error, stackTrace) => const Text('No pudimos cargar tu viaje actual.'),
                );
                final colorScheme = Theme.of(context).colorScheme;
                final rideTrend = _generateRideTrend(metrics);
                final panicEnabled = _isTripAccepted(currentTrip);
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _DashboardGreetingBanner(riderName: rider.name, metrics: metrics),
                    const SizedBox(height: 16),
                    //4.- LayoutBuilder ajusta las tarjetas para garantizar una altura mínima.
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const spacing = 12.0;
                        const minHeight = 240.0;
                        final maxWidth = constraints.maxWidth;
                        const crossAxisCount = 3;
                        final totalSpacing = spacing * (crossAxisCount - 1);
                        final clampedWidth =
                            (maxWidth - totalSpacing).clamp(160.0, double.infinity)
                                as double;
                        final itemWidth = clampedWidth / crossAxisCount;
                        final aspectRatio = itemWidth / minHeight;
                        final quickStats = [
                          _DashboardQuickStat(
                            icon: Icons.account_balance,
                            title: 'Banco',
                            value: metrics.bankName,
                            description: 'Gestiona tus datos bancarios y cobros.',
                            background: colorScheme.primaryContainer,
                            foreground: colorScheme.onPrimaryContainer,
                            actionLabel: 'Actualizar',
                            onAction: () => context.pushNamed(AppRoute.bankInfo.name),
                          ),
                          _DashboardQuickStat(
                            icon: Icons.credit_card,
                            title: 'Cuenta',
                            value: rider.email,
                            description: 'Edita tu perfil y datos de contacto.',
                            background: colorScheme.secondaryContainer,
                            foreground: colorScheme.onSecondaryContainer,
                            actionLabel: 'Editar',
                            onAction: () => context.pushNamed(AppRoute.riderProfile.name),
                          ),
                          _DashboardQuickStat(
                            icon: Icons.star_rate,
                            title: 'Evaluación',
                            value: '${metrics.evaluationScore} / 5',
                            description:
                                'Revisa el promedio de satisfacción de tus pasajeros.',
                            background: colorScheme.tertiaryContainer,
                            foreground: colorScheme.onTertiaryContainer,
                            actionLabel: 'Ver opiniones',
                            onAction: () =>
                                _showComingSoon(context, 'las opiniones detalladas'),
                          ),
                          _DashboardQuickStat(
                            icon: Icons.event_available,
                            title: 'Reserva',
                            value: 'Anticipa viajes',
                            description:
                                'Registra traslados programados para tus clientes frecuentes.',
                            background: colorScheme.surfaceVariant,
                            foreground: colorScheme.onSurfaceVariant,
                            actionLabel: 'Crear',
                            onAction: () => context.pushNamed(AppRoute.reservation.name),
                          ),
                          _DashboardQuickStat(
                            icon: Icons.warning_amber_outlined,
                            title: 'Panic Button',
                            value:
                                panicEnabled ? 'Listo para usar' : 'Sin viaje aceptado',
                            description:
                                'Activa asistencia inmediata cuando tu seguridad esté en riesgo.',
                            background: colorScheme.errorContainer,
                            foreground: colorScheme.onErrorContainer,
                            actionLabel: 'Alerta',
                            isEnabled: panicEnabled,
                            onAction: () => context.pushNamed(
                              AppRoute.panicButton.name,
                              extra: currentTrip,
                            ),
                          ),
                          _DashboardQuickStat(
                            icon: Icons.support_agent,
                            title: 'Contáctanos',
                            value: 'Soporte 24/7',
                            description:
                                'Habla con nuestro equipo para resolver dudas y reportes.',
                            background: colorScheme.inversePrimary,
                            foreground: colorScheme.onPrimary,
                            actionLabel: 'Abrir',
                            onAction: () => context.pushNamed(AppRoute.contact.name),
                          ),
                        ];
                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: spacing,
                          mainAxisSpacing: spacing,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: aspectRatio,
                          children: quickStats,
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _DashboardSection(
                      title: 'Rendimiento de la semana',
                      accentColor: colorScheme.primary,
                      actionLabel: 'Ver historial',
                      onAction: () => context.pushNamed(AppRoute.travelHistory.name),
                      children: [
                        Text(
                          'Has completado ${metrics.completedRidesThisWeek} viajes con ${metrics.cancelledRidesThisWeek} cancelaciones.',
                        ),
                        const SizedBox(height: 12),
                        _RideTrendChart(data: rideTrend, color: colorScheme.primary),
                      ],
                    ),
                    _DashboardSection(
                      title: 'Finanzas',
                      accentColor: colorScheme.secondary,
                      actionLabel: 'Exportar',
                      onAction: () =>
                          _showComingSoon(context, 'la exportación de finanzas'),
                      children: [
                        FinanceRangeSelector(
                          selectedRange: selectedFinanceRange,
                          onChanged: (range) => ref
                              .read(dashboardFinanceRangeProvider.notifier)
                              .state = range,
                        ),
                        const SizedBox(height: 16),
                        FinanceStatsGrid(
                          snapshot: metrics.snapshotFor(selectedFinanceRange),
                          acceptanceRate: metrics.acceptanceRate.toDouble(),
                        ),
                      ],
                    ),
                    _DashboardSection(
                      title: 'Viaje en curso',
                      accentColor: colorScheme.tertiary,
                      actionLabel: 'Ver detalles',
                      onAction: () {
                        currentTripAsync.whenData((trip) {
                          if (trip == null) {
                            _showComingSoon(context, 'los detalles del viaje');
                          } else {
                            context.pushNamed(
                              AppRoute.currentTripDetails.name,
                              extra: trip,
                            );
                          }
                        });
                      },
                      children: [currentTripSection],
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      key: dashboardCreateRideButtonKey,
                      onPressed: () {
                        //6.- Navegamos al mapa mediante GoRouter para mantener un stack consistente.
                        context.pushNamed(AppRoute.rideMap.name);
                      },
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: const Text('Crear viaje de taxi'),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Ocurrió un problema al cargar tus métricas. Intenta nuevamente más tarde.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
    );
  }

  //4.- _buildCurrentTrip presenta el estado del viaje o un fallback cuando no existe.
  Widget _buildCurrentTrip(BuildContext context, DashboardCurrentTrip? trip) {
    if (trip == null) {
      return const Text('No tienes viajes activos en este momento.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pasajero: ${trip.passengerName}'),
        Text('Recoger en: ${trip.pickupAddress}'),
        Text('Destino: ${trip.dropoffAddress}'),
        Text('Estado: ${trip.status}'),
        Text('Placas: ${trip.vehiclePlate}'),
        Text('ETA: ${trip.etaMinutes} min'),
        Text('Monto estimado: ${trip.amount.toStringAsFixed(2)} MXN'),
        Text('Duración estimada: ${trip.durationMinutes} min'),
        Text('Distancia estimada: ${trip.distanceKm.toStringAsFixed(1)} km'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => context.pushNamed(
                AppRoute.driverProfile.name,
                extra: trip,
              ),
              icon: const Icon(Icons.person_outline),
              label: const Text('Perfil del conductor'),
            ),
            FilledButton.tonalIcon(
              onPressed: () => context.pushNamed(
                AppRoute.currentTripDetails.name,
                extra: trip,
              ),
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('Detalles del viaje'),
            ),
            OutlinedButton.icon(
              onPressed: () => _confirmCancelTrip(context),
              icon: const Icon(Icons.cancel),
              label: const Text('Cancelar viaje'),
            ),
          ],
        ),
      ],
    );
  }

  //15.- _confirmCancelTrip centraliza la confirmación para cancelar un viaje activo.
  Future<void> _confirmCancelTrip(BuildContext context) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar viaje'),
        content: const Text('¿Confirmas que deseas cancelar este viaje?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancelar viaje'),
          ),
        ],
      ),
    );
    if (shouldCancel == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Se envió la solicitud de cancelación.')),
      );
    }
  }

  //16.- _showComingSoon brinda retroalimentación rápida para acciones informativas.
  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pronto podrás acceder a $feature.')),
    );
  }

  //17.- _isTripAccepted evalúa el estado textual para activar el botón de pánico.
  bool _isTripAccepted(DashboardCurrentTrip? trip) {
    if (trip == null) {
      return false;
    }
    final normalizedStatus = trip.status.toLowerCase();
    return normalizedStatus.contains('acept') ||
        normalizedStatus.contains('curso') ||
        normalizedStatus.contains('recogiendo') ||
        normalizedStatus.contains('camino');
  }
}

//5.- _DashboardSection estiliza cada bloque de información del tablero con acentos de color.
class _DashboardSection extends StatelessWidget {
  const _DashboardSection({
    required this.title,
    required this.children,
    this.accentColor,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final List<Widget> children;
  final Color? accentColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headlineStyle = theme.textTheme.titleMedium?.copyWith(
      color: accentColor ?? theme.colorScheme.onSurface,
      fontWeight: FontWeight.w600,
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: (accentColor ?? theme.colorScheme.outlineVariant).withOpacity(0.4)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 24,
                  decoration: BoxDecoration(
                    color: accentColor ?? theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: headlineStyle,
                  ),
                ),
                if (actionLabel != null)
                  TextButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.open_in_new),
                    label: Text(actionLabel!),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

//6.- _DashboardGreetingBanner pinta un encabezado con gradiente y resumen rápido.
class _DashboardGreetingBanner extends StatelessWidget {
  const _DashboardGreetingBanner({required this.riderName, required this.metrics});

  final String riderName;
  final DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hola, $riderName',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tus métricas siguen saludables. Mantén tu ritmo para conservar el bono semanal.',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onPrimary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _BannerTile(
                label: 'Viajes',
                value: '${metrics.completedRidesThisWeek}',
                icon: Icons.local_taxi,
              ),
              const SizedBox(width: 12),
              _BannerTile(
                label: 'Bonos activos',
                value: '${metrics.acceptanceRate}%',
                icon: Icons.emoji_events_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

//7.- _BannerTile muestra cifras compactas dentro del encabezado.
class _BannerTile extends StatelessWidget {
  const _BannerTile({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.onPrimary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.onPrimary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onPrimary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

//8.- _DashboardQuickStat genera tarjetas compactas para metadatos.
class _DashboardQuickStat extends StatelessWidget {
  const _DashboardQuickStat({
    required this.icon,
    required this.title,
    required this.value,
    required this.description,
    required this.background,
    required this.foreground,
    required this.actionLabel,
    required this.onAction,
    this.isEnabled = true,
  });

  final IconData icon;
  final String title;
  final String value;
  final String description;
  final Color background;
  final Color foreground;
  final String actionLabel;
  final VoidCallback onAction;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = isEnabled ? foreground : foreground.withOpacity(0.45);
    final titleColor = isEnabled ? foreground.withOpacity(0.85) : foreground.withOpacity(0.4);
    final bodyColor = isEnabled ? foreground.withOpacity(0.9) : foreground.withOpacity(0.35);
    final ctaColor = isEnabled ? foreground : foreground.withOpacity(0.5);
    //18.- Material + Ink convierten toda la tarjeta en una superficie táctil con ripple.
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isEnabled ? onAction : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                        color: iconColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: bodyColor,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: ctaColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: ctaColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//11.- _RideTrendChart dibuja un gráfico de barras simplificado sin dependencias externas.
class _RideTrendChart extends StatelessWidget {
  const _RideTrendChart({required this.data, required this.color});

  final List<int> data;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3,
      child: CustomPaint(
        painter: _RideTrendPainter(data: data, color: color),
      ),
    );
  }
}

//12.- _RideTrendPainter convierte los datos en barras verticales con fondo degradado.
class _RideTrendPainter extends CustomPainter {
  _RideTrendPainter({required this.data, required this.color});

  final List<int> data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.1), color.withOpacity(0.02)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      backgroundPaint,
    );

    if (data.isEmpty) {
      return;
    }

    final maxValue = data.reduce(math.max).toDouble();
    final barWidth = size.width / (data.length * 2);
    for (var i = 0; i < data.length; i++) {
      final value = data[i];
      final normalizedHeight = value / maxValue;
      final barHeight = normalizedHeight * size.height;
      final dx = barWidth + i * barWidth * 2;
      final barRect = Rect.fromLTWH(dx, size.height - barHeight, barWidth, barHeight);
      canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, const Radius.circular(8)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RideTrendPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color;
  }
}

//13.- _generateRideTrend crea una serie predecible usando las métricas actuales.
List<int> _generateRideTrend(DashboardMetrics metrics) {
  final base = math.max(metrics.completedRidesThisWeek - 4, 2);
  return List<int>.generate(5, (index) => base + index);
}

