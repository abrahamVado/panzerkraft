import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//1.- RiderAccount describe la identidad autenticada que se comparte con la UI.
class RiderAccount {
  const RiderAccount({required this.email, required this.name});

  final String email;
  final String name;
}

//2.- FakeCredential encapsula un correo y el hash de su contraseña.
class FakeCredential {
  const FakeCredential({required this.email, required this.passwordHash});

  final String email;
  final String passwordHash;

  //3.- matches verifica si las credenciales coinciden tras normalizar y hashear la contraseña.
  bool matches(String candidateEmail, String candidatePassword) {
    final normalizedEmail = _normalizeEmail(candidateEmail);
    final normalizedPassword = _hash(candidatePassword);
    return email == normalizedEmail && passwordHash == normalizedPassword;
  }

  //4.- riderName construye un nombre legible usando el prefijo del correo.
  String get riderName {
    final prefix = email.split('@').first;
    final segments = prefix.split(RegExp(r'[._-]+')).where((segment) => segment.isNotEmpty);
    if (segments.isEmpty) {
      return 'Rider';
    }
    final capitalized = segments
        .map((segment) => segment.isEmpty
            ? ''
            : segment[0].toUpperCase() + segment.substring(1).toLowerCase())
        .where((segment) => segment.isNotEmpty)
        .toList();
    return capitalized.join(' ');
  }

  //5.- availableAccount materializa la cuenta asociada para las capas superiores.
  RiderAccount get availableAccount => RiderAccount(email: email, name: riderName);

  //6.- _normalizeEmail centraliza el saneamiento de correos para evitar duplicación.
  static String _normalizeEmail(String value) => value.trim().toLowerCase();

  //7.- _hash aplica SHA-256 y codifica como hexadecimal para comparaciones seguras.
  static String _hash(String value) {
    final bytes = utf8.encode(value);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

//8.- FakeCredentialStore resguarda el listado permitido y coordina autenticaciones.
class FakeCredentialStore {
  const FakeCredentialStore(this._credentials);

  final List<FakeCredential> _credentials;

  //9.- authenticate retorna la cuenta cuando encuentra coincidencia exacta, de lo contrario null.
  RiderAccount? authenticate(String email, String password) {
    final normalizedEmail = email.trim().toLowerCase();
    for (final credential in _credentials) {
      if (credential.matches(normalizedEmail, password)) {
        return credential.availableAccount;
      }
    }
    return null;
  }

  //10.- allowedRiders expone la lista de cuentas que podrían autenticarse.
  List<RiderAccount> get allowedRiders =>
      _credentials.map((credential) => credential.availableAccount).toList(growable: false);
}

//11.- fakeCredentialStoreProvider comparte el almacén de credenciales con Riverpod.
final fakeCredentialStoreProvider = Provider<FakeCredentialStore>((ref) {
  const credentials = [
    FakeCredential(
      email: 'itzel.rider@example.com',
      passwordHash: '3e13adf022bf21a6a5af0711fd308250d608591bfee81d3252c450461a76f327',
    ),
    FakeCredential(
      email: 'yahualica.rider@example.com',
      passwordHash: '5831be2394a3329adcab17a3e30ac57e87eb2bf50fcaf60c0af1dd335d5acb55',
    ),
    FakeCredential(
      email: 'xolo.rider@example.com',
      passwordHash: 'b08f1d06c97727125b200a43be6451f5aaea28f597f746fbd617f1300097aaeb',
    ),
  ];
  return FakeCredentialStore(credentials);
});
