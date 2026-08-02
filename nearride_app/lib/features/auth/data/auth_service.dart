import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/token_store.dart';

class AuthService {
  AuthService(this._api, this._tokens);

  final ApiClient _api;
  final TokenStore _tokens;

  Future<void> signInWithGoogle() async {
    if (AppConfig.googleServerClientId.isEmpty) {
      throw const AuthException(
        'Google Sign-In is not configured in this build. Add '
        'GOOGLE_SERVER_CLIENT_ID with --dart-define.',
      );
    }

    final googleSignIn = GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: AppConfig.googleServerClientId,
    );
    final account = await googleSignIn.signIn();
    if (account == null) throw const GoogleSignInCancelled();

    final idToken = (await account.authentication).idToken;
    if (idToken == null) {
      throw const AuthException('Google did not return an ID token.');
    }

    final response = await _api.dio.post(
      '/auth/google',
      data: {'idToken': idToken},
    );
    await _tokens.save(
      response.data['data']['session'] as Map<String, dynamic>,
    );
  }

  static String messageFor(Object exception) {
    if (exception is AuthException) return exception.message;
    if (exception is DioException) {
      final data = exception.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      if (exception.type == DioExceptionType.connectionError ||
          exception.type == DioExceptionType.connectionTimeout) {
        return 'Could not reach the NearRide server.';
      }
    }
    if (exception is PlatformException) {
      return 'Google Sign-In failed (${exception.code}). Check the OAuth '
          'package name and SHA fingerprints.';
    }
    return 'Google Sign-In failed. Please try again.';
  }
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}

class GoogleSignInCancelled implements Exception {
  const GoogleSignInCancelled();
}
