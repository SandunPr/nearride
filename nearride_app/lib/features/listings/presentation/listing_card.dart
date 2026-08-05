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
        onTap: () {
          final distance = listing.distanceKm;
          final location = Uri(
            path: '/listing/${listing.publicId}',
            queryParameters:
                distance == null ? null : {'distanceKm': '$distance'},
          ).toString();
          context.push(location);
        },
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 82,
                  height: 102,
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
              const SizedBox(width: 9),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (listing.listingVerified)
                          Padding(
                            padding: const EdgeInsets.only(right: 4, top: 2),
                            child: Icon(
                              Icons.verified,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        IconButton(
                          constraints: const BoxConstraints.tightFor(
                            width: 30,
                            height: 30,
                          ),
                          padding: EdgeInsets.zero,
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
                    const SizedBox(height: 3),
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
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 14),
                        const SizedBox(width: 3),
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
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          listing.availableNow
                              ? Icons.check_circle
                              : Icons.schedule,
                          size: 15,
                          color: listing.availableNow
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          listing.availableNow
                              ? 'Available'
                              : 'Ask Availability',
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
