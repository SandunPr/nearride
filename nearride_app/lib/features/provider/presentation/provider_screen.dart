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
  final year = TextEditingController();
  final passengerCapacity = TextEditingController();
  final loadCapacity = TextEditingController();
  final startingPrice = TextEditingController();
  String priceUnit = 'negotiable';
  bool hasAirConditioning = true;
  bool availableNow = true;
  bool longDistanceAvailable = true;
  final area = TextEditingController();
  final phone = TextEditingController();
  final whatsapp = TextEditingController();

  double lat = 6.9271;
  double lng = 79.8612;
  bool fetchingLocation = false;
  String? locationStatus;

  List<XFile> selectedImages = [];
  bool loading = false;
  String? error;

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    manufacturer.dispose();
    model.dispose();
    year.dispose();
    passengerCapacity.dispose();
    loadCapacity.dispose();
    startingPrice.dispose();
    area.dispose();
    phone.dispose();
    whatsapp.dispose();
    super.dispose();
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
          locationStatus = 'Location updated (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';
        } else {
          locationStatus = result.message ?? 'Could not detect location.';
        }
      });
    }
  }

  Future<void> pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 82, maxWidth: 1200);
    if (images.isNotEmpty) {
      setState(() {
        selectedImages = images.take(2).toList();
      });
    }
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
    return 'Could not submit your listing. Complete your provider profile first.';
  }

  Future<void> submit() async {
    if (title.text.trim().isEmpty) {
      setState(() => error = 'Please enter a title for your listing.');
      return;
    }
    if (phone.text.trim().isEmpty) {
      setState(() => error = 'Please enter a contact phone number.');
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final dio = ref.read(apiProvider).dio;
      final response = await dio.post(
        '/provider/listings',
        data: {
          'listingType': type,
          'categoryId': categoryId,
          'title': title.text.trim(),
          'description': description.text.trim().isEmpty ? null : description.text.trim(),
          'manufacturer': manufacturer.text.trim().isEmpty ? null : manufacturer.text.trim(),
          'model': model.text.trim().isEmpty ? null : model.text.trim(),
          'manufacturedYear': int.tryParse(year.text.trim()),
          'passengerCapacity': int.tryParse(passengerCapacity.text.trim()),
          'loadCapacityKg': double.tryParse(loadCapacity.text.trim()),
          'startingPrice': double.tryParse(startingPrice.text.trim()),
          'priceUnit': priceUnit,
          'hasAirConditioning': hasAirConditioning,
          'availableNow': availableNow,
          'longDistanceAvailable': longDistanceAvailable,
          'latitude': lat,
          'longitude': lng,
          'publicAreaName': area.text.trim().isEmpty ? null : area.text.trim(),
          'phone': phone.text.trim(),
          'whatsappNumber': whatsapp.text.trim().isEmpty ? null : whatsapp.text.trim(),
        },
      );

      final publicId = response.data['data']['publicId'] as String?;

      if (publicId != null && selectedImages.isNotEmpty) {
        final formFiles = <MultipartFile>[];
        for (final img in selectedImages) {
          formFiles.add(await MultipartFile.fromFile(img.path, filename: img.name));
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
            title: const Text('Listing Submitted'),
            content: const Text(
              'Your listing was created successfully and is now active or pending review.',
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
    if (step == 4 && phone.text.trim().isEmpty) {
      setState(() => error = 'Please enter a contact phone number.');
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
                          decoration: const InputDecoration(labelText: 'Vehicle Category'),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('Motorbike')),
                            DropdownMenuItem(value: 2, child: Text('Three Wheeler')),
                            DropdownMenuItem(value: 3, child: Text('Car')),
                            DropdownMenuItem(value: 4, child: Text('SUV')),
                            DropdownMenuItem(value: 5, child: Text('Van')),
                            DropdownMenuItem(value: 6, child: Text('Bus')),
                            DropdownMenuItem(value: 7, child: Text('Pickup')),
                            DropdownMenuItem(value: 8, child: Text('Lorry')),
                            DropdownMenuItem(value: 9, child: Text('Tow Vehicle')),
                            DropdownMenuItem(value: 10, child: Text('Tractor')),
                            DropdownMenuItem(value: 11, child: Text('Other')),
                          ],
                          onChanged: (val) => setState(() => categoryId = val),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: type,
                          decoration: const InputDecoration(labelText: 'Listing Service Type'),
                          items: const [
                            DropdownMenuItem(value: 'vehicle_with_driver', child: Text('Vehicle with driver')),
                            DropdownMenuItem(value: 'vehicle_without_driver', child: Text('Vehicle without driver')),
                            DropdownMenuItem(value: 'driver_only', child: Text('Driver only')),
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
                            hintText: 'Describe vehicle features, terms, or services offered...',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: manufacturer,
                                decoration: const InputDecoration(labelText: 'Make (e.g. Toyota)'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: model,
                                decoration: const InputDecoration(labelText: 'Model (e.g. HiAce)'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: year,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Year'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: passengerCapacity,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Passengers'),
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
                                decoration: const InputDecoration(labelText: 'Starting Price (LKR)'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: priceUnit,
                                decoration: const InputDecoration(labelText: 'Unit'),
                                items: const [
                                  DropdownMenuItem(value: 'per_km', child: Text('Per KM')),
                                  DropdownMenuItem(value: 'per_hour', child: Text('Per Hour')),
                                  DropdownMenuItem(value: 'per_day', child: Text('Per Day')),
                                  DropdownMenuItem(value: 'fixed', child: Text('Fixed Rate')),
                                  DropdownMenuItem(value: 'negotiable', child: Text('Negotiable')),
                                ],
                                onChanged: (val) => setState(() => priceUnit = val!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          value: availableNow,
                          onChanged: (val) => setState(() => availableNow = val),
                          title: const Text('Available Now'),
                        ),
                        SwitchListTile(
                          value: hasAirConditioning,
                          onChanged: (val) => setState(() => hasAirConditioning = val),
                          title: const Text('Air Conditioned'),
                        ),
                        SwitchListTile(
                          value: longDistanceAvailable,
                          onChanged: (val) => setState(() => longDistanceAvailable = val),
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
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.my_location),
                          label: Text(fetchingLocation ? 'Detecting...' : 'Detect Current GPS Coordinates'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'GPS Coordinates: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)} (Exact location is kept private)',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (locationStatus != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              locationStatus!,
                              style: TextStyle(
                                color: locationStatus!.contains('updated')
                                    ? Colors.green
                                    : Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Step(
                    title: const Text('Contact & Photos'),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: phone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Primary Phone Number *'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: whatsapp,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'WhatsApp Number (Optional)'),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: pickImages,
                          icon: const Icon(Icons.add_a_photo_outlined),
                          label: Text(selectedImages.isEmpty ? 'Select Vehicle Photos (Max 2)' : 'Change Selected Photos (${selectedImages.length})'),
                        ),
                        if (selectedImages.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: selectedImages
                                  .map(
                                    (img) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          File(img.path),
                                          width: 64,
                                          height: 64,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              error!,
                              style: TextStyle(color: Theme.of(context).colorScheme.error),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      );
}
