import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/vehicle_listing.dart';
import '../../../shared/providers/providers.dart';
import '../../listings/presentation/listing_card.dart';

class FavouritesScreen extends ConsumerStatefulWidget {
  const FavouritesScreen({super.key});

  @override
  ConsumerState<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends ConsumerState<FavouritesScreen> {
  List<VehicleListing> items = const [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }
    try {
      final result = await ref.read(listingRepositoryProvider).favourites();
      if (mounted) setState(() => items = result);
    } on DioException catch (exception) {
      if (exception.response?.statusCode == 401) {
        if (mounted) context.go('/login?redirect=%2Ffavourites');
        return;
      }
      if (mounted) setState(() => error = 'Could not load your favourites.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void remove(VehicleListing listing) {
    setState(() => items = items
        .where((item) => item.publicId != listing.publicId)
        .toList(growable: false));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Saved listings')),
        bottomNavigationBar: NavigationBar(
          selectedIndex: 2,
          onDestinationSelected: (index) {
            if (index == 0) context.go('/');
            if (index == 1) context.go('/search');
            if (index == 3) context.push('/profile');
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
            NavigationDestination(
              icon: Icon(Icons.favorite),
              label: 'Saved',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              label: 'Account',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (loading)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (error != null)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(child: Text(error!)),
                )
              else if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: Column(
                    children: [
                      Icon(Icons.favorite_border, size: 56),
                      SizedBox(height: 12),
                      Text('You have no saved listings yet.'),
                    ],
                  ),
                )
              else
                ...items.map(
                  (listing) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ListingCard(
                      listing: listing,
                      initiallySaved: true,
                      onRemoved: () => remove(listing),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
}
