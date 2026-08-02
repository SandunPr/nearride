import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/providers/providers.dart';
import '../data/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  String? error;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  String messageFor(Object exception) {
    if (exception is DioException) {
      final data = exception.response?.data;
      if (data is Map && data['message'] is String) return data['message'] as String;
      if (exception.type == DioExceptionType.connectionError || exception.type == DioExceptionType.connectionTimeout) {
        return 'Could not reach the NearRide server.';
      }
    }
    return 'Sign in failed. Please try again.';
  }

  Future<void> finish(Future<Response<dynamic>> request) async {
    final response = await request;
    await ref.read(tokenStoreProvider).save(response.data['data']['session'] as Map<String, dynamic>);
    if (mounted) context.go('/');
  }

  Future<void> submit() async {
    setState(() { loading = true; error = null; });
    try {
      await finish(ref.read(apiProvider).dio.post('/auth/login', data: {'email': email.text.trim(), 'password': password.text}));
    } catch (exception) {
      if (mounted) setState(() => error = messageFor(exception));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> google() async {
    setState(() { loading = true; error = null; });
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      if (mounted) context.go('/');
    } on GoogleSignInCancelled {
      // Closing the Google account picker is not an error.
    } catch (exception) {
      if (mounted) setState(() => error = AuthService.messageFor(exception));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(24), children: [
            Text('Welcome back', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Sign in to save listings and manage your provider profile.'),
            const SizedBox(height: 28),
            TextField(controller: email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(controller: password, obscureText: true, onSubmitted: (_) { if (!loading) submit(); }, decoration: const InputDecoration(labelText: 'Password')),
            if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
            const SizedBox(height: 20),
            FilledButton(onPressed: loading ? null : submit, child: Padding(padding: const EdgeInsets.all(14), child: Text(loading ? 'Signing in…' : 'Sign in'))),
            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('or')), Expanded(child: Divider())])),
            OutlinedButton.icon(onPressed: loading ? null : google, icon: const Icon(Icons.account_circle_outlined), label: const Padding(padding: EdgeInsets.all(14), child: Text('Continue with Google'))),
            const SizedBox(height: 8),
            TextButton(
              onPressed: loading ? null : () => context.push('/register'),
              child: const Text('Create a new account'),
            ),
          ]),
        ),
      );
}
