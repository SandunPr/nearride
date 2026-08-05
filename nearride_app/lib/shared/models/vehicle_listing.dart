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
    this.manufacturedYear,
    this.passengerCapacity,
    this.loadCapacityKg,
    this.publicAreaName,
    this.distanceKm,
    this.whatsappNumber,
    this.thumbnailUrl,
    this.registrationNumber,
    this.hasAirConditioning = false,
    this.longDistanceAvailable = false,
    this.emergencyContactAvailable = false,
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
  final int? manufacturedYear;
  final String? publicAreaName;
  final String? whatsappNumber;
  final String? thumbnailUrl;
  final String? registrationNumber;
  final bool providerVerified;
  final bool availableNow;
  final bool hasAirConditioning;
  final bool longDistanceAvailable;
  final bool emergencyContactAvailable;
  final int? passengerCapacity;
  final double? loadCapacityKg;
  final double? startingPrice;
  final String? priceUnit;
  final double? distanceKm;
  final List<String> images;

  static double? _doubleValue(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static int? _intValue(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static bool _boolValue(dynamic value) =>
      value == true || value == 1 || value == '1' || value == 'true';

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
      providerVerified: _boolValue(json['providerVerified']),
      availableNow: _boolValue(json['availableNow']),
      phone: json['phone'] ?? '',
      categoryName: json['categoryName'],
      description: json['description'],
      manufacturer: json['manufacturer'],
      model: json['model'],
      manufacturedYear: _intValue(json['manufacturedYear']),
      passengerCapacity: _intValue(json['passengerCapacity']),
      loadCapacityKg: _doubleValue(json['loadCapacityKg']),
      publicAreaName: json['publicAreaName'],
      distanceKm: _doubleValue(json['distanceKm']),
      whatsappNumber: json['whatsappNumber'],
      thumbnailUrl:
          json['thumbnailUrl'] ?? (images.isEmpty ? null : images.first),
      registrationNumber:
          json['registrationNumberMasked'] ?? json['registrationNumber'],
      hasAirConditioning: _boolValue(json['hasAirConditioning']),
      longDistanceAvailable: _boolValue(json['longDistanceAvailable']),
      emergencyContactAvailable:
          _boolValue(json['emergencyContactAvailable']),
      startingPrice: _doubleValue(json['startingPrice']),
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
