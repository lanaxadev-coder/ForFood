// ============================================================
// NAVIGATION BLOC — Controls auth screen switching
// ============================================================

import 'package:flutter_bloc/flutter_bloc.dart';

/// Which auth screen to show when user is logged out.
enum AuthScreen { join, login, signup, forgotPassword }

/// Events for NavigationBloc.
abstract class NavigationEvent {
  const NavigationEvent();
}

class NavigationEventNavigateTo extends NavigationEvent {
  final AuthScreen screen;
  const NavigationEventNavigateTo(this.screen);
}

class NavigationEventReset extends NavigationEvent {
  const NavigationEventReset();
}

/// State for NavigationBloc.
class NavigationState {
  final AuthScreen screen;
  const NavigationState(this.screen);
}

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc() : super(const NavigationState(AuthScreen.join)) {
    print('🔵 NAVIGATION BLOC: Constructor called, initial: ${AuthScreen.join}');
    on<NavigationEventNavigateTo>(_onNavigate);
    on<NavigationEventReset>(_onReset);
  }

  void _onNavigate(
    NavigationEventNavigateTo event,
    Emitter<NavigationState> emit,
  ) {
    print('🔵 NAVIGATION BLOC: Navigate to ${event.screen}');
    emit(NavigationState(event.screen));
  }

  void _onReset(
    NavigationEventReset event,
    Emitter<NavigationState> emit,
  ) {
    print('🔵 NAVIGATION BLOC: Reset to join');
    emit(const NavigationState(AuthScreen.join));
  }
}