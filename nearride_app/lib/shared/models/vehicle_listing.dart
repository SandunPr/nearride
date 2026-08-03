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
    this.passengerCapacity,
    this.publicAreaName,
    this.distanceKm,
    this.whatsappNumber,
    this.thumbnailUrl,
    this.registrationNumber,
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
  final String? publicAreaName;
  final String? whatsappNumber;
  final String? thumbnailUrl;
  final String? registrationNumber;
  final bool providerVerified;
  final bool availableNow;
  final int? passengerCapacity;
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
      passengerCapacity: (json['passengerCapacity'] as num?)?.toInt(),
      publicAreaName: json['publicAreaName'],
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      whatsappNumber: json['whatsappNumber'],
      thumbnailUrl:
          json['thumbnailUrl'] ?? (images.isEmpty ? null : images.first),
      registrationNumber:
          json['registrationNumberMasked'] ?? json['registrationNumber'],
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
}
