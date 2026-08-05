import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/providers/providers.dart';
import '../data/auth_service.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, this.redirectTo});

  final String? redirectTo;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final formKey = GlobalKey<FormState>();
  final fullName = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  bool loading = false;
  bool obscurePassword = true;
  String? error;

  @override
  void dispose() {
    fullName.dispose();
    email.dispose();
    phone.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  String? requiredText(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    return null;
  }

  String messageFor(Object exception) {
    if (exception is DioException) {
      final data = exception.response?.data;
      if (data is Map) {
        final errors = data['errors'];
        if (errors is List && errors.isNotEmpty) {
          return errors
              .whereType<Map>()
              .map((item) => item['message'])
              .whereType<String>()
              .join('\n');
        }
        if (data['message'] is String) return data['message'] as String;
      }
      if (exception.type == DioExceptionType.connectionError ||
          exception.type == DioExceptionType.connectionTimeout) {
        return 'Could not reach the NearRide server.';
      }
    }
    return 'Could not create your account. Please try again.';
  }

  String get destination {
    final redirect = widget.redirectTo;
    return redirect != null &&
            redirect.startsWith('/') &&
            !redirect.startsWith('//')
        ? redirect
        : '/';
  }

  void showStatus(String message, {required bool success}) {
    final colors = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? colors.primary : colors.error,
        ),
      );
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final response = await ref.read(apiProvider).dio.post(
        '/auth/register',
        data: {
          'fullName': fullName.text.trim(),
          'email': email.text.trim(),
          'phone': phone.text.trim().isEmpty ? null : phone.text.trim(),
          'password': password.text,
        },
      );
      await ref.read(tokenStoreProvider).save(
            response.data['data']['session'] as Map<String, dynamic>,
          );
      if (mounted) {
        showStatus('Account created successfully.', success: true);
        context.go(destination);
      }
    } catch (exception) {
      if (mounted) {
        final message = messageFor(exception);
        setState(() => error = message);
        showStatus(message, success: false);
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> google() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      if (mounted) {
        showStatus('Registered with Google successfully.', success: true);
        context.go(destination);
      }
    } on GoogleSignInCancelled {
      if (mounted) {
        showStatus('Google registration was cancelled.', success: false);
      }
    } catch (exception) {
      if (mounted) {
        final message = AuthService.messageFor(exception);
        setState(() => error = message);
        showStatus(message, success: false);
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Create account'),
          actions: [
            IconButton(
              tooltip: 'Home',
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.home_outlined),
            ),
          ],
        ),
        body: SafeArea(
          child: Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Join NearRide',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                    'Save vehicles and create your own provider listings.'),
                const SizedBox(height: 24),
                TextFormField(
                  controller: fullName,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: (value) => requiredText(value, 'Full name'),
                  decoration: const InputDecoration(labelText: 'Full name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: (value) {
                    final required = requiredText(value, 'Email');
                    if (required != null) return required;
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(value!.trim())) {
                      return 'Enter a valid email address.';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  decoration:
                      const InputDecoration(labelText: 'Phone (optional)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: password,
                  obscureText: obscurePassword,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (value) {
                    if (value == null || value.length < 8) {
                      return 'Password must contain at least 8 characters.';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => obscurePassword = !obscurePassword),
                      icon: Icon(obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmPassword,
                  obscureText: obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!loading) submit();
                  },
                  validator: (value) =>
                      value != password.text ? 'Passwords do not match.' : null,
                  decoration:
                      const InputDecoration(labelText: 'Confirm password'),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      error!,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: loading ? null : submit,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                        loading ? 'Creating account...' : 'Create account'),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Row(children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or'),
                    ),
                    Expanded(child: Divider()),
                  ]),
                ),
                OutlinedButton.icon(
                  onPressed: loading ? null : google,
                  icon: const Icon(Icons.account_circle_outlined),
                  label: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('Register with Google'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: loading ? null : () => context.pop(),
                  child: const Text('Already have an account? Sign in'),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('By creating an account, you accept our '),
                    TextButton(
                      onPressed: () => context.push('/terms'),
                      child: const Text('Terms'),
                    ),
                    const Text('and'),
                    TextButton(
                      onPressed: () => context.push('/privacy'),
                      child: const Text('Privacy Policy'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}
