import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/providers/providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final formKey = GlobalKey<FormState>();
  final fullName = TextEditingController();
  final phone = TextEditingController();
  String email = '';
  String? avatarUrl;
  bool loading = true;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    fullName.dispose();
    phone.dispose();
    super.dispose();
  }

  String messageFor(Object exception) {
    if (exception is DioException) {
      final data = exception.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
    }
    return 'Something went wrong. Please try again.';
  }

  void applyUser(Map<String, dynamic> user) {
    fullName.text = user['fullName'] as String? ?? '';
    phone.text = user['phone'] as String? ?? '';
    email = user['email'] as String? ?? '';
    avatarUrl = user['avatarUrl'] as String?;
  }

  Future<void> load() async {
    try {
      final response = await ref.read(apiProvider).dio.get('/auth/me');
      if (mounted) setState(() => applyUser(Map<String, dynamic>.from(response.data['data'])));
    } on DioException catch (exception) {
      if (exception.response?.statusCode == 401) {
        if (mounted) context.go('/login');
        return;
      }
      if (mounted) setState(() => error = messageFor(exception));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() { saving = true; error = null; });
    try {
      final response = await ref.read(apiProvider).dio.patch('/auth/me', data: {
        'fullName': fullName.text.trim(),
        'phone': phone.text.trim().isEmpty ? null : phone.text.trim(),
      });
      if (mounted) {
        setState(() => applyUser(Map<String, dynamic>.from(response.data['data'])));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated.')));
      }
    } catch (exception) {
      if (mounted) setState(() => error = messageFor(exception));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> chooseAvatar() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1200,
    );
    if (image == null) return;
    setState(() { saving = true; error = null; });
    try {
      final file = await MultipartFile.fromFile(image.path, filename: image.name);
      final response = await ref.read(apiProvider).dio.post(
        '/auth/me/avatar',
        data: FormData.fromMap({'avatar': file}),
      );
      if (mounted) setState(() => applyUser(Map<String, dynamic>.from(response.data['data'])));
    } catch (exception) {
      if (mounted) setState(() => error = messageFor(exception));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> logout() async {
    final tokens = ref.read(tokenStoreProvider);
    final refreshToken = await tokens.refresh();
    try {
      await ref.read(apiProvider).dio.post('/auth/logout', data: {'refreshToken': refreshToken});
    } catch (_) {
      // Local logout must still work when the server is unavailable.
    }
    await tokens.clear();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('My profile')),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 54,
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            backgroundImage: avatarUrl == null ? null : CachedNetworkImageProvider(avatarUrl!),
                            child: avatarUrl == null ? const Icon(Icons.person, size: 54) : null,
                          ),
                          Positioned(
                            right: -4,
                            bottom: -4,
                            child: IconButton.filled(
                              onPressed: saving ? null : chooseAvatar,
                              tooltip: 'Change profile photo',
                              icon: const Icon(Icons.camera_alt_outlined),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: fullName,
                      decoration: const InputDecoration(labelText: 'Full name'),
                      validator: (value) => value == null || value.trim().length < 2 ? 'Enter your full name.' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: email,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone (optional)'),
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: saving ? null : save,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(saving ? 'Saving...' : 'Save profile'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: saving ? null : () => context.push('/provider'),
                      icon: const Icon(Icons.directions_car_outlined),
                      label: const Text('Manage provider listings'),
                    ),
                    const SizedBox(height: 20),
                    TextButton.icon(
                      onPressed: saving ? null : logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign out'),
                    ),
                  ],
                ),
              ),
      );
}
