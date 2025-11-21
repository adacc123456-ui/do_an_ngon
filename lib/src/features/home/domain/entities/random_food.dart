class RandomFood {
  final String id;
  final String name;
  final String imageUrl;
  final String description;
  final String restaurantName;
  final String restaurantAddress;
  final bool isFavorite;

  const RandomFood({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.restaurantName,
    required this.restaurantAddress,
    this.isFavorite = false,
  });
}

