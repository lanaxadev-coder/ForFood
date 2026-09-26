// ============================================================
// RESTAURANT BLOC — WITH SAFETY TIMEOUT
// ============================================================

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:forfood/models/restaurant_model.dart';
import 'package:forfood/service/database/firestore_provider.dart';
import 'package:forfood/service/exceptions/domain_exceptions.dart';
import 'package:forfood/service/restaurant/restaurant_event.dart';
import 'package:forfood/service/restaurant/restaurant_state.dart';
import 'package:forfood/utilities/friendly_error.dart';

class RestaurantBloc extends Bloc<RestaurantEvent, RestaurantState> {
  final FirestoreProvider _firestoreProvider;
  StreamSubscription<RestaurantModel?>? _restaurantSubscription;
  Timer? _timeoutTimer;

  RestaurantBloc(FirestoreProvider firestoreProvider)
      : _firestoreProvider = firestoreProvider,
        super(const RestaurantStateInitial()) {
    on<RestaurantEventFetchByOwnerId>(_onFetchByOwnerId);
    on<RestaurantEventFetchById>(_onFetchById);
    on<RestaurantEventUpdateDeliveryStatus>(_onUpdateDeliveryStatus);

    on<RestaurantEventStreamUpdated>(_onStreamUpdated);
on<RestaurantEventStreamError>(_onStreamError);
on<RestaurantEventTimeout>(_onTimeout);
  }
Future<void> _onFetchByOwnerId(
  RestaurantEventFetchByOwnerId event,
  Emitter<RestaurantState> emit,
) async {
  emit(const RestaurantStateLoading());

  _timeoutTimer?.cancel();
  _timeoutTimer = Timer(const Duration(seconds: 3), () {
    if (!isClosed) add(const RestaurantEventTimeout());
  });

  try {
    final restaurant =
        await _firestoreProvider.getRestaurantByOwnerId(event.ownerId);

    if (restaurant == null) {
      _timeoutTimer?.cancel();
      emit(const RestaurantStateError(
        message: 'No restaurant found for this account',
      ));
      return;
    }

    _timeoutTimer?.cancel();
    emit(RestaurantStateLoaded(restaurant: restaurant));

    await _restaurantSubscription?.cancel();
    _restaurantSubscription = _firestoreProvider
        .streamRestaurantById(restaurant.id)
        .listen(
      (updated) {
        _timeoutTimer?.cancel();
        if (!isClosed && updated != null) {
          add(RestaurantEventStreamUpdated(restaurant: updated));
        }
      },
      onError: (error) {
        _timeoutTimer?.cancel();
        if (!isClosed) {
          add(RestaurantEventStreamError(message: error.toString()));
        }
      },
    );
  } on RestaurantNotFoundException catch (e) {
    _timeoutTimer?.cancel();
    emit(RestaurantStateError(message: e.message));
  } on FirestoreOperationException catch (e) {
    _timeoutTimer?.cancel();
    emit(RestaurantStateError(message: e.message));
  } catch (e) {
    _timeoutTimer?.cancel();
    emit(RestaurantStateError(message: 'Failed to fetch restaurant: $e'));
  }
}Future<void> _onFetchById(
  RestaurantEventFetchById event,
  Emitter<RestaurantState> emit,
) async {
  emit(const RestaurantStateLoading());

  _timeoutTimer?.cancel();
  _timeoutTimer = Timer(const Duration(seconds: 3), () {
    if (!isClosed) add(const RestaurantEventTimeout());
  });

  try {
    final restaurant =
        await _firestoreProvider.getRestaurantById(event.restaurantId);

    _timeoutTimer?.cancel();
    emit(RestaurantStateLoaded(restaurant: restaurant));

    await _restaurantSubscription?.cancel();
    _restaurantSubscription = _firestoreProvider
        .streamRestaurantById(event.restaurantId)
        .listen(
      (updated) {
        _timeoutTimer?.cancel();
        if (!isClosed && updated != null) {
          add(RestaurantEventStreamUpdated(restaurant: updated));
        }
      },
      onError: (error) {
        _timeoutTimer?.cancel();
        if (!isClosed) {
          add(RestaurantEventStreamError(message: error.toString()));
        }
      },
    );
  } on RestaurantNotFoundException catch (e) {
    _timeoutTimer?.cancel();
    emit(RestaurantStateError(message: friendlyError(e)));
  } on FirestoreOperationException catch (e) {
    _timeoutTimer?.cancel();
    emit(RestaurantStateError(message: friendlyError(e)));
  } catch (e) {
    _timeoutTimer?.cancel();
    emit(RestaurantStateError(message: 'Failed to fetch restaurant: $e'));
  }
}
  Future<void> _onUpdateDeliveryStatus(
    RestaurantEventUpdateDeliveryStatus event,
    Emitter<RestaurantState> emit,
  ) async {
    final currentState = state;

    if (currentState is! RestaurantStateLoaded) {
      emit(const RestaurantStateError(
        message: 'Restaurant not loaded',
      ));
      return;
    }

    try {
      final updatedRestaurant = currentState.restaurant.copyWith(
        isDeliveryEnabled: event.isDeliveryEnabled,
      );

      await _firestoreProvider.updateRestaurant(updatedRestaurant);
      // The stream will emit the updated restaurant automatically
    } on FirestoreOperationException catch (e) {
      emit(RestaurantStateError(message: e.message));
    } catch (e) {
      emit(RestaurantStateError(
        message: 'Failed to update delivery status: $e',
      ));
    }
  }
  void _onStreamUpdated(
  RestaurantEventStreamUpdated event,
  Emitter<RestaurantState> emit,
) {
  emit(RestaurantStateLoaded(restaurant: event.restaurant));
}

void _onStreamError(
  RestaurantEventStreamError event,
  Emitter<RestaurantState> emit,
) {
  emit(RestaurantStateError(message: event.message));
}

void _onTimeout(
  RestaurantEventTimeout event,
  Emitter<RestaurantState> emit,
) {
  if (state is RestaurantStateLoading) {
    emit(const RestaurantStateError(
      message: 'Failed to load restaurant data. Please try again.',
    ));
  }
}

  @override
  Future<void> close() {
    _restaurantSubscription?.cancel();
    _timeoutTimer?.cancel();
    return super.close();
  }
}