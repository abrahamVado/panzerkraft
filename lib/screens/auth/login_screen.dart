import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/branding_config.dart';
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
                const _BrandingPreview(),
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

//1.1.- _BrandingPreview presenta los recursos configurables antes del formulario.
class _BrandingPreview extends StatelessWidget {
  const _BrandingPreview();

  static const double _imageHeight = 84;

  @override
  Widget build(BuildContext context) {
    //1.- build arma la sección de logos solo cuando existen rutas configuradas.
    final entries = <(String, String)>[
      (BrandingConfig.appLogoSource, 'Logotipo de la aplicación'),
      (BrandingConfig.androidIconSource, 'Ícono para Android'),
    ]
        .where((entry) => entry.$1.trim().isNotEmpty)
        .toList(growable: false);
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final entry in entries)
              _BrandingImageTile(
                source: entry.$1,
                label: entry.$2,
                height: _imageHeight,
              ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

//1.2.- _BrandingImageTile decide entre assets locales e imágenes remotas con fallback.
class _BrandingImageTile extends StatelessWidget {
  const _BrandingImageTile({
    required this.source,
    required this.label,
    required this.height,
  });

  final String source;
  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    //1.- build dibuja un recuadro con la imagen y etiqueta descriptiva.
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outlineVariant;
    final textStyle = theme.textTheme.labelMedium;
    final imageWidget = BrandingConfig.isRemoteSource(source)
        ? Image.network(
            source,
            height: height,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => _BrandingImagePlaceholder(label: label),
          )
        : Image.asset(
            source,
            height: height,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => _BrandingImagePlaceholder(label: label),
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Semantics(
            label: label,
            image: true,
            child: SizedBox(
              height: height,
              width: height,
              child: FittedBox(
                fit: BoxFit.contain,
                child: imageWidget,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: textStyle, textAlign: TextAlign.center),
      ],
    );
  }
}

//1.3.- _BrandingImagePlaceholder asegura un estado visual consistente ante errores.
class _BrandingImagePlaceholder extends StatelessWidget {
  const _BrandingImagePlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_outlined, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
