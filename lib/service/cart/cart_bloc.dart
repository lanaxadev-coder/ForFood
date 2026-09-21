// ============================================================
// CART BLOC — FULL CORRECTED VERSION
// ============================================================
// State management for the shopping cart.
//
// Enforces the single-restaurant rule.
// Preserves original timestamps when quantity changes.
// ============================================================
// ============================================================
// CART BLOC — single-restaurant rule, self-recovering state machine
// ============================================================

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:forfood/models/order_model.dart';
import 'package:forfood/service/cart/cart_event.dart';
import 'package:forfood/service/cart/cart_state.dart';
import 'package:forfood/service/exceptions/domain_exceptions.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartStateEmpty()) {
    on<CartEventAddItem>(_onAddItem);
    on<CartEventRemoveItem>(_onRemoveItem);
    on<CartEventIncrementQuantity>(_onIncrementQuantity);
    on<CartEventDecrementQuantity>(_onDecrementQuantity);
    on<CartEventClear>(_onClear);
  }

  // ============================================================
  // ADD ITEM
  // ============================================================
  // Treat Error like Empty — a clean slate. This is the fix for
  // the "cart gets stuck after multi-restaurant error" bug.
  // ============================================================
  void _onAddItem(CartEventAddItem event, Emitter<CartState> emit) {
    final currentState = state;

    // ── Fresh cart: Empty OR recovering from Error ──
    if (currentState is CartStateEmpty || currentState is CartStateError) {
      final newItem = OrderItem(
        menuItemId: event.item.menuItemId,
        name: event.item.name,
        price: event.item.price,
        quantity: 1,
        imageUrl: event.item.imageUrl,
        dateTime: DateTime.now(),
      );

      emit(CartStateLoaded(
        items: [newItem],
        restaurantId: event.restaurantId,
        restaurantName: event.restaurantName,
        total: _calculateTotal([newItem]),
      ));
      return;
    }

    // ── Loaded cart ──
    if (currentState is CartStateLoaded) {
      // Single-restaurant rule
      if (currentState.restaurantId != event.restaurantId) {
        emit(CartStateError(
          message: const MultiRestaurantCartException().message,
        ));
        return;
      }

      final existingIndex = currentState.items.indexWhere(
        (item) => item.menuItemId == event.item.menuItemId,
      );

      if (existingIndex != -1) {
        final updatedItems = List<OrderItem>.from(currentState.items);
        updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
          quantity: updatedItems[existingIndex].quantity + 1,
        );
        emit(currentState.copyWith(
          items: updatedItems,
          total: _calculateTotal(updatedItems),
        ));
        return;
      }

      final newItem = OrderItem(
        menuItemId: event.item.menuItemId,
        name: event.item.name,
        price: event.item.price,
        quantity: 1,
        imageUrl: event.item.imageUrl,
        dateTime: DateTime.now(),
      );
      final updatedItems = [...currentState.items, newItem];
      emit(currentState.copyWith(
        items: updatedItems,
        total: _calculateTotal(updatedItems),
      ));
    }
  }

  // ============================================================
  // REMOVE ITEM
  // ============================================================
  void _onRemoveItem(CartEventRemoveItem event, Emitter<CartState> emit) {
    final currentState = state;
    if (currentState is! CartStateLoaded) return;

    final updatedItems = currentState.items
        .where((item) => item.menuItemId != event.menuItemId)
        .toList();

    if (updatedItems.isEmpty) {
      emit(const CartStateEmpty());
      return;
    }

    emit(currentState.copyWith(
      items: updatedItems,
      total: _calculateTotal(updatedItems),
    ));
  }

  // ============================================================
  // INCREMENT
  // ============================================================
  void _onIncrementQuantity(
    CartEventIncrementQuantity event,
    Emitter<CartState> emit,
  ) {
    final currentState = state;
    if (currentState is! CartStateLoaded) return;

    final updatedItems = currentState.items.map((item) {
      if (item.menuItemId == event.menuItemId) {
        return item.copyWith(quantity: item.quantity + 1);
      }
      return item;
    }).toList();

    emit(currentState.copyWith(
      items: updatedItems,
      total: _calculateTotal(updatedItems),
    ));
  }

  // ============================================================
  // DECREMENT (removes item when quantity hits 0)
  // ============================================================
  void _onDecrementQuantity(
    CartEventDecrementQuantity event,
    Emitter<CartState> emit,
  ) {
    final currentState = state;
    if (currentState is! CartStateLoaded) return;

    final updatedItems = currentState.items.map((item) {
      if (item.menuItemId == event.menuItemId) {
        if (item.quantity > 1) {
          return item.copyWith(quantity: item.quantity - 1);
        }
        return null; // signal removal
      }
      return item;
    }).whereType<OrderItem>().toList();

    if (updatedItems.isEmpty) {
      emit(const CartStateEmpty());
      return;
    }

    emit(currentState.copyWith(
      items: updatedItems,
      total: _calculateTotal(updatedItems),
    ));
  }

  // ============================================================
  // CLEAR
  // ============================================================
  void _onClear(CartEventClear event, Emitter<CartState> emit) {
    emit(const CartStateEmpty());
  }

  double _calculateTotal(List<OrderItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.subtotal);
  }
}