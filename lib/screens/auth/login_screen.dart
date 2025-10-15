import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../services/auth/fake_credentials.dart';

const loginEmailFieldKey = Key('login_email_field');
const loginPasswordFieldKey = Key('login_password_field');
const loginSubmitButtonKey = Key('login_submit_button');

//1.- LoginScreen orquesta el formulario autenticado contra credenciales simuladas.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final FocusNode _passwordFocusNode;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    //1.- initState enlaza controladores y listeners para sincronizar con LoginController.
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _passwordFocusNode = FocusNode();
    _emailController.addListener(_handleEmailChange);
    _passwordController.addListener(_handlePasswordChange);
  }

  //2.- _handleEmailChange replica el texto del campo hacia el estado global.
  void _handleEmailChange() {
    ref.read(loginControllerProvider.notifier).updateEmail(_emailController.text);
  }

  //3.- _handlePasswordChange mantiene la contraseña sincronizada con el controlador.
  void _handlePasswordChange() {
    ref.read(loginControllerProvider.notifier).updatePassword(_passwordController.text);
  }

  //4.- _submit ejecuta la autenticación y cierra el teclado activo.
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await ref.read(loginControllerProvider.notifier).submit();
  }

  @override
  void dispose() {
    //5.- dispose libera recursos evitando fugas de memoria.
    _emailController.removeListener(_handleEmailChange);
    _passwordController.removeListener(_handlePasswordChange);
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final theme = Theme.of(context);
    //6.- build arma la interfaz con validaciones visuales y mensajes de retroalimentación.
    return Scaffold(
      appBar: AppBar(title: const Text('Ingreso de riders')), 
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Acceso demo activo: escribe cualquier correo y contraseña para avanzar.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: loginEmailFieldKey,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () => _passwordFocusNode.requestFocus(),
                    decoration: InputDecoration(
                      labelText: 'Correo',
                      hintText: 'tu.nombre@example.com',
                      errorText: !state.isValidEmail && state.email.isNotEmpty
                          ? 'Introduce un correo válido.'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: loginPasswordFieldKey,
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (!state.isSubmitting) {
                        _submit();
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      errorText: !state.isValidPassword && state.password.isNotEmpty
                          ? 'La contraseña debe tener al menos 6 caracteres.'
                          : null,
                    ),
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
                    Text(
                      'Bienvenido, ${state.riderName}!'.replaceAll('  ', ' '),
                      style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
                    ),
                    const SizedBox(height: 12),
                  ],
                  FilledButton(
                    key: loginSubmitButtonKey,
                    onPressed: state.isSubmitting ? null : _submit,
                    child: state.isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Iniciar sesión'),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        'Riders permitidos:',
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
      ),
    );
  }
}
