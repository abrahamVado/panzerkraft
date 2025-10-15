import 'package:flutter/material.dart';

//1.- ReservationScreen guía al conductor para agendar viajes futuros.
class ReservationScreen extends StatefulWidget {
  const ReservationScreen({super.key});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passengerController = TextEditingController();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  DateTime? _reservationDate;

  @override
  void dispose() {
    _passengerController.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear reserva')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Completa los datos para garantizar un traslado puntual a tus pasajeros recurrentes.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _passengerController,
              decoration: const InputDecoration(labelText: 'Pasajero'),
              validator: (value) => value == null || value.isEmpty ? 'Ingresa un pasajero' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pickupController,
              decoration: const InputDecoration(labelText: 'Punto de partida'),
              validator: (value) => value == null || value.isEmpty ? 'Ingresa un punto de partida' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dropoffController,
              decoration: const InputDecoration(labelText: 'Destino'),
              validator: (value) => value == null || value.isEmpty ? 'Ingresa un destino' : null,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fecha y hora'),
              subtitle: Text(
                _reservationDate == null
                    ? 'Selecciona una fecha'
                    : _formatDateTime(_reservationDate!),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: () async {
                  //2.- Seleccionamos la fecha y hora de la reserva en dos pasos accesibles.
                  final now = DateTime.now();
                  final pickedDate = await showDatePicker(
                    context: context,
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 365)),
                    initialDate: _reservationDate ?? now,
                  );
                  if (pickedDate == null) {
                    return;
                  }
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_reservationDate ?? now),
                  );
                  if (!mounted || pickedTime == null) {
                    return;
                  }
                  setState(() {
                    _reservationDate = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      pickedTime.hour,
                      pickedTime.minute,
                    );
                  });
                },
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                //3.- Validamos el formulario y confirmamos la creación de la reserva.
                if (!_formKey.currentState!.validate() || _reservationDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Completa todos los campos para agendar.')),
                  );
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Reserva registrada para ${_passengerController.text} el ${_formatDateTime(_reservationDate!)}. '
                      'Recibirás un recordatorio 1 hora antes.',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.event_available),
              label: const Text('Confirmar reserva'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}
