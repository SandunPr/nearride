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
  final whatsapp = TextEditingController();
  final providerDisplayName = TextEditingController();
  final providerDescription = TextEditingController();
  String providerType = 'both';
  bool providerProfileComplete = false;
  bool whatsappSameAsPhone = false;
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
    whatsapp.dispose();
    providerDisplayName.dispose();
    providerDescription.dispose();
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
    whatsapp.text = user['whatsappNumber'] as String? ?? '';
    whatsappSameAsPhone = phone.text.isNotEmpty && phone.text == whatsapp.text;
    email = user['email'] as String? ?? '';
    avatarUrl = user['avatarUrl'] as String?;
  }

  void applyProvider(Map<String, dynamic>? provider) {
    if (provider == null) {
      providerDisplayName.text = fullName.text;
      providerDescription.clear();
      providerType = 'both';
      providerProfileComplete = false;
      return;
    }
    providerDisplayName.text =
        provider['displayName'] as String? ?? fullName.text;
    providerDescription.text = provider['description'] as String? ?? '';
    providerType = provider['providerType'] as String? ?? 'both';
    providerProfileComplete = provider['completedProfile'] == true ||
        provider['completedProfile'] == 1;
  }

  String normalizedMobile(String value) =>
      value.replaceAll(RegExp(r'[^0-9]'), '');

  String? validateMobile(String? value, String label) {
    final number = normalizedMobile(value ?? '');
    if (number.isEmpty) return '$label is required for provider listings.';
    if (!RegExp(r'^07\d{8}$').hasMatch(number)) {
      return 'Enter a valid local mobile number (07XXXXXXXX).';
    }
    return null;
  }

  Future<void> load() async {
    try {
      final response = await ref.read(apiProvider).dio.get('/auth/me');
      final providerResponse =
          await ref.read(apiProvider).dio.get('/provider/profile');
      if (mounted) {
        setState(() {
          applyUser(Map<String, dynamic>.from(response.data['data']));
          final data = providerResponse.data['data'];
          applyProvider(
            data is Map ? Map<String, dynamic>.from(data) : null,
          );
        });
      }
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
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final dio = ref.read(apiProvider).dio;
      final response = await dio.patch('/auth/me', data: {
        'fullName': fullName.text.trim(),
        'phone': normalizedMobile(phone.text),
        'whatsappNumber': whatsappSameAsPhone
            ? normalizedMobile(phone.text)
            : normalizedMobile(whatsapp.text),
      });
      final providerResponse = await dio.post('/provider/profile', data: {
        'displayName': providerDisplayName.text.trim(),
        'providerType': providerType,
        'description': providerDescription.text.trim().isEmpty
            ? null
            : providerDescription.text.trim(),
      });
      if (mounted) {
        setState(() {
          applyUser(Map<String, dynamic>.from(response.data['data']));
          applyProvider(
            Map<String, dynamic>.from(providerResponse.data['data']),
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Provider profile completed successfully.')));
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
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final file =
          await MultipartFile.fromFile(image.path, filename: image.name);
      final response = await ref.read(apiProvider).dio.post(
            '/auth/me/avatar',
            data: FormData.fromMap({'avatar': file}),
          );
      if (mounted) {
        setState(
            () => applyUser(Map<String, dynamic>.from(response.data['data'])));
      }
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
      await ref
          .read(apiProvider)
          .dio
          .post('/auth/logout', data: {'refreshToken': refreshToken});
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
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            backgroundImage: avatarUrl == null
                                ? null
                                : CachedNetworkImageProvider(avatarUrl!),
                            child: avatarUrl == null
                                ? const Icon(Icons.person, size: 54)
                                : null,
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
                      validator: (value) =>
                          value == null || value.trim().length < 2
                              ? 'Enter your full name.'
                              : null,
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
                      autofillHints: const [AutofillHints.telephoneNumber],
                      decoration: const InputDecoration(
                        labelText: 'Local mobile number *',
                        hintText: '07XXXXXXXX',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (value) =>
                          validateMobile(value, 'Mobile number'),
                      onChanged: (value) {
                        if (whatsappSameAsPhone) whatsapp.text = value;
                      },
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: whatsappSameAsPhone,
                      title: const Text('WhatsApp is the same as mobile'),
                      onChanged: saving
                          ? null
                          : (value) => setState(() {
                                whatsappSameAsPhone = value ?? false;
                                if (whatsappSameAsPhone) {
                                  whatsapp.text = phone.text;
                                }
                              }),
                    ),
                    TextFormField(
                      controller: whatsapp,
                      enabled: !whatsappSameAsPhone,
                      keyboardType: TextInputType.phone,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      decoration: const InputDecoration(
                        labelText: 'WhatsApp number *',
                        hintText: '07XXXXXXXX',
                        prefixIcon: Icon(Icons.chat_outlined),
                      ),
                      validator: (value) => validateMobile(
                        whatsappSameAsPhone ? phone.text : value,
                        'WhatsApp number',
                      ),
                    ),
                    const Divider(height: 40),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Provider profile',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        Chip(
                          avatar: Icon(
                            providerProfileComplete
                                ? Icons.check_circle
                                : Icons.info_outline,
                            size: 18,
                          ),
                          label: Text(
                            providerProfileComplete
                                ? 'Complete'
                                : 'Required for listings',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: providerDisplayName,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Provider display name *',
                        hintText: 'Name shown on your listings',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (value) =>
                          value == null || value.trim().length < 2
                              ? 'Enter your provider display name.'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: providerType,
                      decoration: const InputDecoration(
                        labelText: 'Provider type *',
                        prefixIcon: Icon(Icons.business_center_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'vehicle_owner',
                          child: Text('Vehicle owner'),
                        ),
                        DropdownMenuItem(
                          value: 'driver',
                          child: Text('Driver'),
                        ),
                        DropdownMenuItem(
                          value: 'both',
                          child: Text('Vehicle owner and driver'),
                        ),
                      ],
                      onChanged: saving
                          ? null
                          : (value) => setState(() {
                                if (value != null) providerType = value;
                              }),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: providerDescription,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Provider description (optional)',
                        hintText: 'Describe your driving or vehicle service',
                      ),
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(error!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
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
                      onPressed:
                          saving ? null : () => context.push('/provider'),
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
