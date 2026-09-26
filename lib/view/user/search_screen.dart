// ============================================================
// SEARCH VIEW — PRODUCTION READY
// Filter fields + Location picker + Bottom Nav + Drawer
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/bottom_nav_dart.dart';
import 'package:forfood/core/widgets/cart_app_drawer.dart';
import 'package:forfood/core/widgets/drawer_helpers.dart';
import 'package:forfood/core/widgets/location_map_picker.dart';
import 'package:forfood/core/widgets/notification_drawer.dart';
import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/auth/user_role.dart';
import 'package:forfood/service/location/geocoding_service.dart';
import 'package:forfood/service/location/location_service.dart';
import 'package:forfood/service/search/search_bloc.dart';
import 'package:forfood/service/search/search_event.dart';
import 'package:forfood/service/search/search_state.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/utilities/tab_route.dart';
import 'package:forfood/view/chat_inbox_view.dart';
import 'package:forfood/view/user/my_order_view.dart';
import 'package:forfood/view/user/results.dart';
import 'package:forfood/view/user/home_page.dart';
import 'package:geolocator/geolocator.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _cravingController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _locationController =
      TextEditingController(text: '');
  final GeocodingService _geocodingService = NominatimGeocodingService();
  bool _showLocationPrompt = true;
  int _currentIndex = 1;

  // ✅ Scaffold key + which drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DrawerType _activeDrawer = DrawerType.profile;

  // GPS location (fetched on init)
  double? _userLatitude;
  double? _userLongitude;

  // Manually picked location (overrides GPS if set)
  double? _pickedLatitude;
  double? _pickedLongitude;

  bool _isFetchingLocation = true;

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  @override
  void dispose() {
    _cravingController.dispose();
    _budgetController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // ✅ Drawer openers
  void _openProfileDrawer() {
    setState(() => _activeDrawer = DrawerType.profile);
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _openCartDrawer() {
    setState(() => _activeDrawer = DrawerType.cart);
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _openNotificationDrawer() {
    setState(() => _activeDrawer = DrawerType.notifications);
    _scaffoldKey.currentState?.openEndDrawer();
  }

  // ✅ Fetch GPS location in the background
  Future<void> _fetchUserLocation() async {
    setState(() {
      _isFetchingLocation = true;
      _locationController.text = 'Finding your location...';
    });

    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentPosition();

      if (!mounted) return;

      // ─── GPS failed ───
      if (position == null) {
        setState(() {
          _isFetchingLocation = false;
          _locationController.text = '';
        });
        // Show the "enable location" dialog once on load
        if (_showLocationPrompt) {
          _showLocationPrompt = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showEnableLocationDialog();
          });
        }
        return;
      }

      // ─── GPS works → reverse geocode ───
      final place = await _geocodingService.reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) return;

      setState(() {
        _userLatitude = position.latitude;
        _userLongitude = position.longitude;
        _pickedLatitude = null;
        _pickedLongitude = null;
        _locationController.text = place?.displayName ?? 'Current location';
        _isFetchingLocation = false;
      });
    } catch (e) {
      debugPrint('Failed to fetch user location: $e');
      if (!mounted) return;
      setState(() {
        _isFetchingLocation = false;
        _locationController.text = '';
      });
    }
  }

  Future<void> _showEnableLocationDialog() async {
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColor.nearWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Enable location',
          style: TextStyle(
            color: AppColor.textDark,
            fontSize: 18,
            fontFamily: 'League Spartan',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'ForFood needs your location to show restaurants near you. '
          'Please enable it to continue.',
          style: TextStyle(
            color: AppColor.textDark,
            fontSize: 14,
            fontFamily: 'League Spartan',
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'later'),
            child: const Text(
              'Not now',
              style: TextStyle(
                color: AppColor.gray,
                fontFamily: 'League Spartan',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'enable'),
            child: const Text(
              'Enable',
              style: TextStyle(
                color: AppColor.orange,
                fontFamily: 'League Spartan',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (!mounted || action == null) return;

    if (action == 'enable') {
      // Try permission first, then fall back to app settings
      final locationService = LocationService();
      final permission = await locationService.checkPermission();

      if (permission == LocationPermission.deniedForever) {
        await locationService.openAppSettings();
      } else {
        final result = await locationService.requestPermission();
        if (result == LocationPermission.deniedForever) {
          await locationService.openAppSettings();
        }
      }

      if (!mounted) return;

      // Retry fetch
      await _fetchUserLocation();
    }
  }

  // ✅ Open the map picker to select a location
  Future<void> _openLocationPicker() async {
    // Start the picker at GPS position if available, else default Algiers
    final initialLat = _pickedLatitude ?? _userLatitude ?? 36.7538;
    final initialLng = _pickedLongitude ?? _userLongitude ?? 3.0588;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LocationMapPicker(
          initialLatitude: initialLat,
          initialLongitude: initialLng,
          initialAddress: _locationController.text == 'Near you'
              ? ''
              : _locationController.text,
          onConfirmed: (address, lat, lng) {
            setState(() {
              _locationController.text = address;
              _pickedLatitude = lat;
              _pickedLongitude = lng;
            });
          },
        ),
      ),
    );
  }

  // ✅ Reset to GPS "Near you"
  void _resetToGpsLocation() async {
    setState(() {
      _pickedLatitude = null;
      _pickedLongitude = null;
    });
    // Refetch GPS (this also re-runs reverse geocode)
    await _fetchUserLocation();
  }

  void _handleSearch() {
    final craving = _cravingController.text.trim();
    final budgetString = _budgetController.text.trim();
    final location = _locationController.text.trim();

    final maxBudget = double.tryParse(budgetString);
    if (maxBudget == null || maxBudget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid budget')),
      );
      return;
    }

    // Use picked > GPS > default
    final userLatitude = _pickedLatitude ?? _userLatitude ?? 36.7538;
    final userLongitude = _pickedLongitude ?? _userLongitude ?? 3.0588;

    context.read<SearchBloc>().add(
          SearchEventPerformSearch(
            craving: craving,
            maxBudget: maxBudget,
            userLatitude: userLatitude,
            userLongitude: userLongitude,
          ),
        );

    Navigator.push(
      context,
      fadeSlideRoute(
        ResultsView(
          craving: craving,
          maxBudget: budgetString,
          location: location,
        ),
      ),
    );
  }

  void _handleBottomNavTap(int index) {
    if (index == _currentIndex) return;

    switch (index) {
      case 0:
        Navigator.of(context).pushAndRemoveUntil(
          tabRoute(const UserHomeView()),
          (route) => false,
        );
        break;
      case 1:
        Navigator.of(context).push(tabRoute(const SearchView()));
        break;
      case 2:
        Navigator.of(context).push(tabRoute(const ChatInboxView()));
        break;
      case 3:
        // ✅ Cart tab → cart drawer
        Navigator.of(context).push(tabRoute(const MyOrdersView()));
        break;
      case 4:
        // ✅ Profile tab → profile drawer
        _openProfileDrawer();
        break;
    }
  }

  // ✅ Picks which drawer renders (preserves restaurant vs user)
  Widget _buildActiveDrawer(
    String userName,
    String userEmail,
    String? profileImageUrl,
    bool isRestaurant,
  ) {
    switch (_activeDrawer) {
      case DrawerType.profile:
        return isRestaurant
            ? buildRestaurantDrawer(
                name: userName,
                email: userEmail,
                profileImageUrl: profileImageUrl,
              )
            : buildUserDrawer(
                name: userName,
                email: userEmail,
                profileImageUrl: profileImageUrl,
              );
      case DrawerType.cart:
        return const CartView();
      case DrawerType.notifications:
        return const NotificationDrawer();
    }
  }

  Widget _filterField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    Widget? trailing,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthScale = screenWidth / 393;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColor.textDark,
            fontSize: 20 * widthScale,
            fontFamily: 'League Spartan',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 45,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF3E9B5),
            borderRadius: BorderRadius.circular(13),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColor.textDark,
                fontSize: 14 * widthScale,
                fontFamily: 'League Spartan',
                fontWeight: FontWeight.w300,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              suffixIcon: trailing,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final widthScale = screenWidth / 393;
    final heightScale = screenHeight / 852;

    final hasPickedLocation = _pickedLatitude != null;
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        String userName = '';
        String userEmail = '';
        String? profileImageUrl;
        bool isRestaurant = false;

        if (authState is AuthStateLoggedIn) {
          userName = authState.user.fullName;
          userEmail = authState.user.email;
          profileImageUrl = authState.user.profileImageUrl;
          isRestaurant = authState.user.role == UserRole.restaurant;
        }

        return Scaffold(
          key: _scaffoldKey,
          // ✅ Dynamic drawer
          endDrawer: _buildActiveDrawer(
            userName,
            userEmail,
            profileImageUrl,
            isRestaurant,
          ),
          body: Container(
            width: screenWidth,
            height: screenHeight,
            clipBehavior: Clip.antiAlias,
            decoration: ShapeDecoration(
              color: const Color(0xFFF5CB58),
              shape: RoundedRectangleBorder(
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 163 * heightScale,
                  child: Container(
                    width: screenWidth,
                    height: screenHeight - (163 * heightScale),
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      color: const Color(0xFFF5F5F5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  left: 35 * widthScale,
                  top: 84 * heightScale,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset(
                      'assets/icons/BackiconArrow.png',
                      width: 20 * widthScale,
                      height: 20 * heightScale,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                Positioned(
                  left: 140 * widthScale,
                  top: 76 * heightScale,
                  child: Text(
                    'Filter',
                    style: TextStyle(
                      color: AppColor.nearWhite,
                      fontSize: 30 * widthScale,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Positioned(
                  left: 30 * widthScale,
                  right: 0,
                  top: 180 * heightScale,
                  bottom: 0,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(right: 25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Find your food  ',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 28 * widthScale,
                                fontFamily: 'League Spartan',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SvgPicture.asset(
                              'assets/icons/LocationMapicon.svg',
                              height: 40,
                              width: 40,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          height: 1,
                          width: 254 * widthScale,
                          color: AppColor.divider,
                        ),
                        const SizedBox(height: 24),

                        _filterField(
                          label: 'What are you craving?',
                          controller: _cravingController,
                          hint: 'e.g. pizza, burger, tacos..',
                        ),
                        const SizedBox(height: 24),
                        Container(
                          height: 1,
                          width: 322 * widthScale,
                          color: AppColor.divider,
                        ),
                        const SizedBox(height: 24),

                        _filterField(
                          label: 'Your budget',
                          controller: _budgetController,
                          hint: 'e.g 10 \$',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          height: 1,
                          width: 322 * widthScale,
                          color: AppColor.divider,
                        ),
                        const SizedBox(height: 24),

                        // ============================================================
                        // Where field with picker
                        // ============================================================
                        _filterField(
                          label: 'Where',
                          controller: _locationController,
                          hint: _isFetchingLocation
                              ? 'Finding your location...'
                              : 'Tap to set location',
                          trailing: _isFetchingLocation
                              ? Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColor.orange,
                                    ),
                                  ),
                                )
                              : hasPickedLocation
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: AppColor.orange,
                                        size: 18,
                                      ),
                                      onPressed: _resetToGpsLocation,
                                    )
                                  : IconButton(
                                      icon: const Icon(
                                        Icons.my_location,
                                        color: AppColor.orange,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        if (_userLatitude == null) {
                                          _showEnableLocationDialog();
                                        } else {
                                          _resetToGpsLocation();
                                        }
                                      },
                                    ),
                        ),

                        // Actions row: "See on Map" and "Reset"
                        Padding(
                          padding: EdgeInsets.only(left: 215 * widthScale),
                          child: TextButton.icon(
                            onPressed: () {
                              if (_userLatitude == null &&
                                  _pickedLatitude == null) {
                                // No GPS, no manual pick → offer to enable
                                _showEnableLocationDialog();
                              } else {
                                _openLocationPicker();
                              }
                            },
                            icon: const Icon(
                              Icons.location_on,
                              color: AppColor.orange,
                              size: 12,
                            ),
                            label: Text(
                              'Pick on Map',
                              style: TextStyle(
                                color: AppColor.orange,
                                fontSize: 12 * widthScale,
                                fontFamily: 'League Spartan',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        Center(
                          child: BlocBuilder<SearchBloc, SearchState>(
                            builder: (context, searchState) {
                              final isLoading =
                                  searchState is SearchStateLoading;
                              return GestureDetector(
                                onTap: (isLoading || _isFetchingLocation)
                                    ? null
                                    : _handleSearch,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isLoading
                                        ? AppColor.gray
                                        : AppColor.orange,
                                    borderRadius: BorderRadius.circular(51.57),
                                  ),
                                  child: (isLoading || _isFetchingLocation)
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Search',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontFamily: 'League Spartan',
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavBar(
            currentIndex: _currentIndex,
            onTap: _handleBottomNavTap,
          ),
        );
      },
    );
  }
}