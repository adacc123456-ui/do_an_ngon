import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:do_an_ngon/src/core/services/local_storage_service.dart';
import 'package:do_an_ngon/src/features/cart/presentation/bloc/cart_event.dart';
import 'package:do_an_ngon/src/features/cart/presentation/bloc/cart_state.dart';
import 'package:do_an_ngon/src/features/cart/domain/entities/cart_item.dart';
import 'package:do_an_ngon/src/features/home/domain/entities/food.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final LocalStorageService _localStorageService;

  CartBloc({LocalStorageService? localStorageService})
      : _localStorageService = localStorageService ?? LocalStorageService(),
        super(const CartState(items: [])) {
    on<LoadCartEvent>(_onLoadCart);
    on<AddToCartEvent>(_onAddToCart);
    on<RemoveFromCartEvent>(_onRemoveFromCart);
    on<UpdateCartItemQuantityEvent>(_onUpdateCartItemQuantity);
    on<ClearCartEvent>(_onClearCart);

    // Load cart from storage on initialization
    add(const LoadCartEvent());
  }

  Future<void> _onLoadCart(LoadCartEvent event, Emitter<CartState> emit) async {
    try {
      final cartJson = await _localStorageService.getCart();
      if (cartJson != null && cartJson.isNotEmpty) {
        final List<dynamic> decoded = json.decode(cartJson);
        final items = decoded.map((item) => _cartItemFromJson(item)).toList();
        emit(state.copyWith(items: items));
      }
    } catch (e) {
      // If error loading, start with empty cart
      emit(state);
    }
  }

  Future<void> _onAddToCart(AddToCartEvent event, Emitter<CartState> emit) async {
    final existingItemIndex = state.items.indexWhere(
      (item) => item.food.id == event.food.id,
    );

    List<CartItem> updatedItems;

    if (existingItemIndex >= 0) {
      // Update quantity if item already exists
      final existingItem = state.items[existingItemIndex];
      updatedItems = List.from(state.items);
      updatedItems[existingItemIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + event.quantity,
      );
    } else {
      // Add new item
      final newItem = CartItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        food: event.food,
        quantity: event.quantity,
        price: event.price,
        restaurantId: event.food.restaurantId,
      );
      updatedItems = [...state.items, newItem];
    }

    emit(state.copyWith(items: updatedItems));
    await _saveCartToStorage(updatedItems);
  }

  Future<void> _onRemoveFromCart(RemoveFromCartEvent event, Emitter<CartState> emit) async {
    final updatedItems = state.items.where(
      (item) => item.id != event.cartItemId,
    ).toList();

    emit(state.copyWith(items: updatedItems));
    await _saveCartToStorage(updatedItems);
  }

  Future<void> _onUpdateCartItemQuantity(
    UpdateCartItemQuantityEvent event,
    Emitter<CartState> emit,
  ) async {
    if (event.quantity <= 0) {
      add(RemoveFromCartEvent(cartItemId: event.cartItemId));
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.id == event.cartItemId) {
        return item.copyWith(quantity: event.quantity);
      }
      return item;
    }).toList();

    emit(state.copyWith(items: updatedItems));
    await _saveCartToStorage(updatedItems);
  }

  Future<void> _onClearCart(ClearCartEvent event, Emitter<CartState> emit) async {
    emit(const CartState(items: []));
    await _localStorageService.clearCart();
  }

  Future<void> _saveCartToStorage(List<CartItem> items) async {
    try {
      final cartJson = json.encode(items.map((item) => _cartItemToJson(item)).toList());
      await _localStorageService.saveCart(cartJson);
    } catch (e) {
      // Silently fail - cart will still work in memory
    }
  }

  Map<String, dynamic> _cartItemToJson(CartItem item) {
    return {
      'id': item.id,
      'restaurantId': item.restaurantId ?? item.food.restaurantId,
      'food': {
        'id': item.food.id,
        'name': item.food.name,
        'imageUrl': item.food.imageUrl,
        'restaurantName': item.food.restaurantName,
        'restaurantAddress': item.food.restaurantAddress,
        if (item.food.restaurantId != null) 'restaurantId': item.food.restaurantId,
        if (item.food.price != null) 'price': item.food.price,
      },
      'quantity': item.quantity,
      'price': item.price,
    };
  }

  CartItem _cartItemFromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      food: Food(
        id: json['food']['id'] as String,
        name: json['food']['name'] as String,
        imageUrl: json['food']['imageUrl'] as String,
        restaurantName: json['food']['restaurantName'] as String,
        restaurantAddress: json['food']['restaurantAddress'] as String,
        restaurantId: json['food']['restaurantId'] as String?,
        price: (json['food']['price'] as num?)?.toDouble(),
      ),
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      restaurantId: (json['restaurantId'] ?? json['food']['restaurantId']) as String?,
    );
  }
}

