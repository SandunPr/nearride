import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/models/vehicle_listing.dart';

class ListingRepository {
  ListingRepository(this.api);

  final ApiClient api;

  List<VehicleListing> _list(dynamic response) =>
      (response.data['data'] as List)
          .map((item) => VehicleListing.fromJson(item as Map<String, dynamic>))
          .toList();

  Future<List<VehicleListing>> nearby({
    required double latitude,
    required double longitude,
    double radius = 25,
    String? category,
    String? type,
    bool available = false,
  }) async {
    final response = await api.dio.get(
      '/listings/nearby',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radiusKm': radius,
        if (category != null) 'category': category,
        if (type != null) 'listingType': type,
        if (available) 'availableNow': 'true',
      },
    );
    return _list(response);
  }

  Future<List<VehicleListing>> search({
    String? query,
    String? category,
    String? listingType,
    bool availableNow = false,
  }) async {
    final response = await api.dio.get(
      '/listings/search',
      queryParameters: {
        if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
        if (category != null) 'category': category,
        if (listingType != null) 'listingType': listingType,
        if (availableNow) 'availableNow': 'true',
      },
    );
    return _list(response);
  }

  Future<VehicleListing> detail(String id) async => VehicleListing.fromJson(
        (await api.dio.get('/listings/$id')).data['data'],
      );

  Future<List<VehicleListing>> favourites() async =>
      _list(await api.dio.get('/favourites'));

  Future<void> saveFavourite(String id) async {
    await api.dio.post('/favourites/$id');
  }

  Future<void> removeFavourite(String id) async {
    await api.dio.delete('/favourites/$id');
  }

  Future<void> event(String id, String type) async {
    try {
      await api.dio.post(
        '/listings/$id/events',
        data: {'eventType': type},
      );
    } on DioException {
      // Contact actions must not be blocked by analytics.
    }
  }
}
