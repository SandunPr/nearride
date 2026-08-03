import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/location_service.dart';
import '../../../shared/providers/providers.dart';

class ProviderScreen extends ConsumerStatefulWidget {
  const ProviderScreen({super.key});

  @override
  ConsumerState<ProviderScreen> createState() => _ProviderScreenState();
}

class _ProviderScreenState extends ConsumerState<ProviderScreen> {
  int step = 0;
  final formKey = GlobalKey<FormState>();

  // Form Fields
  String type = 'vehicle_with_driver';
  int? categoryId = 3; // Default Car category
  final title = TextEditingController();
  final description = TextEditingController();
  final manufacturer = TextEditingController();
  final model = TextEditingController();
  final vehicleNumber = TextEditingController();
  final driverLicenseNumber = TextEditingController();
  final year = TextEditingController();
  final passengerCapacity = TextEditingController();
  final loadCapacity = TextEditingController();
  final startingPrice = TextEditingController();
  String priceUnit = 'negotiable';
  bool hasAirConditioning = true;
  bool longDistanceAvailable = true;
  final area = TextEditingController();
  String? profilePhone;
  String? profileWhatsapp;
  bool providerProfileComplete = false;
  bool loadingProfileContacts = true;

  double? lat;
  double? lng;
  bool fetchingLocation = false;
  String? locationStatus;

