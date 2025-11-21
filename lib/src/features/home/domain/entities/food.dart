class FoodRating {
  final double average;
  final int totalReviews;

  const FoodRating({
    required this.average,
    required this.totalReviews,
  });
}

class RestaurantInfo {
  final String id;
  final String name;
  final String? address;
  final FoodRating? rating;

  const RestaurantInfo({
    required this.id,
    required this.name,
    this.address,
    this.rating,
  });
}

class Food {
  final String id;
  final String name;
  final String imageUrl;
  final String restaurantName;
  final String restaurantAddress;
  final String? restaurantId;
  final double? price;
  final FoodRating? rating; // Rating for the food item
  final RestaurantInfo? restaurant; // Restaurant info with rating

  const Food({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.restaurantName,
    required this.restaurantAddress,
    this.restaurantId,
    this.price,
    this.rating,
    this.restaurant,
  });

  double get averageRating => rating?.average ?? 0.0;
  int get totalReviews => rating?.totalReviews ?? 0;
  double get restaurantAverageRating => restaurant?.rating?.average ?? 0.0;
  int get restaurantTotalReviews => restaurant?.rating?.totalReviews ?? 0;
}

