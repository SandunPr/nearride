import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/providers/providers.dart';

class AdminListingsScreen extends ConsumerStatefulWidget {
  const AdminListingsScreen({super.key});

  @override
  ConsumerState<AdminListingsScreen> createState() =>
      _AdminListingsScreenState();
}

class _AdminListingsScreenState extends ConsumerState<AdminListingsScreen> {
  List<Map<String, dynamic>> listings = const [];
  bool loading = true;
  String? error;
  String? processingId;

  @override
  void initState() {
    super.initState();
    load();
  }

  String messageFor(Object exception) {
    if (exception is DioException) {
      final data = exception.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
    }
    return 'Could not load the moderation queue.';
  }

  Future<void> load() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }
    try {
      final response = await ref.read(apiProvider).dio.get(
        '/admin/listings',
        queryParameters: {'status': 'pending'},
      );
      final data = response.data['data'] as List? ?? const [];
      if (mounted) {
        setState(() {
          listings = data
              .whereType<Map>()
              .map(Map<String, dynamic>.from)
              .toList(growable: false);
        });
      }
    } on DioException catch (exception) {
      if (exception.response?.statusCode == 401) {
        if (mounted) context.go('/login?redirect=%2Fadmin%2Flistings');
        return;
      }
      if (mounted) setState(() => error = messageFor(exception));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> moderate(
    Map<String, dynamic> listing,
    String status, {
    String? note,
  }) async {
    final publicId = listing['publicId'] as String;
    setState(() {
      processingId = publicId;
      error = null;
    });
    try {
      final response = await ref.read(apiProvider).dio.patch(
        '/admin/listings/$publicId/moderation',
        data: {'status': status, 'moderationNote': note},
      );
      if (mounted) {
        setState(() => listings = listings
            .where((item) => item['publicId'] != publicId)
            .toList(growable: false));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.data['message'] as String)),
        );
      }
    } catch (exception) {
      if (mounted) setState(() => error = messageFor(exception));
    } finally {
      if (mounted) setState(() => processingId = null);
    }
  }

  Future<void> approve(Map<String, dynamic> listing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve listing?'),
        content: Text(
          '“${listing['title']}” will become visible in public feeds.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await moderate(listing, 'active');
  }

  Future<void> reject(Map<String, dynamic> listing) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject listing'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 500,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Reason *',
            hintText: 'Explain what the provider needs to correct',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (note != null && mounted) {
      await moderate(listing, 'rejected', note: note);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Listing approvals'),
          actions: [
            IconButton(
              onPressed: loading ? null : load,
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(error!),
                ),
              if (loading)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (listings.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child:
                      Center(child: Text('No listings are awaiting review.')),
                )
              else
                ...listings.map(
                  (listing) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _ModerationCard(
                      listing: listing,
                      processing: processingId == listing['publicId'],
                      onApprove: () => approve(listing),
                      onReject: () => reject(listing),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
}

class _ModerationCard extends StatelessWidget {
  const _ModerationCard({
    required this.listing,
    required this.processing,
    required this.onApprove,
    required this.onReject,
  });

  final Map<String, dynamic> listing;
  final bool processing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final thumbnail = listing['thumbnailUrl'] as String?;
    final rawImageCount = listing['imageCount'];
    final imageCount = rawImageCount is num
        ? rawImageCount.toInt()
        : int.tryParse('$rawImageCount') ?? 0;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 170,
            width: double.infinity,
            child: thumbnail == null
                ? Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.directions_car, size: 58),
                  )
                : CachedNetworkImage(
                    imageUrl: thumbnail,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.broken_image, size: 48),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing['title'] as String? ?? 'Untitled listing',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${listing['listingType']} • $imageCount photos',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                Text(listing['description'] as String? ?? 'No description'),
                const SizedBox(height: 10),
                Text(
                  'Provider: ${listing['providerName']} (${listing['providerEmail']})',
                ),
                Text('Area: ${listing['publicAreaName'] ?? 'Not provided'}'),
                Text(
                  'Vehicle: ${listing['manufacturer'] ?? '-'} ${listing['model'] ?? '-'} • ${listing['registrationNumberMasked'] ?? '-'}',
                ),
                const SizedBox(height: 14),
                if (processing)
                  const Center(child: CircularProgressIndicator())
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onReject,
                          icon: const Icon(Icons.close),
                          label: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onApprove,
                          icon: const Icon(Icons.check),
                          label: const Text('Approve'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
