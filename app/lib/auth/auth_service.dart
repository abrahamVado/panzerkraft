import 'dart:async';

import 'user_session.dart';

class AuthService {
  const AuthService();

  Future<UserSession> signInWithEmail(String email) async {
    //1.- Simulate a network delay so the UI can show progress feedback.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    //2.- Build the user session extracting a friendly display name from the email.
    return UserSession(
      email: email.trim(),
      displayName: _buildDisplayName(email),
    );
  }

  String _buildDisplayName(String email) {
    //1.- Extract the user part and capture only letter sequences as potential names.
    final userPart = email.split('@').first;
    final matches = RegExp(r'[a-zA-Z]+').allMatches(userPart);
    final words = matches.map((match) => match.group(0)!).toList();
    //2.- Capitalize each segment so it feels like a name.
    final capitalized = words
        .map((segment) =>
            segment[0].toUpperCase() + segment.substring(1).toLowerCase())
        .toList();
    //3.- Return a fallback when the email does not contain characters.
    if (capitalized.isEmpty) {
      return 'Guest Rider';
    }
    return capitalized.join(' ');
  }
}
