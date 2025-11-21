import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:do_an_ngon/src/core/services/local_storage_service.dart';
import 'package:do_an_ngon/src/features/favorites/presentation/bloc/favorites_event.dart';
import 'package:do_an_ngon/src/features/favorites/presentation/bloc/favorites_state.dart';
import 'package:do_an_ngon/src/features/home/domain/entities/food.dart';

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final LocalStorageService _localStorageService;

  FavoritesBloc({LocalStorageService? localStorageService})
      : _localStorageService = localStorageService ?? LocalStorageService(),
        super(const FavoritesState(favorites: [])) {
    on<LoadFavoritesEvent>(_onLoadFavorites);
    on<AddToFavoritesEvent>(_onAddToFavorites);
    on<RemoveFromFavoritesEvent>(_onRemoveFromFavorites);
    on<ToggleFavoriteEvent>(_onToggleFavorite);

    // Load favorites on initialization
    add(const LoadFavoritesEvent());
  }

  Future<void> _onLoadFavorites(
    LoadFavoritesEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final favoritesJson = await _localStorageService.getFavorites();
      if (favoritesJson != null && favoritesJson.isNotEmpty) {
        final List<dynamic> decoded = json.decode(favoritesJson);
        final favorites = decoded.map((item) => _foodFromJson(item)).toList();
        emit(state.copyWith(favorites: favorites, isLoading: false));
      } else {
        emit(state.copyWith(isLoading: false));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onAddToFavorites(
    AddToFavoritesEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    if (state.favorites.any((food) => food.id == event.food.id)) {
      return; // Already in favorites
    }

    final updatedFavorites = [...state.favorites, event.food];
    emit(state.copyWith(favorites: updatedFavorites));
    await _saveFavoritesToStorage(updatedFavorites);
  }

  Future<void> _onRemoveFromFavorites(
    RemoveFromFavoritesEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    final updatedFavorites = state.favorites
        .where((food) => food.id != event.foodId)
        .toList();
    emit(state.copyWith(favorites: updatedFavorites));
    await _saveFavoritesToStorage(updatedFavorites);
  }

  Future<void> _onToggleFavorite(
    ToggleFavoriteEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    if (state.isFavorite(event.food.id)) {
      add(RemoveFromFavoritesEvent(foodId: event.food.id));
    } else {
      add(AddToFavoritesEvent(food: event.food));
    }
  }

  Future<void> _saveFavoritesToStorage(List<Food> favorites) async {
    try {
      final favoritesJson =
          json.encode(favorites.map((item) => _foodToJson(item)).toList());
      await _localStorageService.saveFavorites(favoritesJson);
    } catch (e) {
      // Silently fail - favorites will still work in memory
    }
  }

  Map<String, dynamic> _foodToJson(Food food) {
    return {
      'id': food.id,
      'name': food.name,
      'imageUrl': food.imageUrl,
      'restaurantId': food.restaurantId,
      'restaurantName': food.restaurantName,
      'restaurantAddress': food.restaurantAddress,
      'price': food.price,
    };
  }

  Food _foodFromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
      restaurantName: json['restaurantName'] as String,
      restaurantAddress: json['restaurantAddress'] as String,
      restaurantId: json['restaurantId'] as String?,
      price: (json['price'] as num?)?.toDouble(),
    );
  }
}

