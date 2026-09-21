// ============================================================
// FORFOOD — MAIN
// ============================================================

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/service/chat/chat_bloc.dart';
import 'package:forfood/service/notification/fcm_service.dart';
import 'package:forfood/service/notification/local_notification_listner.dart';
import 'package:forfood/service/revenuecat/revenuecat_service.dart';
import 'package:provider/provider.dart';

import 'package:forfood/firebase_options.dart';
import 'package:forfood/l10n/app_localizations.dart';
import 'package:forfood/service/auth/user_role.dart';
import 'package:forfood/service/language/language_provider.dart';
import 'package:forfood/service/location/geocoding_service.dart';
import 'package:forfood/service/location/location_bloc.dart';
import 'package:forfood/service/location/location_service.dart';

import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/auth/firebase_auth_provider.dart';
import 'package:forfood/service/cart/cart_bloc.dart';
import 'package:forfood/service/database/firestore_provider.dart';
import 'package:forfood/service/login/login_bloc.dart';
import 'package:forfood/service/menu/menu_bloc.dart';
import 'package:forfood/service/notification/notification_bloc.dart';
import 'package:forfood/service/order/order_bloc.dart';
import 'package:forfood/service/restaurant/restaurant_bloc.dart';
import 'package:forfood/service/restaurant_list/restaurant_list_bloc.dart';
import 'package:forfood/service/search/search_bloc.dart';
import 'package:forfood/service/signup/signup_bloc.dart';

import 'package:forfood/view/splash_screen.dart';
import 'package:forfood/view/join_user_restaurant.dart';
import 'package:forfood/view/restaurant/home_page.dart';
import 'package:forfood/view/user/home_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ============================================================
// SAFE AREA BUILDER
// - Paints the status bar area brand yellow
// - Pushes all content below the notch
// - Shrinks the reported screen height so inner `screenHeight * scale`
//   math stays accurate
// ============================================================
Widget _safeAreaBuilder(BuildContext context, Widget? child) {
  final mq = MediaQuery.of(context);
  final topPadding = mq.padding.top;

  return Container(
    color: AppColor.yellow,
    child: Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: MediaQuery(
        data: mq.copyWith(
          size: Size(mq.size.width, mq.size.height - topPadding),
          padding: EdgeInsets.zero,
          viewPadding: EdgeInsets.zero,
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  FcmService.instance.initialize();
  FcmService.instance.saveTokenToFirestore();
  LocalNotificationListener.instance.start();

  final languageProvider = LanguageProvider();
  await languageProvider.loadLocale();

  runApp(
    ChangeNotifierProvider(
      create: (_) => languageProvider,
      child: const ForFoodApp(),
    ),
  );
}

class ForFoodApp extends StatelessWidget {
  const ForFoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => AuthBloc(FirebaseAuthProvider())),
        RepositoryProvider<FirestoreProvider>(
          create: (_) => FirestoreProvider(),
        ),
        BlocProvider<LoginBloc>(
          create: (c) => LoginBloc(
            authProvider: FirebaseAuthProvider(),
            authBloc: c.read<AuthBloc>(),
          ),
        ),
        BlocProvider<SignupBloc>(
          create: (c) => SignupBloc(
            authProvider: FirebaseAuthProvider(),
            authBloc: c.read<AuthBloc>(),
          ),
        ),
        BlocProvider<RestaurantBloc>(
          create: (c) => RestaurantBloc(c.read<FirestoreProvider>()),
        ),
        BlocProvider<MenuBloc>(
          create: (c) => MenuBloc(c.read<FirestoreProvider>()),
        ),
        BlocProvider<CartBloc>(create: (_) => CartBloc()),
        BlocProvider<OrderBloc>(
          create: (c) =>
              OrderBloc(c.read<FirestoreProvider>(), c.read<CartBloc>()),
        ),
        BlocProvider<NotificationBloc>(
          create: (c) => NotificationBloc(c.read<FirestoreProvider>()),
        ),
        BlocProvider<SearchBloc>(
          create: (c) => SearchBloc(c.read<FirestoreProvider>()),
        ),
        BlocProvider<RestaurantListBloc>(
          create: (c) => RestaurantListBloc(c.read<FirestoreProvider>()),
        ),
        BlocProvider<LocationBloc>(
          create: (_) => LocationBloc(
            geocodingService: NominatimGeocodingService(),
            locationService: LocationService(),
          ),
        ),
        BlocProvider<ChatBloc>(
          create: (c) => ChatBloc(c.read<FirestoreProvider>()),
        ),
      ],      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (prev, curr) =>
            curr is AuthStateLoggedOut ||
            (curr is AuthStateLoggedIn &&
                (prev is! AuthStateLoggedIn ||
                    prev.user.id != curr.user.id)),
        listener: (context, state) async {
          if (state is AuthStateLoggedIn) {
            await RevenueCatService.initialize(appUserID: state.user.id);
            // Pop every pushed route so the root home screen becomes visible.
            navigatorKey.currentState?.popUntil((route) => route.isFirst);
          } else if (state is AuthStateLoggedOut) {
            await RevenueCatService.logOut();
            // Same on logout — return to the join screen.
            navigatorKey.currentState?.popUntil((route) => route.isFirst);
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            Widget home;

            if (authState is AuthStateLoggedIn) {
              home = authState.user.role == UserRole.restaurant
                  ? const RestaurantHomeView()
                  : const UserHomeView();
            } else if (authState is AuthStateLoggedOut) {
              home = const JoinUserRestaurantView();
            } else {
              home = const SplashScreen();
            }

            return MaterialApp(
              navigatorKey: navigatorKey,
              title: 'ForFood',
              debugShowCheckedModeBanner: false,
              builder: _safeAreaBuilder,
              theme: ThemeData(
                fontFamily: 'League Spartan',
                useMaterial3: true,
              ),
              locale: languageProvider.locale,
              supportedLocales: const [
                Locale('en'),
                Locale('ar'),
                Locale('fr'),
                Locale('es'),
                Locale('tr'),
                Locale('it'),
              ],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: home,
            );
          },
        ),
      ),
    );
  }
}
