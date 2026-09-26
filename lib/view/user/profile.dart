// ============================================================
// USER PROFILE VIEW — PRODUCTION READY
// Real drawer + Image Picker + Bottom Nav + Responsive + Keyboard Dismiss
// ============================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forfood/service/auth/auth_event.dart';
import 'package:forfood/service/auth/auth_user.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/utilities/tab_route.dart';
import 'package:forfood/view/chat_inbox_view.dart';
import 'package:forfood/view/user/my_order_view.dart';
import 'package:image_picker/image_picker.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/bottom_nav_dart.dart';
import 'package:forfood/core/widgets/cart_app_drawer.dart';
import 'package:forfood/core/widgets/drawer_helpers.dart';
import 'package:forfood/core/widgets/notification_drawer.dart';
import 'package:forfood/core/widgets/profile_avatar.dart';

import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/database/firestore_provider.dart';
import 'package:forfood/service/exceptions/domain_exceptions.dart';

import 'package:forfood/view/user/home_page.dart';
import 'package:forfood/view/user/search_screen.dart';

class UserProfileView extends StatefulWidget {
  const UserProfileView({super.key});

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  int _currentIndex = 4;
  bool _isSaving = false;
  File? _selectedImage;
  final FirestoreProvider _firestoreProvider = FirestoreProvider();
  final ImagePicker _imagePicker = ImagePicker();

  // ✅ Scaffold key + which drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DrawerType _activeDrawer = DrawerType.profile;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthStateLoggedIn) {
      _nameController.text = authState.user.fullName;
      _emailController.text = authState.user.email;
      _phoneController.text = authState.user.phoneNumber ?? '';
    }
  }

  // ✅ Image picker implementation
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _handleUpdateProfile() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Full name is required')),
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthStateLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to update profile')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 1. Fetch existing user doc so we preserve createdAt
      final existingUser =
          await _firestoreProvider.getUserById(authState.user.id);

      // 2. Upload new image if picked
      String? imageUrl = existingUser.profileImageUrl;
      if (_selectedImage != null) {
        imageUrl = await _firestoreProvider.uploadImage(
          file: _selectedImage!,
          path:
              'users/${authState.user.id}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      // 3. Update Firestore — preserve createdAt
      final updatedUser = existingUser.copyWith(
        fullName: name,
        email: email,
        phoneNumber: phone.isEmpty ? null : phone,
        profileImageUrl: imageUrl,
      );
      await _firestoreProvider.updateUser(updatedUser);

      if (!mounted) return;

      // 4. Push fresh user into AuthBloc — no flash, drawer + avatar update everywhere
      context.read<AuthBloc>().add(
            AuthEventLoggedIn(
              user: AuthUser(
                id: updatedUser.id,
                fullName: updatedUser.fullName,
                email: updatedUser.email,
                phoneNumber: updatedUser.phoneNumber,
                profileImageUrl: updatedUser.profileImageUrl,
                role: updatedUser.role,
              ),
            ),
          );

      // 5. Success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // 6. Drop the temp file — AuthBloc now holds the remote URL
      setState(() => _selectedImage = null);
    } on FirestoreOperationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
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
            setState(() => _currentIndex = index);   // ✅ highlight

        // ✅ Cart tab → cart drawer
        Navigator.of(context).push(tabRoute(const MyOrdersView()));
        break;
      case 4:
            setState(() => _currentIndex = index);   // ✅ highlight

        // ✅ Profile tab → profile drawer
        _openProfileDrawer();
        break;
    }
  }

  // ✅ Picks which drawer renders
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
            // ✅ Dynamic drawer
            endDrawer: _buildActiveDrawer(
              userName,
              userEmail,
              profileImageUrl,
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
                    left: 116 * widthScale,
                    top: 76 * heightScale,
                    child: Text(
                      'My Profile',
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
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: 20 * heightScale),
                          Center(
                            child: Stack(
                              children: [
                                GestureDetector(
                                  onTap: _pickImage,
                                  child: ProfileAvatar(
                                    imageUrl: _selectedImage != null
                                        ? _selectedImage!.path
                                        : profileImageUrl,
                                    size: 127 * widthScale,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _pickImage,
                                    child: Container(
                                      width: 26 * widthScale,
                                      height: 26 * heightScale,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppColor.orange,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.edit,
                                        color: AppColor.white,
                                        size: 14 * widthScale,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 30 * heightScale),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 35 * widthScale),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Full Name',
                                  style: TextStyle(
                                    color: AppColor.textDark,
                                    fontSize: 20 * widthScale,
                                    fontFamily: 'League Spartan',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8 * heightScale),
                                Container(
                                  height: 45 * heightScale,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3E9B5),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: TextField(
                                    controller: _nameController,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16 * widthScale),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20 * heightScale),
                                Text(
                                  'Email',
                                  style: TextStyle(
                                    color: AppColor.textDark,
                                    fontSize: 20 * widthScale,
                                    fontFamily: 'League Spartan',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8 * heightScale),
                                Container(
                                  height: 45 * heightScale,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3E9B5),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: TextField(
                                    controller: _emailController,
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16 * widthScale),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20 * heightScale),
                                Text(
                                  'Phone Number (optional)',
                                  style: TextStyle(
                                    color: AppColor.textDark,
                                    fontSize: 20 * widthScale,
                                    fontFamily: 'League Spartan',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8 * heightScale),
                                Container(
                                  height: 45 * heightScale,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3E9B5),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: TextField(
                                    controller: _phoneController,
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16 * widthScale),
                                      hintText: '01 23 45 67 89',
                                      hintStyle: TextStyle(
                                        color: AppColor.gray,
                                        fontSize: 15 * widthScale,
                                        fontFamily: 'League Spartan',
                                      ),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 40 * heightScale),
                                Center(
                                  child: GestureDetector(
                                    onTap: _isSaving ? null : _handleUpdateProfile,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 24 * widthScale,
                                        vertical: 10 * heightScale,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _isSaving ? AppColor.gray : AppColor.orange,
                                        borderRadius: BorderRadius.circular(100),
                                      ),
                                      child: _isSaving
                                          ? SizedBox(
                                              width: 24 * widthScale,
                                              height: 24 * heightScale,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                              'Update Profile',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 17 * widthScale,
                                                fontFamily: 'League Spartan',
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
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
          ),
        );
      },
    );
  }
}