  List<XFile> selectedImages = [];
  XFile? driverPhoto;
  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    loadProfileContacts();
    detectLocation();
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    manufacturer.dispose();
    model.dispose();
    vehicleNumber.dispose();
    driverLicenseNumber.dispose();
    year.dispose();
    passengerCapacity.dispose();
    loadCapacity.dispose();
    startingPrice.dispose();
    area.dispose();
    super.dispose();
  }

  bool get profileContactsValid =>
      RegExp(r'^07\d{8}$').hasMatch(profilePhone ?? '') &&
      RegExp(r'^07\d{8}$').hasMatch(profileWhatsapp ?? '');

  Future<void> loadProfileContacts() async {
    try {
      final response = await ref.read(apiProvider).dio.get('/auth/me');
      final providerResponse =
          await ref.read(apiProvider).dio.get('/provider/profile');
      final user = Map<String, dynamic>.from(response.data['data'] as Map);
      final provider = providerResponse.data['data'];
      if (mounted) {
        setState(() {
          profilePhone = user['phone'] as String?;
          profileWhatsapp = user['whatsappNumber'] as String?;
          providerProfileComplete = provider is Map &&
              (provider['completedProfile'] == true ||
                  provider['completedProfile'] == 1);
        });
      }
    } catch (exception) {
      if (exception is DioException && exception.response?.statusCode == 401) {
        if (mounted) context.go('/login?redirect=%2Fprovider');
        return;
      }
      if (mounted) setState(() => error = messageFor(exception));
    } finally {
      if (mounted) setState(() => loadingProfileContacts = false);
    }
  }

  Future<void> editProfileContacts() async {
    await context.push('/profile');
    if (mounted) {
      setState(() => loadingProfileContacts = true);
      await loadProfileContacts();
    }
  }

  Future<void> detectLocation() async {
    setState(() {
      fetchingLocation = true;
      locationStatus = null;
    });
    final result = await LocationService().current();
    if (mounted) {
      setState(() {
        fetchingLocation = false;
        if (result.position != null) {
          lat = result.position!.latitude;
          lng = result.position!.longitude;
          locationStatus = result.message ??
              'Location updated (${lat!.toStringAsFixed(4)}, ${lng!.toStringAsFixed(4)})';
        } else {
          locationStatus = result.message ?? 'Could not detect location.';
        }
      });
    }
  }

  Future<void> pickImages() async {
    final picker = ImagePicker();
    final images =
        await picker.pickMultiImage(imageQuality: 82, maxWidth: 1200);
    if (images.isNotEmpty) {
      setState(() {
        selectedImages = images.take(2).toList();
      });
    }
  }

  Future<void> pickDriverPhoto() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 900,
    );
    if (image != null && mounted) setState(() => driverPhoto = image);
  }

  bool get hasDriver => type != 'vehicle_without_driver';
  bool get hasVehicle => type != 'driver_only';

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
    return 'Could not submit your listing. Complete your provider profile first.';
  }

  Future<void> submit() async {
    if (title.text.trim().isEmpty) {
      setState(() => error = 'Please enter a title for your listing.');
      return;
    }
    if (!profileContactsValid) {
      setState(
        () => error =
            'Update your mobile and WhatsApp numbers in your profile first.',
      );
      return;
    }
    if (!providerProfileComplete) {
      setState(
        () => error = 'Complete the provider section in your profile first.',
      );
      return;
    }
    if (lat == null || lng == null) {
      setState(
        () => error = 'Detect your GPS location before creating the listing.',
      );
      return;
    }
    if (hasVehicle && vehicleNumber.text.trim().isEmpty) {
      setState(() => error = 'Please enter the vehicle number.');
      return;
    }
    if (hasVehicle && selectedImages.length != 2) {
      setState(() => error = 'Please select exactly two vehicle photos.');
      return;
    }
    if (hasDriver && driverLicenseNumber.text.trim().isEmpty) {
      setState(() => error = 'Please enter the driver licence number.');
      return;
    }
    if (hasDriver && driverPhoto == null) {
      setState(() => error = 'Please select a clear driver photo.');
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final dio = ref.read(apiProvider).dio;

      if (driverPhoto != null) {
        final avatar = await MultipartFile.fromFile(
          driverPhoto!.path,
          filename: driverPhoto!.name,
        );
        await dio.post(
          '/auth/me/avatar',
          data: FormData.fromMap({'avatar': avatar}),
        );
      }

      final response = await dio.post(
        '/provider/listings',
        data: {
          'listingType': type,
          'categoryId': categoryId,
          'title': title.text.trim(),
          'description':
              description.text.trim().isEmpty ? null : description.text.trim(),
          'manufacturer': manufacturer.text.trim().isEmpty
              ? null
              : manufacturer.text.trim(),
          'model': model.text.trim().isEmpty ? null : model.text.trim(),
          'registrationNumber':
              hasVehicle ? vehicleNumber.text.trim().toUpperCase() : null,
          'driverLicenseNumber':
              hasDriver ? driverLicenseNumber.text.trim().toUpperCase() : null,
          'manufacturedYear': int.tryParse(year.text.trim()),
          'passengerCapacity': int.tryParse(passengerCapacity.text.trim()),
          'loadCapacityKg': double.tryParse(loadCapacity.text.trim()),
          'startingPrice': double.tryParse(startingPrice.text.trim()),
          'priceUnit': priceUnit,
          'hasAirConditioning': hasAirConditioning,
          'longDistanceAvailable': longDistanceAvailable,
          'latitude': lat!,
          'longitude': lng!,
          'publicAreaName': area.text.trim().isEmpty ? null : area.text.trim(),
        },
      );

      final publicId = response.data['data']['publicId'] as String?;
      final createdStatus = response.data['data']['status'] as String?;

      if (publicId != null && selectedImages.isNotEmpty) {
        final formFiles = <MultipartFile>[];
        for (final img in selectedImages) {
          formFiles
              .add(await MultipartFile.fromFile(img.path, filename: img.name));
        }
        await dio.post(
          '/provider/listings/$publicId/images',
          data: FormData.fromMap({'images': formFiles}),
        );
      }

      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(
              createdStatus == 'active'
                  ? 'Listing Published'
                  : 'Listing Pending Review',
            ),
            content: Text(
              createdStatus == 'active'
                  ? 'Your listing is active and can now appear in nearby feeds.'
                  : 'Your listing was saved successfully but will not appear in public feeds until it is approved.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (exception) {
      if (exception is DioException && exception.response?.statusCode == 401) {
        if (mounted) context.go('/login?redirect=%2Fprovider');
        return;
      }
      if (mounted) setState(() => error = messageFor(exception));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void nextStep() {
    if (step == 1 && title.text.trim().isEmpty) {
      setState(() => error = 'Please enter a title for your listing.');
      return;
    }
    if (step == 4 && !profileContactsValid) {
      setState(
        () => error =
            'Update your mobile and WhatsApp numbers in your profile first.',
      );
      return;
    }
    if (step == 4 && !providerProfileComplete) {
      setState(
        () => error = 'Complete the provider section in your profile first.',
      );
      return;
    }
    if (step == 3 && (lat == null || lng == null)) {
      setState(
        () => error = 'Detect your GPS location before continuing.',
      );
      return;
    }
    if (step == 1 && hasVehicle && vehicleNumber.text.trim().isEmpty) {
      setState(() => error = 'Please enter the vehicle number.');
      return;
    }
    if (step == 1 && hasDriver && driverLicenseNumber.text.trim().isEmpty) {
      setState(() => error = 'Please enter the driver licence number.');
      return;
    }
    if (step == 4 && hasVehicle && selectedImages.length != 2) {
      setState(() => error = 'Please select exactly two vehicle photos.');
      return;
    }
    if (step == 4 && hasDriver && driverPhoto == null) {
      setState(() => error = 'Please select a clear driver photo.');
      return;
    }
    setState(() {
      error = null;
      if (step < 4) {
        step++;
      } else {
        submit();
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Create Listing')),
        body: loading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Submitting your listing…'),
                  ],
                ),
              )
            : Stepper(
                currentStep: step,
                onStepContinue: nextStep,
                onStepCancel: step == 0 ? null : () => setState(() => step--),
                controlsBuilder: (context, details) => Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Row(
                    children: [
                      FilledButton(
                        onPressed: details.onStepContinue,
                        child: Text(step == 4 ? 'Submit Listing' : 'Continue'),
                      ),
                      const SizedBox(width: 8),
                      if (step > 0)
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Back'),
                        ),
                    ],
                  ),
                ),
                steps: [
                  Step(
                    title: const Text('Category & Type'),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<int>(
                          initialValue: categoryId,
                          decoration: const InputDecoration(
                              labelText: 'Vehicle Category'),
                          items: const [
                            DropdownMenuItem(
                                value: 1, child: Text('Motorbike')),
                            DropdownMenuItem(
                                value: 2, child: Text('Three Wheeler')),
                            DropdownMenuItem(value: 3, child: Text('Car')),
                            DropdownMenuItem(value: 4, child: Text('SUV')),
                            DropdownMenuItem(value: 5, child: Text('Van')),
                            DropdownMenuItem(value: 6, child: Text('Bus')),
                            DropdownMenuItem(value: 7, child: Text('Pickup')),
                            DropdownMenuItem(value: 8, child: Text('Lorry')),
                            DropdownMenuItem(
                                value: 9, child: Text('Tow Vehicle')),
                            DropdownMenuItem(value: 10, child: Text('Tractor')),
                            DropdownMenuItem(value: 11, child: Text('Other')),
                          ],
                          onChanged: (val) => setState(() => categoryId = val),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: type,
                          decoration: const InputDecoration(
                              labelText: 'Listing Service Type'),
                          items: const [
                            DropdownMenuItem(
                                value: 'vehicle_with_driver',
                                child: Text('Vehicle with driver')),
                            DropdownMenuItem(
                                value: 'vehicle_without_driver',
                                child: Text('Vehicle without driver')),
                            DropdownMenuItem(
                                value: 'driver_only',
                                child: Text('Driver only')),
                          ],
                          onChanged: (val) => setState(() => type = val!),
                        ),
                      ],
                    ),
                  ),
                  Step(
                    title: const Text('Vehicle & Service Details'),
                    content: Column(
                      children: [
                        TextField(
                          controller: title,
                          decoration: const InputDecoration(
                            labelText: 'Listing Title *',
                            hintText: 'e.g. Toyota KDH Super GL Van for Rent',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: description,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText:
                                'Describe vehicle features, terms, or services offered...',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: manufacturer,
                                decoration: const InputDecoration(
                                    labelText: 'Make (e.g. Toyota)'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: model,
                                decoration: const InputDecoration(
                                    labelText: 'Model (e.g. HiAce)'),
                              ),
                            ),
                          ],
                        ),
                        if (hasVehicle) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: vehicleNumber,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Vehicle Number *',
                              hintText: 'e.g. WP CAB-1234',
                            ),
                          ),
                        ],
                        if (hasDriver) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: driverLicenseNumber,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Driver Licence Number *',
                              helperText:
                                  'Stored securely and used for provider verification.',
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: year,
                                keyboardType: TextInputType.number,
                                decoration:
                                    const InputDecoration(labelText: 'Year'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: passengerCapacity,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    labelText: 'Passengers'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Step(
                    title: const Text('Pricing & Availability'),
                    content: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: startingPrice,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    labelText: 'Starting Price (LKR)'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: priceUnit,
                                decoration:
                                    const InputDecoration(labelText: 'Unit'),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'per_km', child: Text('Per KM')),
                                  DropdownMenuItem(
                                      value: 'per_hour',
                                      child: Text('Per Hour')),
                                  DropdownMenuItem(
                                      value: 'per_day', child: Text('Per Day')),
                                  DropdownMenuItem(
                                      value: 'fixed',
                                      child: Text('Fixed Rate')),
                                  DropdownMenuItem(
                                      value: 'negotiable',
                                      child: Text('Negotiable')),
                                ],
                                onChanged: (val) =>
                                    setState(() => priceUnit = val!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          value: hasAirConditioning,
                          onChanged: (val) =>
                              setState(() => hasAirConditioning = val),
                          title: const Text('Air Conditioned'),
                        ),
                        SwitchListTile(
                          value: longDistanceAvailable,
                          onChanged: (val) =>
                              setState(() => longDistanceAvailable = val),
                          title: const Text('Long Distance Trips'),
                        ),
                      ],
                    ),
                  ),
                  Step(
                    title: const Text('Location'),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: area,
                          decoration: const InputDecoration(
                            labelText: 'Approximate Service Area / City',
                            hintText: 'e.g. Colombo 03 / Dehiwala',
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: fetchingLocation ? null : detectLocation,
                          icon: fetchingLocation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.my_location),
                          label: Text(fetchingLocation
                              ? 'Detecting...'
                              : 'Detect Current GPS Coordinates'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          lat == null || lng == null
                              ? 'GPS location is required. Exact coordinates remain private.'
                              : 'GPS Coordinates: ${lat!.toStringAsFixed(4)}, ${lng!.toStringAsFixed(4)} (Exact location is kept private)',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (locationStatus != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              locationStatus!,
                              style: TextStyle(
                                color: lat != null && lng != null
                                    ? Colors.green
                                    : Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        if (locationStatus?.contains('turned off') == true)
                          TextButton.icon(
                            onPressed: () async {
                              await LocationService().openLocationSettings();
                            },
                            icon: const Icon(Icons.settings_outlined),
                            label: const Text('Open Location Settings'),
                          ),
                        if (locationStatus?.contains('permanently denied') ==
                            true)
                          TextButton.icon(
                            onPressed: () async {
                              await LocationService().openAppSettings();
                            },
                            icon: const Icon(Icons.settings_outlined),
                            label: const Text('Open App Settings'),
                          ),
                      ],
                    ),
                  ),
                  Step(
                    title: const Text('Contact & Photos'),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact Details',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Card(
                          margin: EdgeInsets.zero,
                          child: loadingProfileContacts
                              ? const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : Column(
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.phone_outlined),
                                      title: const Text('Mobile'),
                                      subtitle: Text(
                                        profilePhone ?? 'Not configured',
                                      ),
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.chat_outlined),
                                      title: const Text('WhatsApp'),
                                      subtitle: Text(
                                        profileWhatsapp ?? 'Not configured',
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: loadingProfileContacts
                              ? null
                              : editProfileContacts,
                          icon: const Icon(Icons.manage_accounts_outlined),
                          label: Text(
                            profileContactsValid && providerProfileComplete
                                ? 'Update Provider Profile'
                                : 'Complete Provider Profile',
                          ),
                        ),
                        if (!loadingProfileContacts &&
                            (!profileContactsValid || !providerProfileComplete))
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              !profileContactsValid
                                  ? 'A valid mobile and WhatsApp number are required before creating a listing.'
                                  : 'Complete the provider section in your profile before creating a listing.',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        if (hasVehicle) ...[
                          Text(
                            'Vehicle Photos *',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: pickImages,
                            icon: const Icon(Icons.add_a_photo_outlined),
                            label: Text(
                              selectedImages.length == 2
                                  ? 'Change Vehicle Photos (2 selected)'
                                  : 'Select Exactly 2 Vehicle Photos',
                            ),
                          ),
                          if (selectedImages.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: selectedImages
                                    .map(
                                      (img) => Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.file(
                                            File(img.path),
                                            width: 88,
                                            height: 72,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                        ],
                        if (hasDriver) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Driver Photo *',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: pickDriverPhoto,
                            icon: const Icon(Icons.person_add_alt_1_outlined),
                            label: Text(
                              driverPhoto == null
                                  ? 'Select Driver Photo'
                                  : 'Change Driver Photo',
                            ),
                          ),
                          if (driverPhoto != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: CircleAvatar(
                                radius: 44,
                                backgroundImage:
                                    FileImage(File(driverPhoto!.path)),
                              ),
                            ),
                        ],
                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              error!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      );
}
