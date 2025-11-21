import 'package:equatable/equatable.dart';
import 'package:do_an_ngon/src/features/home/domain/entities/food.dart';

abstract class FavoritesEvent extends Equatable {
  const FavoritesEvent();

  @override
  List<Object?> get props => [];
}

class LoadFavoritesEvent extends FavoritesEvent {
  const LoadFavoritesEvent();
}

class AddToFavoritesEvent extends FavoritesEvent {
  final Food food;

  const AddToFavoritesEvent({required this.food});

  @override
  List<Object?> get props => [food];
}

class RemoveFromFavoritesEvent extends FavoritesEvent {
  final String foodId;

  const RemoveFromFavoritesEvent({required this.foodId});

  @override
  List<Object?> get props => [foodId];
}

class ToggleFavoriteEvent extends FavoritesEvent {
  final Food food;

  const ToggleFavoriteEvent({required this.food});

  @override
  List<Object?> get props => [food];
}

