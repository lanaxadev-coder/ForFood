// ============================================================
// MENU EVENTS
// ============================================================
// Events dispatched to MenuBloc to manage menu items.
// ============================================================

import 'package:forfood/models/menu_item_model.dart';

/// Base class for all Menu events.
abstract class MenuEvent {
  const MenuEvent();
}

/// Fired to fetch menu items for a restaurant (stream).
class MenuEventFetchByRestaurant extends MenuEvent {
  /// The restaurant's Firestore document ID.
  final String restaurantId;

  const MenuEventFetchByRestaurant({required this.restaurantId});
}

/// Fired to add a new menu item.
class MenuEventAddItem extends MenuEvent {
  /// The menu item to add.
  final MenuItemModel menuItem;

  const MenuEventAddItem({required this.menuItem});
}

/// Fired to update an existing menu item.
class MenuEventUpdateItem extends MenuEvent {
  /// The updated menu item.
  final MenuItemModel menuItem;

  const MenuEventUpdateItem({required this.menuItem});
}

/// Fired to delete a menu item.
class MenuEventDeleteItem extends MenuEvent {
  /// The restaurant ID.
  final String restaurantId;

  /// The menu item ID to delete.
  final String menuItemId;

  const MenuEventDeleteItem({
    required this.restaurantId,
    required this.menuItemId,
  });
}

/// Internal: stream emitted new menu items.
class MenuEventStreamUpdated extends MenuEvent {
  final List<MenuItemModel> menuItems;

  const MenuEventStreamUpdated({required this.menuItems});
}

/// Internal: stream failed.
class MenuEventStreamError extends MenuEvent {
  final String message;

  const MenuEventStreamError({required this.message});
}

/// Internal: safety timeout fired, no data received.
class MenuEventTimeout extends MenuEvent {
  const MenuEventTimeout();
}

