import 'package:flutter/foundation.dart';

import 'auth_service.dart';
import 'user_session.dart';

class AuthController extends ChangeNotifier {
  AuthController({required AuthService service}) : _service = service;

  final AuthService _service;
  UserSession? _session;
  bool _isLoading = false;

  bool get isAuthenticated => _session != null;
  String get displayName => _session?.displayName ?? '';
  bool get isLoading => _isLoading;

  Future<void> signInWithEmail(String email) async {
    //1.- Mark loading state so UI can disable the submit button.
    _isLoading = true;
    notifyListeners();
    try {
      //2.- Delegate to the service and keep the resulting session in memory.
      _session = await _service.signInWithEmail(email);
    } finally {
      //3.- Reset loading state regardless of success or failure.
      _isLoading = false;
      notifyListeners();
    }
  }

  void signOut() {
    //1.- Clear the session reference to log out the user.
    _session = null;
    //2.- Let listeners know so navigation can return to the login screen.
    notifyListeners();
  }
}
