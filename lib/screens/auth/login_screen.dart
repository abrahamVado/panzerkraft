import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../services/auth/fake_credentials.dart';

const loginSubmitButtonKey = Key('login_submit_button');

//1.- LoginScreen simplifica el acceso mostrando un único botón de entrada demo.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginControllerProvider);
    final theme = Theme.of(context);
    //2.- build construye una UI directa con mensajes de estado y el CTA demo.
    return Scaffold(
      appBar: AppBar(title: const Text('Ingreso de riders')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Ahora puedes entrar de inmediato con un usuario demo. La aplicación generará credenciales por ti.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                if (state.errorMessage != null) ...[
                  Text(
                    state.errorMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                  ),
                  const SizedBox(height: 12),
                ],
                if (state.riderName != null) ...[
                  Card(
                    color: theme.colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bienvenido, ${state.riderName}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sesión creada como ${state.email}.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                FilledButton.icon(
                  key: loginSubmitButtonKey,
                  onPressed: state.isSubmitting
                      ? null
                      : () async {
                          //3.- El botón dispara la creación de credenciales demo y la autenticación.
                          await ref.read(loginControllerProvider.notifier).signInAsDemo();
                        },
                  icon: state.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(state.isSubmitting ? 'Ingresando...' : 'Entrar como Demo'),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      'Riders de referencia:',
                      style: theme.textTheme.labelLarge,
                    ),
                    ...ref.watch(fakeCredentialStoreProvider).allowedRiders.map(
                      (rider) => Chip(label: Text(rider.email)),
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
