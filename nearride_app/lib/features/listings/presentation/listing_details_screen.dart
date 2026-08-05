import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/ads/admob_banner.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/vehicle_listing.dart';
import '../../../shared/providers/providers.dart';

class ListingDetailsScreen extends ConsumerWidget {
  const ListingDetailsScreen({
    super.key,
    required this.id,
    this.distanceKm,
  });

  final String id;
  final double? distanceKm;

  String distanceLabel(double distance) => distance < 1
      ? '${(distance * 1000).round()} m away'
      : '${distance.toStringAsFixed(1)} km away';

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

  Widget infoRow(
          BuildContext context, IconData icon, String label, String value) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 9),
          SizedBox(
            width: 92,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ]),
      );

  Widget section(BuildContext context,
          {required String title,
          required IconData icon,
          required List<Widget> children}) =>
      Card(
        margin: const EdgeInsets.only(top: 12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ]),
              const Divider(height: 18),
              ...children,
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: const Text('Listing details')),
        bottomNavigationBar: const AdMobBanner(),
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
            final resolvedDistance = listing.distanceKm ?? distanceKm;
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
              Text(
                [
                  listing.typeLabel,
                  if (resolvedDistance != null) distanceLabel(resolvedDistance),
                ].join(' • '),
              ),
              const SizedBox(height: 16),
              Wrap(spacing: 8, children: [
                if (listing.listingVerified)
                  const Chip(
                    avatar: Icon(Icons.verified, size: 18),
                    label: Text('Verified listing'),
                  ),
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
              section(
                context,
                title: 'Vehicle Details',
                icon: Icons.directions_car_outlined,
                children: [
                  if (listing.vehicleLabel != null)
                    infoRow(context, Icons.badge_outlined, 'Vehicle',
                        listing.vehicleLabel!),
                  if (listing.categoryName != null)
                    infoRow(context, Icons.category_outlined, 'Category',
                        listing.categoryName!),
                  if (listing.manufacturedYear != null)
                    infoRow(context, Icons.calendar_today_outlined, 'Year',
                        '${listing.manufacturedYear}'),
                  if (listing.registrationNumber != null)
                    infoRow(context, Icons.pin_outlined, 'Registration',
                        listing.registrationNumber!),
                  if (listing.passengerCapacity != null)
                    infoRow(context, Icons.airline_seat_recline_normal,
                        'Capacity', '${listing.passengerCapacity} Seats'),
                  if (listing.loadCapacityKg != null)
                    infoRow(context, Icons.scale_outlined, 'Load Capacity',
                        '${listing.loadCapacityKg!.toStringAsFixed(0)} kg'),
                  infoRow(context, Icons.ac_unit, 'Air Conditioning',
                      listing.hasAirConditioning ? 'Available' : 'Not Listed'),
                ],
              ),
              section(
                context,
                title: 'Driver & Service',
                icon: Icons.person_outline,
                children: [
                  if (listing.listingVerified)
                    infoRow(
                      context,
                      Icons.verified_outlined,
                      'Listing',
                      'Admin reviewed and verified',
                    ),
                  infoRow(context, Icons.person_outline, 'Provider',
                      listing.providerName),
                  if (listing.providerVerified)
                    infoRow(
                      context,
                      Icons.verified_user_outlined,
                      'Verification',
                      'Verified Provider',
                    ),
                  infoRow(context, Icons.work_outline, 'Service Type',
                      listing.typeLabel),
                  infoRow(
                    context,
                    Icons.check_circle_outline,
                    'Availability',
                    listing.availableNow ? 'Available Now' : 'Currently Busy',
                  ),
                  infoRow(
                      context,
                      Icons.route_outlined,
                      'Long Distance',
                      listing.longDistanceAvailable
                          ? 'Available'
                          : 'Not Listed'),
                  if (listing.emergencyContactAvailable)
                    infoRow(context, Icons.emergency_outlined, 'Emergency',
                        'Contact Available'),
                ],
              ),
              section(
                context,
                title: 'Location & Pricing',
                icon: Icons.payments_outlined,
                children: [
                  if (listing.publicAreaName != null)
                    infoRow(context, Icons.location_on_outlined, 'Area',
                        listing.publicAreaName!),
                  if (resolvedDistance != null)
                    infoRow(
                      context,
                      Icons.near_me_outlined,
                      'Distance',
                      distanceLabel(resolvedDistance),
                    ),
                  if (listing.priceLabel != null)
                    infoRow(context, Icons.payments_outlined, 'Starting Price',
                        listing.priceLabel!),
                ],
              ),
              const SizedBox(height: 12),
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
