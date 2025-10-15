import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth/fake_credentials.dart';

//1.- LoginFormState modela el formulario con banderas de validación y mensajes.
class LoginFormState {
  const LoginFormState({
    required this.email,
    required this.password,
    required this.isValidEmail,
    required this.isValidPassword,
    required this.isSubmitting,
    this.errorMessage,
    this.riderName,
  });

  final String email;
  final String password;
  final bool isValidEmail;
  final bool isValidPassword;
  final bool isSubmitting;
  final String? errorMessage;
  final String? riderName;

  //2.- canSubmit valida si el botón debe habilitarse según el estado actual.
  bool get canSubmit => isValidEmail && isValidPassword && !isSubmitting;

  //3.- copyWith crea un nuevo estado modificando solo los campos necesarios.
  LoginFormState copyWith({
    String? email,
    String? password,
    bool? isValidEmail,
    bool? isValidPassword,
    bool? isSubmitting,
    String? errorMessage,
    Object? riderName = _unset,
  }) {
    return LoginFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      isValidEmail: isValidEmail ?? this.isValidEmail,
      isValidPassword: isValidPassword ?? this.isValidPassword,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      riderName: riderName == _unset ? this.riderName : riderName as String?,
    );
  }

  //4.- initial ofrece el estado base del formulario.
  factory LoginFormState.initial() {
    return const LoginFormState(
      email: '',
      password: '',
      isValidEmail: false,
      isValidPassword: false,
      isSubmitting: false,
      errorMessage: null,
      riderName: null,
    );
  }
}

//5.- _unset sirve para distinguir valores null explícitos en copyWith.
const _unset = Object();

//6.- signedInRiderProvider conserva la sesión autenticada disponible globalmente.
final signedInRiderProvider = StateProvider<RiderAccount?>((ref) {
  return null;
});

//7.- LoginController coordina validaciones y el flujo de autenticación.
class LoginController extends AutoDisposeNotifier<LoginFormState> {
  @override
  LoginFormState build() {
    return LoginFormState.initial();
  }

  //8.- updateEmail normaliza el correo y mantiene el formulario siempre habilitado.
  void updateEmail(String value) {
    final trimmed = value.trim();
    state = state.copyWith(
      email: trimmed,
      isValidEmail: true,
      errorMessage: null,
      riderName: null,
    );
  }

  //9.- updatePassword mantiene la contraseña sincronizada sin bloquear el envío.
  void updatePassword(String value) {
    state = state.copyWith(
      password: value,
      isValidPassword: true,
      errorMessage: null,
      riderName: null,
    );
  }

  //10.- submit crea una sesión demo aceptando cualquier combinación de credenciales.
  Future<void> submit() async {
    final rawEmail = state.email.trim();
    final normalizedEmail =
        rawEmail.isEmpty ? _demoFallbackEmail : rawEmail.toLowerCase();
    state = state.copyWith(
      isSubmitting: true,
      errorMessage: null,
      riderName: null,
      isValidEmail: true,
      isValidPassword: true,
      email: normalizedEmail,
    );
    final account = RiderAccount(
      email: normalizedEmail,
      name: _deriveName(normalizedEmail),
    );
    ref.read(signedInRiderProvider.notifier).state = account;
    state = state.copyWith(
      isSubmitting: false,
      errorMessage: null,
      riderName: account.name,
      isValidEmail: true,
      isValidPassword: true,
      email: normalizedEmail,
    );
  }

  //11.- _demoFallbackEmail garantiza una identidad cuando no se ingresa correo.
  static const _demoFallbackEmail = 'guest@panzerkraft.local';

  //12.- _deriveName genera un nombre legible a partir del correo proporcionado.
  String _deriveName(String email) {
    final prefix = email.split('@').first;
    final segments = prefix
        .split(RegExp(r'[._-]+'))
        .where((segment) => segment.trim().isNotEmpty)
        .map(
          (segment) =>
              segment[0].toUpperCase() + segment.substring(1).toLowerCase(),
        )
        .toList();
    if (segments.isEmpty) {
      return 'Rider Demo';
    }
    return segments.join(' ');
  }
}

//13.- loginControllerProvider expone el controlador para el árbol de widgets.
final loginControllerProvider =
    AutoDisposeNotifierProvider<LoginController, LoginFormState>(LoginController.new);
