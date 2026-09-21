// ============================================================
// MENU BLOC — SAME PATTERN AS NOTIFICATIONBLOC
// ============================================================

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:forfood/models/menu_item_model.dart';
import 'package:forfood/service/database/firestore_provider.dart';
import 'package:forfood/service/exceptions/domain_exceptions.dart';
import 'package:forfood/service/menu/menu_event.dart';
import 'package:forfood/service/menu/menu_state.dart';

class MenuBloc extends Bloc<MenuEvent, MenuState> {
  final FirestoreProvider _firestoreProvider;
  StreamSubscription<List<MenuItemModel>>? _menuSubscription;
  Timer? _timeoutTimer;

  MenuBloc(FirestoreProvider firestoreProvider)
      : _firestoreProvider = firestoreProvider,
        super(const MenuStateInitial()) {
    on<MenuEventFetchByRestaurant>(_onFetchByRestaurant);
    on<MenuEventStreamUpdated>(_onStreamUpdated);
    on<MenuEventStreamError>(_onStreamError);
    on<MenuEventTimeout>(_onTimeout);
    on<MenuEventAddItem>(_onAddItem);
    on<MenuEventUpdateItem>(_onUpdateItem);
    on<MenuEventDeleteItem>(_onDeleteItem);
  }

  // ============================================================
  // FETCH — just starts stream + timer, no emit in callbacks
  // ============================================================

  Future<void> _onFetchByRestaurant(
    MenuEventFetchByRestaurant event,
    Emitter<MenuState> emit,
  ) async {
    emit(const MenuStateLoading());

    await _menuSubscription?.cancel();
    _timeoutTimer?.cancel();

    // Safety timeout — dispatches internal event if stream is slow
    _timeoutTimer = Timer(const Duration(seconds: 3), () {
      if (!isClosed) {
        add(const MenuEventTimeout());
      }
    });

    _menuSubscription = _firestoreProvider
        .streamMenuItemsByRestaurantId(event.restaurantId)
        .listen(
      (menuItems) {
        _timeoutTimer?.cancel();
        if (!isClosed) {
          add(MenuEventStreamUpdated(menuItems: menuItems));
        }
      },
      onError: (error) {
        _timeoutTimer?.cancel();
        if (!isClosed) {
          add(MenuEventStreamError(message: error.toString()));
        }
      },
      onDone: () {
        _timeoutTimer?.cancel();
        if (!isClosed && state is MenuStateLoading) {
          add(const MenuEventStreamUpdated(menuItems: []));
        }
      },
    );
  }

  // ============================================================
  // INTERNAL HANDLERS — emit allowed here
  // ============================================================

  void _onStreamUpdated(
    MenuEventStreamUpdated event,
    Emitter<MenuState> emit,
  ) {
    emit(MenuStateLoaded(menuItems: event.menuItems));
  }

  void _onStreamError(
    MenuEventStreamError event,
    Emitter<MenuState> emit,
  ) {
    emit(MenuStateError(message: event.message));
  }

  void _onTimeout(
    MenuEventTimeout event,
    Emitter<MenuState> emit,
  ) {
    // Only if still loading
    if (state is MenuStateLoading) {
      emit(const MenuStateLoaded(menuItems: []));
    }
  }

  // ============================================================
  // ADD / UPDATE / DELETE (unchanged)
  // ============================================================

  Future<void> _onAddItem(
    MenuEventAddItem event,
    Emitter<MenuState> emit,
  ) async {
    try {
      await _firestoreProvider.createMenuItem(event.menuItem);
    } on FirestoreOperationException catch (e) {
      emit(MenuStateError(message: e.message));
    } catch (e) {
      emit(MenuStateError(message: 'Failed to add menu item: $e'));
    }
  }

  Future<void> _onUpdateItem(
    MenuEventUpdateItem event,
    Emitter<MenuState> emit,
  ) async {
    try {
      await _firestoreProvider.updateMenuItem(event.menuItem);
    } on FirestoreOperationException catch (e) {
      emit(MenuStateError(message: e.message));
    } catch (e) {
      emit(MenuStateError(message: 'Failed to update menu item: $e'));
    }
  }

  Future<void> _onDeleteItem(
    MenuEventDeleteItem event,
    Emitter<MenuState> emit,
  ) async {
    try {
      await _firestoreProvider.deleteMenuItem(
        restaurantId: event.restaurantId,
        menuItemId: event.menuItemId,
      );
    } on FirestoreOperationException catch (e) {
      emit(MenuStateError(message: e.message));
    } catch (e) {
      emit(MenuStateError(message: 'Failed to delete menu item: $e'));
    }
  }

  @override
  Future<void> close() {
    _menuSubscription?.cancel();
    _timeoutTimer?.cancel();
    return super.close();
  }
}