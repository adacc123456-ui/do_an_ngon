import 'package:equatable/equatable.dart';
import 'package:do_an_ngon/src/features/home/domain/entities/food.dart';

class FavoritesState extends Equatable {
  final List<Food> favorites;
  final bool isLoading;

  const FavoritesState({
    required this.favorites,
    this.isLoading = false,
  });

  FavoritesState copyWith({
    List<Food>? favorites,
    bool? isLoading,
  }) {
    return FavoritesState(
      favorites: favorites ?? this.favorites,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool isFavorite(String foodId) {
    return favorites.any((food) => food.id == foodId);
  }

  @override
  List<Object?> get props => [favorites, isLoading];
}

