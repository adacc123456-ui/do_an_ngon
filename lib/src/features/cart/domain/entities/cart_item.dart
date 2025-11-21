import 'package:do_an_ngon/src/features/home/domain/entities/food.dart';

class CartItem {
  final String id;
  final Food food;
  final int quantity;
  final double price;
  final String? restaurantId;

  const CartItem({
    required this.id,
    required this.food,
    required this.quantity,
    required this.price,
    this.restaurantId,
  });

  CartItem copyWith({
    String? id,
    Food? food,
    int? quantity,
    double? price,
    String? restaurantId,
  }) {
    return CartItem(
      id: id ?? this.id,
      food: food ?? this.food,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      restaurantId: restaurantId ?? this.restaurantId,
    );
  }

  double get totalPrice => price * quantity;
}

