// ============================================================
// ADD ADDRESS VIEW
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

import 'package:forfood/models/address_model.dart';
import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/database/firestore_provider.dart';
import 'package:forfood/service/exceptions/domain_exceptions.dart';
import 'package:forfood/utilities/tab_route.dart';
import 'package:forfood/view/chat_inbox_view.dart';

import 'package:forfood/view/user/home_page.dart';
import 'package:forfood/view/user/search_screen.dart';

class AddAddressView extends StatefulWidget {
  const AddAddressView({super.key});

  @override
  State<AddAddressView> createState() => _AddAddressViewState();
}

class _AddAddressViewState extends State<AddAddressView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 3;
  bool _isSaving = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final FirestoreProvider _firestoreProvider = FirestoreProvider();

  // ✅ Which drawer to show — same pattern as UserHomeView
  DrawerType _activeDrawer = DrawerType.profile;

  double? _pickedLatitude;
  double? _pickedLongitude;

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

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _openLocationPicker() async {
    final initialLat = _pickedLatitude ?? 36.7538;
    final initialLng = _pickedLongitude ?? 3.0588;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LocationMapPicker(
          initialLatitude: initialLat,
          initialLongitude: initialLng,
          initialAddress: _addressController.text.trim(),
          onConfirmed: (address, lat, lng) {
            setState(() {
              _addressController.text = address;
              _pickedLatitude = lat;
              _pickedLongitude = lng;
            });
          },
        ),
      ),
    );
  }

  Future<void> _handleSaveAddress() async {
    final label = _nameController.text.trim();
    final fullAddress = _addressController.text.trim();

    if (label.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address name is required')),
      );
      return;
    }

    if (fullAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address is required')),
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthStateLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add an address')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final address = AddressModel(
        id: '',
        userId: authState.user.id,
        label: label,
        fullAddress: fullAddress,
        isDefault: false,
        createdAt: DateTime.now(),
      );

      await _firestoreProvider.createAddress(address);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address added successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } on FirestoreOperationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save address: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _handleBottomNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushAndRemoveUntil(
          tabRoute(const UserHomeView()),
          (route) => false,
        );
        break;
      case 1:
        Navigator.of(context).pushReplacement(
          tabRoute(const SearchView()),
        );
        break;
      case 2:
        Navigator.of(context).pushReplacement(
          tabRoute(const ChatInboxView()),
        );
        break;
      case 3:
            setState(() => _currentIndex = index);   // ✅ highlight

        // ✅ Cart tab → cart drawer
        _openCartDrawer();
        break;
      case 4:
            setState(() => _currentIndex = index);   // ✅ highlight

        // ✅ Profile tab → profile drawer
        _openProfileDrawer();
        break;
    }
  }

  // ✅ Same helper as UserHomeView — picks which drawer renders
  Widget _buildActiveDrawer(
    String userName,
    String userEmail,
    String? profileImageUrl,
  ) {
    switch (_activeDrawer) {
      case DrawerType.profile:
        return buildUserDrawer(
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final widthScale = screenWidth / 393;
    final heightScale = screenHeight / 852;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        String userName = '';
        String userEmail = '';
        String? profileImageUrl;

        if (authState is AuthStateLoggedIn) {
          userName = authState.user.fullName;
          userEmail = authState.user.email;
          profileImageUrl = authState.user.profileImageUrl;
        }

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            key: _scaffoldKey,
            // ✅ Dynamic drawer based on _activeDrawer
            endDrawer: _buildActiveDrawer(
              userName,
              userEmail,
              profileImageUrl,
            ),
            body: Container(
              width: screenWidth,
              height: screenHeight,
              clipBehavior: Clip.antiAlias,
              decoration: const ShapeDecoration(
                color: Color(0xFFF5CB58),
                shape: RoundedRectangleBorder(),
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
                      decoration: const ShapeDecoration(
                        color: Color(0xFFF5F5F5),
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
                    left: 100 * widthScale,
                    top: 76 * heightScale,
                    child: Text(
                      'Add New Address',
                      style: TextStyle(
                        color: AppColor.nearWhite,
                        fontSize: 28 * widthScale,
                        fontFamily: 'League Spartan',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 163 * heightScale,
                    bottom: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 16 * heightScale),
                            child: SvgPicture.asset(
                              'assets/icons/home.svg',
                              height: 100 * heightScale,
                              width: 100 * widthScale,
                              color: AppColor.orange,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                                horizontal: 35 * widthScale),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Name',
                                  style: TextStyle(
                                    color: AppColor.textDark,
                                    fontSize: 20,
                                    fontFamily: 'League Spartan',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 45,
                                  decoration: BoxDecoration(
                                    color: AppColor.yellow2,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: TextField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                      hintText: 'e.g. Anna House',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Address',
                                      style: TextStyle(
                                        color: AppColor.textDark,
                                        fontSize: 20,
                                        fontFamily: 'League Spartan',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _openLocationPicker,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons.location_on,
                                            color: AppColor.orange,
                                            size: 18,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Pick on Map',
                                            style: TextStyle(
                                              color: AppColor.orange,
                                              fontSize: 14,
                                              fontFamily: 'League Spartan',
                                              fontWeight: FontWeight.w600,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 65,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColor.yellow2,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: TextField(
                                    controller: _addressController,
                                    maxLines: null,
                                    decoration: const InputDecoration(
                                      hintText:
                                          'Tap "Pick on Map" or type...',
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 90),
                                Center(
                                  child: GestureDetector(
                                    onTap: _isSaving
                                        ? null
                                        : _handleSaveAddress,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 40,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _isSaving
                                            ? AppColor.gray
                                            : AppColor.orange,
                                        borderRadius:
                                            BorderRadius.circular(38),
                                      ),
                                      child: _isSaving
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child:
                                                  CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text(
                                              'Apply',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 17,
                                                fontFamily:
                                                    'League Spartan',
                                                fontWeight:
                                                    FontWeight.w500,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: BottomNavBar(
              currentIndex: _currentIndex,
              onTap: _handleBottomNavTap,
            ),
          ),
        );
      },
    );
  }
}