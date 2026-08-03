import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/vehicle_listing.dart';
import '../../../shared/providers/providers.dart';
import '../../listings/presentation/listing_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final controller = TextEditingController();
  List<VehicleListing> results = const [];
  bool loading = false;
  bool searched = false;
  String? error;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> search() async {
    FocusScope.of(context).unfocus();
    setState(() {
      loading = true;
      searched = true;
      error = null;
    });
    try {
      final items = await ref.read(listingRepositoryProvider).search(
            query: controller.text,
          );
      if (mounted) setState(() => results = items);
    } catch (_) {
      if (mounted) {
        setState(() => error =
            'Could not search NearRide. Check your connection and try again.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Search vehicles')),
        bottomNavigationBar: NavigationBar(
          selectedIndex: 1,
          onDestinationSelected: (index) {
            if (index == 0) context.go('/');
            if (index == 1) return;
            if (index == 2) context.push('/favourites');
            if (index == 3) context.push('/profile');
          },
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
            NavigationDestination(
                icon: Icon(Icons.favorite_outline), label: 'Saved'),
            NavigationDestination(
                icon: Icon(Icons.person_outline), label: 'Account'),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => search(),
                decoration: InputDecoration(
                  hintText: 'Car, van, driver, manufacturer…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: search,
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ),
              ),
            ),
            if (loading) const LinearProgressIndicator(),
            Expanded(
              child: error != null
                  ? Center(
                      child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(error!)))
                  : !searched
                      ? const Center(
                          child: Text('Search all active NearRide listings.'))
                      : results.isEmpty
                          ? const Center(
                              child: Text('No matching listings found.'))
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: results.length,
                              itemBuilder: (_, index) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ListingCard(listing: results[index]),
                              ),
                            ),
            ),
          ],
        ),
      );
}
