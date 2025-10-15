import 'package:flutter/material.dart';

import '../../../services/dashboard/dashboard_current_trip_service.dart';

//1.- PanicButtonScreen alerta sobre el uso responsable del botón de emergencia.
class PanicButtonScreen extends StatelessWidget {
  const PanicButtonScreen({super.key, this.trip});

  final DashboardCurrentTrip? trip;

  @override
  Widget build(BuildContext context) {
    final status = trip?.status ?? 'Sin viaje activo';
    final pickup = trip?.pickupAddress ?? 'Ubicación no disponible';
    final dropoff = trip?.dropoffAddress ?? 'Destino no asignado';
    return Scaffold(
      appBar: AppBar(title: const Text('Botón de pánico')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Utiliza el botón de pánico únicamente en emergencias reales. Un mal uso genera sanciones y retrasa la asistencia para quienes sí la necesitan.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Text('Estado actual del viaje: $status'),
          Text('Punto de partida: $pickup'),
          Text('Destino: $dropoff'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () async {
              //2.- Mostramos una confirmación final antes de iniciar el protocolo de emergencia.
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirmar alerta'),
                  content: const Text(
                    'Al confirmar enviaremos tu ubicación y los datos del viaje a los servicios de emergencia. '
                    'Reporta únicamente situaciones de riesgo real.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Enviar alerta'),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Alerta enviada'),
                    content: const Text(
                      'Contactamos a los servicios de emergencia con la información de tu viaje y tu ubicación actual. '
                      'Por favor no apagues el GPS hasta recibir ayuda.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Entendido'),
                      ),
                    ],
                  ),
                );
              }
            },
            icon: const Icon(Icons.warning_amber),
            label: const Text('Activar protocolo de emergencia'),
          ),
        ],
      ),
    );
  }
}
