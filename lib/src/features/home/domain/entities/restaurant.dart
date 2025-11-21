class RestaurantRating {
  final double average;
  final int totalReviews;

  const RestaurantRating({
    required this.average,
    required this.totalReviews,
  });
}

class Restaurant {
  final String id;
  final String name;
  final String imageUrl;
  final String address;
  final String? slug;
  final String? phone;
  final double? rating; // Legacy field for backward compatibility
  final RestaurantRating? ratingInfo; // New rating object
  final bool? isAcceptingOrders;

  const Restaurant({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.address,
    this.slug,
    this.phone,
    this.rating,
    this.ratingInfo,
    this.isAcceptingOrders,
  });

  double get averageRating => ratingInfo?.average ?? rating ?? 0.0;
  int get totalReviews => ratingInfo?.totalReviews ?? 0;
}

