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

  //8.- updateEmail normaliza y valida el correo mientras limpia mensajes previos.
  void updateEmail(String value) {
    final trimmed = value.trim();
    state = state.copyWith(
      email: trimmed,
      isValidEmail: _isValidEmail(trimmed),
      errorMessage: null,
      riderName: null,
    );
  }

  //9.- updatePassword verifica la longitud mínima y reinicia mensajes transitorios.
  void updatePassword(String value) {
    state = state.copyWith(
      password: value,
      isValidPassword: _isValidPassword(value),
      errorMessage: null,
      riderName: null,
    );
  }

  //10.- submit intenta autenticar en el almacén y publica el resultado.
  Future<void> submit() async {
    final email = state.email.trim().toLowerCase();
    final password = state.password;
    final emailOk = _isValidEmail(email);
    final passwordOk = _isValidPassword(password);
    if (!emailOk || !passwordOk) {
      state = state.copyWith(
        isValidEmail: emailOk,
        isValidPassword: passwordOk,
        isSubmitting: false,
        errorMessage: 'Revisa los datos ingresados.',
        riderName: null,
      );
      return;
    }
    state = state.copyWith(isSubmitting: true, errorMessage: null, riderName: null);
    final store = ref.read(fakeCredentialStoreProvider);
    final account = store.authenticate(email, password);
    if (account != null) {
      ref.read(signedInRiderProvider.notifier).state = account;
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: null,
        riderName: account.name,
      );
    } else {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'No pudimos verificar tus credenciales.',
        riderName: null,
      );
    }
  }

  //11.- _isValidEmail usa una expresión simple para verificar formato.
  bool _isValidEmail(String value) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(value);
  }

  //12.- _isValidPassword exige al menos 6 caracteres para evitar intentos triviales.
  bool _isValidPassword(String value) => value.trim().length >= 6;
}

//13.- loginControllerProvider expone el controlador para el árbol de widgets.
final loginControllerProvider =
    AutoDisposeNotifierProvider<LoginController, LoginFormState>(LoginController.new);
