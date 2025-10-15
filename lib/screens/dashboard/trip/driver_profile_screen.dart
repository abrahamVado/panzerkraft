import 'package:flutter/material.dart';

import '../../../services/dashboard/dashboard_current_trip_service.dart';

//1.- DriverProfileScreen resume los datos esenciales del conductor asignado.
class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key, required this.trip});

  final DashboardCurrentTrip trip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil del conductor')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  child: Text(trip.driverName.substring(0, 1)),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.driverName, style: theme.textTheme.titleLarge),
                    Text('Calificación: ${trip.driverRating.toStringAsFixed(1)}'),
                    Text('Experiencia: ${trip.driverExperienceYears} años'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Contacto', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Teléfono: ${trip.driverPhone}'),
            const SizedBox(height: 24),
            Text('Vehículo', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('${trip.vehicleModel} - Placas ${trip.vehiclePlate}'),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _showContact(context),
              icon: const Icon(Icons.sms_outlined),
              label: const Text('Enviar mensaje'),
            ),
          ],
        ),
      ),
    );
  }

  //2.- _showContact presenta un Snackbar simulando el inicio de conversación.
  void _showContact(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Abriendo chat con ${trip.driverName}...')),
    );
  }
}
