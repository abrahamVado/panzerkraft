import 'package:flutter/material.dart';

import '../../../services/dashboard/dashboard_metrics_service.dart';

//1.- FinanceRangeSelector permite alternar el periodo de análisis de finanzas.
class FinanceRangeSelector extends StatelessWidget {
  const FinanceRangeSelector({
    super.key,
    required this.selectedRange,
    required this.onChanged,
  });

  final FinanceRange selectedRange;
  final ValueChanged<FinanceRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Periodo de análisis', style: theme.textTheme.titleSmall),
        DropdownButton<FinanceRange>(
          value: selectedRange,
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
          items: FinanceRange.values
              .map(
                (range) => DropdownMenuItem(
                  value: range,
                  child: Text(_financeRangeLabel(range)),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

//2.- FinanceStatsGrid organiza los indicadores clave de la sección Finanzas.
class FinanceStatsGrid extends StatelessWidget {
  const FinanceStatsGrid({
    super.key,
    required this.snapshot,
    required this.acceptanceRate,
  });

  final FinanceSnapshot snapshot;
  final double acceptanceRate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _FinanceStatTile(
              label: 'Viajes',
              value: snapshot.tripCount.toString(),
              icon: Icons.route,
            ),
            _FinanceStatTile(
              label: 'Monto total',
              value: _formatCurrency(snapshot.totalAmount),
              icon: Icons.payments,
            ),
            _FinanceStatTile(
              label: 'Precio promedio',
              value: _formatCurrency(snapshot.averagePrice),
              icon: Icons.attach_money,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _AcceptanceRateMeter(rate: acceptanceRate),
      ],
    );
  }
}

//3.- _FinanceStatTile muestra una métrica resumida con iconografía contextual.
class _FinanceStatTile extends StatelessWidget {
  const _FinanceStatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.secondaryContainer,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 44,
              height: 44,
              child: ColoredBox(
                color: colorScheme.secondary,
                child: FittedBox(
                  //4.- FittedBox.cover escala el icono hasta tocar el borde evitando cualquier margen perceptible.
                  fit: BoxFit.cover,
                  child: Icon(
                    icon,
                    //5.- Un tamaño mayor al contenedor asegura que el recorte elimine el halo sobrante del glifo.
                    size: 56,
                    color: colorScheme.onSecondary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _financeRangeLabel(FinanceRange range) {
  //4.- _financeRangeLabel asigna un texto legible para el DropdownButton.
  switch (range) {
    case FinanceRange.today:
      return 'Hoy';
    case FinanceRange.week:
      return 'Semana';
    case FinanceRange.month:
      return 'Mes';
  }
}

String _formatCurrency(double amount) {
  //5.- _formatCurrency estandariza el formato monetario en MXN.
  return 'MXN ${amount.toStringAsFixed(2)}';
}

//6.- _AcceptanceRateMeter traduce la tasa de aceptación a una barra radial sencilla.
class _AcceptanceRateMeter extends StatelessWidget {
  const _AcceptanceRateMeter({required this.rate});

  final double rate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalized = (rate.clamp(0, 100)) / 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tasa de aceptación', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            value: normalized,
            minHeight: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text('${rate.toStringAsFixed(1)}% de viajes aceptados',
            style: theme.textTheme.bodySmall),
      ],
    );
  }
}
