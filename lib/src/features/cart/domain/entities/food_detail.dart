class FoodDetail {
  final String id;
  final String name;
  final String imageUrl;
  final String description;
  final double price;
  final String restaurantName;
  final String restaurantAddress;
  final List<String>? ingredients;
  final double? rating;
  final int? reviewCount;

  const FoodDetail({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.price,
    required this.restaurantName,
    required this.restaurantAddress,
    this.ingredients,
    this.rating,
    this.reviewCount,
  });
}

