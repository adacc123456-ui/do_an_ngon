import 'package:equatable/equatable.dart';
import 'package:do_an_ngon/src/features/cart/domain/entities/cart_item.dart';

class CartState extends Equatable {
  final List<CartItem> items;
  final bool isLoading;

  const CartState({
    required this.items,
    this.isLoading = false,
  });

  CartState copyWith({
    List<CartItem>? items,
    bool? isLoading,
  }) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  // Tính theo số sản phẩm khác nhau, không phải tổng số lượng
  int get totalItems => items.length;

  double get totalPrice => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  @override
  List<Object?> get props => [items, isLoading];
}

