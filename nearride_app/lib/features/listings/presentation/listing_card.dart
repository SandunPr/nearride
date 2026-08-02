import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/vehicle_listing.dart';

class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.listing});
  final VehicleListing listing;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/listing/${listing.publicId}'),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              height: 150,
              width: double.infinity,
              child: listing.thumbnailUrl == null
                  ? Container(color: Colors.grey.shade200, child: const Icon(Icons.directions_car, size: 58))
                  : CachedNetworkImage(imageUrl: listing.thumbnailUrl!, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(Icons.broken_image)),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(listing.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_border)),
                ]),
                Text('${listing.typeLabel} • ${listing.distanceLabel}'),
                const SizedBox(height: 8),
                Row(children: [
                  Icon(listing.availableNow ? Icons.check_circle : Icons.schedule, size: 18, color: listing.availableNow ? Colors.green : Colors.orange),
                  const SizedBox(width: 5),
                  Text(listing.availableNow ? 'Available now' : 'Check availability'),
                  if (listing.passengerCapacity != null) ...[const Spacer(), Text('Seats: ${listing.passengerCapacity}')],
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    backgroundImage: listing.providerAvatarUrl == null ? null : CachedNetworkImageProvider(listing.providerAvatarUrl!),
                    child: listing.providerAvatarUrl == null ? Text(listing.providerName.isEmpty ? '?' : listing.providerName.characters.first.toUpperCase()) : null,
                  ),
                  const SizedBox(width: 9),
                  Expanded(child: Text(listing.providerName, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (listing.providerVerified) ...[const SizedBox(width: 4), Icon(Icons.verified, size: 17, color: Theme.of(context).colorScheme.primary)],
                ]),
              ]),
            ),
          ]),
        ),
      );
}
