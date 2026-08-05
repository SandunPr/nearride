class VehicleListing {
  const VehicleListing({
    required this.publicId,
    required this.title,
    required this.listingType,
    required this.providerName,
    required this.providerVerified,
    required this.availableNow,
    required this.phone,
    this.providerAvatarUrl,
    this.categoryName,
    this.description,
    this.manufacturer,
    this.model,
    this.passengerCapacity,
    this.loadCapacityKg,
    this.publicAreaName,
    this.distanceKm,
    this.whatsappNumber,
    this.thumbnailUrl,
    this.registrationNumber,
    this.hasAirConditioning = false,
    this.longDistanceAvailable = false,
    this.startingPrice,
    this.priceUnit,
    this.images = const [],
  });

  final String publicId;
  final String title;
  final String listingType;
  final String providerName;
  final String phone;
  final String? providerAvatarUrl;
  final String? categoryName;
  final String? description;
  final String? manufacturer;
  final String? model;
  final String? publicAreaName;
  final String? whatsappNumber;
  final String? thumbnailUrl;
  final String? registrationNumber;
  final bool providerVerified;
  final bool availableNow;
  final bool hasAirConditioning;
  final bool longDistanceAvailable;
  final int? passengerCapacity;
  final double? loadCapacityKg;
  final double? startingPrice;
  final String? priceUnit;
  final double? distanceKm;
  final List<String> images;

  factory VehicleListing.fromJson(Map<String, dynamic> json) {
    final imageItems = json['images'] as List? ?? const [];
    final images = imageItems
        .map((item) {
          if (item is String) return item;
          if (item is Map) return item['imageUrl'] as String?;
          return null;
        })
        .whereType<String>()
        .toList(growable: false);

    return VehicleListing(
      publicId: json['publicId'] ?? '',
      title: json['title'] ?? '',
      listingType: json['listingType'] ?? '',
      providerName: json['providerName'] ?? 'Independent provider',
      providerAvatarUrl: json['providerAvatarUrl'],
      providerVerified:
          json['providerVerified'] == true || json['providerVerified'] == 1,
      availableNow: json['availableNow'] == true || json['availableNow'] == 1,
      phone: json['phone'] ?? '',
      categoryName: json['categoryName'],
      description: json['description'],
      manufacturer: json['manufacturer'],
      model: json['model'],
      passengerCapacity: (json['passengerCapacity'] as num?)?.toInt(),
      loadCapacityKg: (json['loadCapacityKg'] as num?)?.toDouble(),
      publicAreaName: json['publicAreaName'],
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      whatsappNumber: json['whatsappNumber'],
      thumbnailUrl:
          json['thumbnailUrl'] ?? (images.isEmpty ? null : images.first),
      registrationNumber:
          json['registrationNumberMasked'] ?? json['registrationNumber'],
      hasAirConditioning: json['hasAirConditioning'] == true ||
          json['hasAirConditioning'] == 1,
      longDistanceAvailable: json['longDistanceAvailable'] == true ||
          json['longDistanceAvailable'] == 1,
      startingPrice: (json['startingPrice'] as num?)?.toDouble(),
      priceUnit: json['priceUnit'],
      images: images,
    );
  }

  String get distanceLabel => distanceKm == null
      ? 'Distance unavailable'
      : distanceKm! < 1
          ? '${(distanceKm! * 1000).round()} m away'
          : '${distanceKm!.toStringAsFixed(1)} km away';

  String get typeLabel => listingType
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');

  String? get vehicleLabel {
    final parts = [manufacturer, model]
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? categoryName : parts.join(' ');
  }

  String? get priceLabel {
    if (startingPrice == null) return null;
    final amount = startingPrice! % 1 == 0
        ? startingPrice!.toStringAsFixed(0)
        : startingPrice!.toStringAsFixed(2);
    const units = {
      'per_km': '/ km',
      'per_hour': '/ hour',
      'per_day': '/ day',
      'fixed': 'fixed',
      'negotiable': 'negotiable',
    };
    return 'LKR $amount ${units[priceUnit] ?? ''}'.trim();
  }
}
