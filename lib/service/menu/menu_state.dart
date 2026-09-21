// ============================================================
// MENU STATES
// ============================================================
// States emitted by MenuBloc in response to MenuEvents.
// ============================================================

import 'package:forfood/models/menu_item_model.dart';

/// Base class for all Menu states.
abstract class MenuState {
  const MenuState();
}

/// Initial state — no menu items loaded.
class MenuStateInitial extends MenuState {
  const MenuStateInitial();
}

/// Loading state — fetching menu items.
class MenuStateLoading extends MenuState {
  const MenuStateLoading();
}

/// Loaded state — menu items fetched.
class MenuStateLoaded extends MenuState {
  /// List of menu items for the restaurant.
  final List<MenuItemModel> menuItems;

  const MenuStateLoaded({required this.menuItems});

  /// Number of menu items.
  int get itemCount => menuItems.length;
}

/// Error state — menu operation failed.
class MenuStateError extends MenuState {
  final String message;

  const MenuStateError({required this.message});
}