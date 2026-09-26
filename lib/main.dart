// ============================================================
// FORFOOD — MAIN
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/service/chat/chat_bloc.dart';
import 'package:forfood/service/notification/fcm_service.dart';
import 'package:forfood/service/notification/local_notification_listner.dart';
import 'package:forfood/service/restaurant_list/restaurant_list_event.dart';
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

// ── Global keys ─────────────────────────────────────────────
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

// ============================================================
// SAFE AREA BUILDER
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
       FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
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

// ============================================================
// ROOT APP — StatefulWidget so we can track the last valid screen
// ============================================================
class ForFoodApp extends StatefulWidget {
  const ForFoodApp({super.key});

  @override
  State<ForFoodApp> createState() => _ForFoodAppState();
}

class _ForFoodAppState extends State<ForFoodApp> {
  // Remembers the last "real" home screen so `Loading` and `Error`
  // don't blank the app back to Splash.
  Widget _lastHome = const SplashScreen();

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
      ],
      child: BlocListener<AuthBloc, AuthState>(
        // ── Nav listener (existing) ─────────────────────────
        listenWhen: (prev, curr) =>
            curr is AuthStateLoggedOut ||
            (curr is AuthStateLoggedIn &&
                (prev is! AuthStateLoggedIn ||
                    prev.user.id != curr.user.id)),
      
      
                listener: (context, state) async {
          if (state is AuthStateLoggedIn) {
            await RevenueCatService.initialize(appUserID: state.user.id);
            navigatorKey.currentState?.popUntil((route) => route.isFirst);

            // ✅ PRELOAD: warm the home + map caches before the user lands on them.
            //    Fires two Firestore queries in the background. The home screen
            //    and the map will read from Firestore's cache instead of hitting
            //    the network when they mount.
            if (!context.mounted) return;
            context.read<RestaurantListBloc>().add(
                  const RestaurantListEventFetchRecommendations(),
                );
            context.read<RestaurantListBloc>().add(
                  const RestaurantListEventFetchHighDemands(),
                );
          } else if (state is AuthStateLoggedOut) {
             navigatorKey.currentState?.popUntil((route) => route.isFirst);
            // ✅ RevenueCat logout runs in the background — don't block UI on it.
            RevenueCatService.logOut();
          }
        },
        child: BlocListener<AuthBloc, AuthState>(
          // ── NEW: Error listener → show snackbar ──────────
          listenWhen: (prev, curr) =>
              prev is! AuthStateError && curr is AuthStateError,
          listener: (context, state) {
            if (state is AuthStateError) {
              scaffoldMessengerKey.currentState?.showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          },
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              // Only real states update `_lastHome`.
              // Loading / Error keep whatever we had before.
              if (authState is AuthStateLoggedIn) {
                _lastHome = authState.user.role == UserRole.restaurant
                    ? const RestaurantHomeView()
                    : const UserHomeView();
              } else if (authState is AuthStateLoggedOut) {
                _lastHome = const JoinUserRestaurantView();
              } else if (authState is AuthStateInitial) {
                _lastHome = const SplashScreen();
              }
              // else: Loading or Error → _lastHome unchanged

              return MaterialApp(
                navigatorKey: navigatorKey,
                scaffoldMessengerKey: scaffoldMessengerKey,
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
                home: _lastHome,
              );
            },
          ),
        ),
      ),
    );
  }
}