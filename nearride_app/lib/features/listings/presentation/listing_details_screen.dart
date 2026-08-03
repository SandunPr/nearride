import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/models/vehicle_listing.dart';
import '../../../shared/providers/providers.dart';

class ListingDetailsScreen extends ConsumerWidget {
  const ListingDetailsScreen({super.key, required this.id});
  final String id;

  String normalized(String value) {
    var number = value.replaceAll(RegExp(r'[^0-9+]'), '');
    if (number.startsWith('0')) number = '+94${number.substring(1)}';
    return number;
  }

  Future<void> contact(
      WidgetRef ref, VehicleListing listing, bool whatsapp) async {
    ref
        .read(listingRepositoryProvider)
        .event(listing.publicId, whatsapp ? 'whatsapp_click' : 'phone_click');
    final number = normalized(
        whatsapp ? listing.whatsappNumber ?? listing.phone : listing.phone);
    final uri = whatsapp
        ? Uri.parse(
            'https://wa.me/${number.replaceFirst('+', '')}?text=${Uri.encodeComponent('Hello, I found your vehicle listing on NearRide. Is it currently available?')}')
        : Uri.parse('tel:$number');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: const Text('Listing details')),
        body: FutureBuilder<VehicleListing>(
          future: ref.read(listingRepositoryProvider).detail(id),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Could not load this listing.'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final listing = snapshot.data!;
            return ListView(padding: const EdgeInsets.all(20), children: [
              SizedBox(
                height: 220,
                child: listing.images.isEmpty
                    ? Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.directions_car, size: 80),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: listing.images.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) => ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            width: MediaQuery.sizeOf(context).width - 56,
                            child: CachedNetworkImage(
                              imageUrl: listing.images[index],
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image, size: 54),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              Text(listing.title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text('${listing.typeLabel} • ${listing.distanceLabel}'),
              const SizedBox(height: 16),
              Wrap(spacing: 8, children: [
                Chip(
                    label: Text(listing.availableNow
                        ? 'Available now'
                        : 'Ask availability')),
                if (listing.passengerCapacity != null)
                  Chip(label: Text('${listing.passengerCapacity} seats')),
                if (listing.registrationNumber != null)
                  Chip(
                    avatar: const Icon(Icons.pin_outlined, size: 18),
                    label: Text(listing.registrationNumber!),
                  ),
              ]),
              const Divider(height: 32),
              Row(children: [
                CircleAvatar(
                  backgroundImage: listing.providerAvatarUrl == null
                      ? null
                      : CachedNetworkImageProvider(listing.providerAvatarUrl!),
                  child: listing.providerAvatarUrl == null
                      ? Text(listing.providerName.isEmpty
                          ? '?'
                          : listing.providerName.characters.first.toUpperCase())
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(listing.providerName,
                        style: Theme.of(context).textTheme.titleMedium)),
                if (listing.providerVerified)
                  const Icon(Icons.verified, color: Colors.teal),
              ]),
              const SizedBox(height: 20),
              Text(listing.description ??
                  'Contact the provider to confirm vehicle details, pricing, pickup, timing, licensing and availability.'),
              const SizedBox(height: 20),
              Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Text(
                      'Safety: Avoid advance transfers before verifying the provider and vehicle. This platform does not guarantee service quality or safety.')),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                    child: FilledButton.icon(
                        onPressed: () => contact(ref, listing, false),
                        icon: const Icon(Icons.call),
                        label: const Text('Call'))),
                const SizedBox(width: 10),
                Expanded(
                    child: FilledButton.tonalIcon(
                        onPressed: () => contact(ref, listing, true),
                        icon: const Icon(Icons.chat),
                        label: const Text('WhatsApp'))),
              ]),
              const SizedBox(height: 24),
              Text(AppConstants.disclaimer,
                  style: Theme.of(context).textTheme.bodySmall),
              TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Report this listing')),
            ]);
          },
        ),
      );
}
