import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/branding_config.dart';
import '../../../providers/dashboard/travel_history_controller.dart';
import '../../../services/dashboard/dashboard_travel_history_service.dart';

//1.1.- travelHistoryThumbnailAsset referencia el recurso configurable por defecto.
const travelHistoryThumbnailAsset =
    BrandingConfig.travelHistoryFallbackSource;

//1.2.- travelHistoryVehicleThumbnails reutiliza la galería definida en BrandingConfig.
final List<String> travelHistoryVehicleThumbnails =
    BrandingConfig.travelHistoryVehicleGallery();

//1.3.- travelHistoryThumbnailKey permite ubicar la miniatura en pruebas de widgets.
const travelHistoryThumbnailKey = Key('travel_history_thumbnail');

//1.4.- TravelHistoryThumbnailResolver asigna una imagen determinística por viaje.
class TravelHistoryThumbnailResolver {
  const TravelHistoryThumbnailResolver({
    this.vehicleAssets = travelHistoryVehicleThumbnails,
    this.fallbackAsset = travelHistoryThumbnailAsset,
  });

  final List<String> vehicleAssets;
  final String fallbackAsset;

  String assetForEntry(TravelHistoryEntry entry) {
    final sanitizedAssets = vehicleAssets
        .map((asset) => asset.trim())
        .where((asset) => asset.isNotEmpty)
        .toList(growable: false);
    if (sanitizedAssets.isEmpty) {
      return fallbackAsset;
    }
    final hash = Object.hash(
      entry.date.millisecondsSinceEpoch,
      entry.origin,
      entry.destination,
      entry.durationMinutes,
      entry.distanceKm,
      entry.fare,
    );
    final index = hash.abs() % sanitizedAssets.length;
    final selected = sanitizedAssets[index];
    return selected.isEmpty ? fallbackAsset : selected;
  }
}

//1.- TravelHistoryScreen muestra la lista paginada de viajes completados.
class TravelHistoryScreen extends ConsumerWidget {
  const TravelHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageState = ref.watch(travelHistoryControllerProvider);
    final controller = ref.read(travelHistoryControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de viajes')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: pageState.when(
          data: (page) {
            if (page.entries.isEmpty) {
              return const Center(
                child: Text('Aún no registramos viajes finalizados en tu cuenta.'),
              );
            }
            return Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: controller.refresh,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: page.entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final entry = page.entries[index];
                        return _TravelHistoryTile(entry: entry);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: page.hasPreviousPage ? controller.previousPage : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Anterior'),
                    ),
                    Text('Página ${page.displayPage} de ${page.totalPages}'),
                    OutlinedButton.icon(
                      onPressed: page.hasNextPage ? controller.nextPage : null,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Siguiente'),
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _TravelHistoryError(
            message: error is StateError
                ? error.message
                : 'No pudimos cargar tu historial. Intenta nuevamente.',
            onRetry: controller.refresh,
          ),
        ),
      ),
    );
  }
}

//2.- _TravelHistoryTile presenta los detalles principales de un viaje.
class _TravelHistoryTile extends StatelessWidget {
  const _TravelHistoryTile({required this.entry});

  final TravelHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.origin} → ${entry.destination}',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('Fecha: ${_formatDate(entry.date)}'),
                  Text('Duración: ${entry.durationMinutes} min'),
                  Text('Distancia: ${entry.distanceKm.toStringAsFixed(1)} km'),
                  Text('Tarifa: ${entry.fare.toStringAsFixed(2)} MXN'),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _TravelHistoryThumbnail(entry: entry),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

//2.1.- _TravelHistoryThumbnail reserva espacio para la imagen ilustrativa del viaje.
class _TravelHistoryThumbnail extends StatelessWidget {
  const _TravelHistoryThumbnail({
    required this.entry,
    this.resolver = const TravelHistoryThumbnailResolver(),
  });

  static const double _thumbnailWidth = 120;
  final TravelHistoryEntry entry;
  final TravelHistoryThumbnailResolver resolver;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final assetPath = resolver.assetForEntry(entry);
    return SizedBox(
      width: _thumbnailWidth,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: BrandingConfig.isRemoteSource(assetPath)
              ? Image.network(
                  assetPath,
                  key: travelHistoryThumbnailKey,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _ThumbnailFallback(colorScheme: colorScheme);
                  },
                )
              : Image.asset(
                  assetPath,
                  key: travelHistoryThumbnailKey,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _ThumbnailFallback(colorScheme: colorScheme);
                  },
                ),
        ),
      ),
    );
  }
}

//2.2.- _ThumbnailFallback centraliza el contenedor mostrado si la imagen falla.
class _ThumbnailFallback extends StatelessWidget {
  const _ThumbnailFallback({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
      ),
      child: Center(
        child: Icon(
          Icons.photo,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

//3.- _TravelHistoryError comunica fallos con un botón de reintento.
class _TravelHistoryError extends StatelessWidget {
  const _TravelHistoryError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
