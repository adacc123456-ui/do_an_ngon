import 'package:equatable/equatable.dart';
import 'package:do_an_ngon/src/features/home/domain/entities/food.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class AddToCartEvent extends CartEvent {
  final Food food;
  final int quantity;
  final double price;

  const AddToCartEvent({
    required this.food,
    required this.quantity,
    required this.price,
  });

  @override
  List<Object?> get props => [food, quantity, price];
}

class RemoveFromCartEvent extends CartEvent {
  final String cartItemId;

  const RemoveFromCartEvent({required this.cartItemId});

  @override
  List<Object?> get props => [cartItemId];
}

class UpdateCartItemQuantityEvent extends CartEvent {
  final String cartItemId;
  final int quantity;

  const UpdateCartItemQuantityEvent({
    required this.cartItemId,
    required this.quantity,
  });

  @override
  List<Object?> get props => [cartItemId, quantity];
}

class ClearCartEvent extends CartEvent {
  const ClearCartEvent();
}

class LoadCartEvent extends CartEvent {
  const LoadCartEvent();
}

