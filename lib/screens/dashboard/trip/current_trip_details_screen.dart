import 'package:flutter/material.dart';

import '../../../services/dashboard/dashboard_current_trip_service.dart';

//1.- CurrentTripDetailsScreen profundiza en la información del viaje activo.
class CurrentTripDetailsScreen extends StatelessWidget {
  const CurrentTripDetailsScreen({super.key, required this.trip});

  final DashboardCurrentTrip trip;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalles del viaje en curso')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pasajero: ${trip.passengerName}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _DetailTile(label: 'Estado', value: trip.status),
            _DetailTile(label: 'Recoger en', value: trip.pickupAddress),
            _DetailTile(label: 'Destino', value: trip.dropoffAddress),
            _DetailTile(label: 'Monto estimado', value: '${trip.amount.toStringAsFixed(2)} MXN'),
            _DetailTile(label: 'Duración estimada', value: '${trip.durationMinutes} minutos'),
            _DetailTile(label: 'Distancia estimada', value: '${trip.distanceKm.toStringAsFixed(1)} km'),
            _DetailTile(label: 'Vehículo asignado', value: '${trip.vehicleModel} (${trip.vehiclePlate})'),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _confirmCancel(context),
              icon: const Icon(Icons.cancel_schedule_send),
              label: const Text('Cancelar viaje'),
            ),
          ],
        ),
      ),
    );
  }

  //2.- _confirmCancel solicita confirmación antes de notificar la cancelación.
  Future<void> _confirmCancel(BuildContext context) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar viaje'),
        content: const Text('¿Deseas cancelar el viaje en curso?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (shouldCancel == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu viaje fue cancelado. Avisamos al pasajero.')),
      );
    }
  }
}

//3.- _DetailTile estandariza la visualización de pares etiqueta-valor.
class _DetailTile extends StatelessWidget {
  const _DetailTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
