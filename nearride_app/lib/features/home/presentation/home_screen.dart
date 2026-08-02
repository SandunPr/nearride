import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/location_service.dart';
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
  double radius = 25;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() { loading = true; message = null; });
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
          );
      if (mounted) setState(() => items = result);
    } catch (_) {
      if (mounted) setState(() => message = 'Could not reach the NearRide API. Pull down to retry.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('NearRide', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Vehicles around you', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ]),
          actions: [IconButton(onPressed: () => context.push('/profile'), icon: const Icon(Icons.person_outline))],
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
            if (index == 3) context.push('/profile');
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
            NavigationDestination(icon: Icon(Icons.favorite_outline), label: 'Saved'),
            NavigationDestination(icon: Icon(Icons.person_outline), label: 'Account'),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              TextField(
                readOnly: true,
                onTap: () => context.push('/search'),
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'What vehicle do you need?'),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Text('Maximum distance', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                DropdownButton<double>(
                  value: radius,
                  items: [5, 10, 25, 50, 100].map((value) => DropdownMenuItem(value: value.toDouble(), child: Text('$value km'))).toList(),
                  onChanged: (value) { if (value != null) { radius = value; load(); } },
                ),
              ]),
              if (message != null)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(12)),
                  child: Text(message!),
                ),
              Row(children: [
                Text('Nearby listings', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(onPressed: load, child: const Text('Refresh')),
              ]),
              if (loading)
                ...List.generate(3, (_) => const Padding(padding: EdgeInsets.only(bottom: 12), child: LinearProgressIndicator()))
              else if (items.isEmpty)
                const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No active listings found in this area.')))
              else
                ...items.map((item) => Padding(padding: const EdgeInsets.only(bottom: 12), child: ListingCard(listing: item))),
            ],
          ),
        ),
      );
}
