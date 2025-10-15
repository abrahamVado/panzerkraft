import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/auth_providers.dart';
import '../../../services/auth/fake_credentials.dart';

//1.- RiderProfileScreen permite editar datos básicos del rider autenticado.
class RiderProfileScreen extends ConsumerStatefulWidget {
  const RiderProfileScreen({super.key});

  @override
  ConsumerState<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends ConsumerState<RiderProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    //2.- Inicializamos los campos usando el rider actual o valores genéricos.
    final rider = ref.read(signedInRiderProvider);
    _nameController = TextEditingController(text: rider?.name ?? 'Conductor');
    _phoneController = TextEditingController(text: '+52 55 0000 0000');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rider = ref.watch(signedInRiderProvider);
    //3.- Si no hay sesión activa mostramos un estado vacío.
    if (rider == null) {
      return const Scaffold(
        body: Center(child: Text('Inicia sesión para editar tu perfil.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actualiza tus datos de contacto para facilitar la comunicación con los pasajeros.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre completo'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono'),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                //4.- Guardamos el nombre actualizado y mostramos confirmación.
                final trimmedName = _nameController.text.trim();
                if (trimmedName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ingresa un nombre válido.')),
                  );
                  return;
                }
                ref.read(signedInRiderProvider.notifier).state =
                    RiderAccount(email: rider.email, name: trimmedName);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Perfil actualizado correctamente.')),
                );
              },
              icon: const Icon(Icons.save),
              label: const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }
}
