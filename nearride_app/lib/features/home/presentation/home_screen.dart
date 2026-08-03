import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/location_service.dart';
import '../../../core/services/token_store.dart';
import '../../../shared/models/vehicle_listing.dart';
import '../../../shared/providers/providers.dart';
import '../../listings/presentation/listing_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<VehicleListing> items = const [];
  bool loading = true;
  String? message;
  double radius = 10;
  String? category;
  bool isProvider = false;
  bool providerAvailable = true;
  bool updatingAvailability = false;

  static const categories = <String, String>{
    'motorbike': 'Motorbike',
    'three-wheeler': 'Three Wheeler',
    'car': 'Car',
    'suv': 'SUV',
    'van': 'Van',
    'bus': 'Bus',
    'pickup': 'Pickup',
    'lorry': 'Lorry',
    'tow-vehicle': 'Tow Vehicle',
    'tractor': 'Tractor',
    'other': 'Other',
  };

  @override
  void initState() {
    super.initState();
    load();
    loadProviderAvailability();
  }

  Future<void> loadProviderAvailability() async {
    final token = await const TokenStore().access();
    if (token == null || token.isEmpty) return;
    try {
      final dio = ref.read(apiProvider).dio;
      final me = await dio.get('/auth/me');
      final provider = me.data['data']['isProvider'] == true ||
          me.data['data']['isProvider'] == 1;
      if (!provider) return;
      final response = await dio.get('/provider/availability');
      if (mounted) {
        setState(() {
          isProvider = true;
          providerAvailable = response.data['data']['isAvailable'] == true ||
              response.data['data']['isAvailable'] == 1;
        });
      }
    } catch (_) {
      // The normal feed remains usable if provider status cannot be loaded.
    }
  }

  Future<void> setProviderAvailability(bool value) async {
    setState(() => updatingAvailability = true);
    try {
      final response = await ref.read(apiProvider).dio.patch(
        '/provider/availability',
        data: {'isAvailable': value},
      );
      if (mounted) {
        setState(() => providerAvailable = value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.data['message'] as String)),
        );
        await load();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update availability. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => updatingAvailability = false);
    }
  }

  Future<void> load() async {
    if (mounted) {
      setState(() {
        loading = true;
        message = null;
      });
    }
    final location = await LocationService().current();
    final latitude = location.position?.latitude ?? 6.9271;
    final longitude = location.position?.longitude ?? 79.8612;
    if (location.position == null) {
      message = '${location.message} Showing results near Colombo.';
    }
    try {
      final result = await ref.read(listingRepositoryProvider).nearby(
            latitude: latitude,
            longitude: longitude,
            radius: radius,
            category: category,
          );
      if (mounted) setState(() => items = result);
    } catch (_) {
      if (mounted) {
        setState(() =>
            message = 'Could not reach the NearRide API. Pull down to retry.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NearRide', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Vehicles around you',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
              ]),
          actions: [
            if (isProvider)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    providerAvailable ? 'Available' : 'Busy',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Switch.adaptive(
                    value: providerAvailable,
                    onChanged:
                        updatingAvailability ? null : setProviderAvailability,
                  ),
                ],
              ),
            IconButton(
                onPressed: () => context.push('/profile'),
                icon: const Icon(Icons.person_outline))
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/provider'),
          icon: const Icon(Icons.add),
          label: const Text('List a vehicle'),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: 0,
          onDestinationSelected: (index) {
            if (index == 1) context.push('/search');
            if (index == 2) context.push('/favourites');
            if (index == 3) context.push('/profile');
          },
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home'),
            NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
            NavigationDestination(
                icon: Icon(Icons.favorite_outline), label: 'Saved'),
            NavigationDestination(
                icon: Icon(Icons.person_outline), label: 'Account'),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Find a vehicle nearby',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String?>(
                        initialValue: category,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle type',
                          prefixIcon: Icon(Icons.directions_car_outlined),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All vehicles'),
                          ),
                          ...categories.entries.map(
                            (entry) => DropdownMenuItem<String?>(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          ),
                        ],
                        onChanged: loading
                            ? null
                            : (value) => setState(() => category = value),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<double>(
                        initialValue: radius,
                        decoration: const InputDecoration(
                          labelText: 'Maximum distance',
                          prefixIcon: Icon(Icons.near_me_outlined),
                        ),
                        items: const [5, 10, 25, 50, 100]
                            .map(
                              (value) => DropdownMenuItem<double>(
                                value: value.toDouble(),
                                child: Text('$value km'),
                              ),
                            )
                            .toList(),
                        onChanged: loading
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => radius = value);
                                }
                              },
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: loading ? null : load,
                        icon: const Icon(Icons.search),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 13),
                          child: Text('Search'),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/search'),
                        child: const Text('Advanced keyword search'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (message != null)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(message!),
                ),
              Row(children: [
                Text('Nearby listings',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(onPressed: load, child: const Text('Refresh')),
              ]),
              if (loading)
                ...List.generate(
                    3,
                    (_) => const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: LinearProgressIndicator()))
              else if (items.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                        child: Text('No active listings found in this area.')))
              else
                ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ListingCard(listing: item))),
            ],
          ),
        ),
      );
}
