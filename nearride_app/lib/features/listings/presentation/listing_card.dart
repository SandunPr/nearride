import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/token_store.dart';
import '../../../shared/models/vehicle_listing.dart';
import '../../../shared/providers/providers.dart';

class ListingCard extends ConsumerStatefulWidget {
  const ListingCard({
    super.key,
    required this.listing,
    this.initiallySaved = false,
    this.onRemoved,
  });

  final VehicleListing listing;
  final bool initiallySaved;
  final VoidCallback? onRemoved;

  @override
  ConsumerState<ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends ConsumerState<ListingCard> {
  late bool saved = widget.initiallySaved;
  bool saving = false;

  Future<void> toggleFavourite() async {
    final token = await const TokenStore().access();
    if (token == null || token.isEmpty) {
      if (mounted) context.push('/login');
      return;
    }
    setState(() => saving = true);
    try {
      final repository = ref.read(listingRepositoryProvider);
      if (saved) {
        await repository.removeFavourite(widget.listing.publicId);
      } else {
        await repository.saveFavourite(widget.listing.publicId);
      }
      if (mounted) {
        setState(() => saved = !saved);
        if (!saved) widget.onRemoved?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(saved
                ? 'Listing added to favourites.'
                : 'Listing removed from favourites.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update favourites.')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/listing/${listing.publicId}'),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 108,
                  height: 162,
                  child: listing.thumbnailUrl == null
                      ? Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.directions_car, size: 42),
                        )
                      : CachedNetworkImage(
                          imageUrl: listing.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              const Icon(Icons.broken_image),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            listing.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: saved
                              ? 'Remove from favourites'
                              : 'Add to favourites',
                          onPressed: saving ? null : toggleFavourite,
                          icon: Icon(
                            saved ? Icons.favorite : Icons.favorite_border,
                            color: saved
                                ? Theme.of(context).colorScheme.error
                                : null,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      [listing.vehicleLabel, listing.typeLabel]
                          .whereType<String>()
                          .join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 15),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            [listing.publicAreaName, listing.distanceLabel]
                                .whereType<String>()
                                .join(' • '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: [
                        if (listing.passengerCapacity != null)
                          _DetailPill(
                            icon: Icons.airline_seat_recline_normal,
                            label: '${listing.passengerCapacity} Seats',
                          ),
                        if (listing.hasAirConditioning)
                          const _DetailPill(icon: Icons.ac_unit, label: 'A/C'),
                        if (listing.longDistanceAvailable)
                          const _DetailPill(
                            icon: Icons.route_outlined,
                            label: 'Long Distance',
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundImage: listing.providerAvatarUrl == null
                              ? null
                              : CachedNetworkImageProvider(
                                  listing.providerAvatarUrl!,
                                ),
                          child: listing.providerAvatarUrl == null
                              ? Text(listing.providerName.isEmpty
                                  ? '?'
                                  : listing.providerName.characters.first
                                      .toUpperCase())
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            listing.providerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        if (listing.providerVerified)
                          Icon(
                            Icons.verified,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          listing.availableNow
                              ? Icons.check_circle
                              : Icons.schedule,
                          size: 15,
                          color:
                              listing.availableNow ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          listing.availableNow ? 'Available Now' : 'Ask Availability',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const Spacer(),
                        if (listing.priceLabel != null)
                          Text(
                            listing.priceLabel!,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12),
            const SizedBox(width: 3),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      );
}
