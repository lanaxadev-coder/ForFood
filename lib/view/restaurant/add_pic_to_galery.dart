// ============================================================
// ADD GALLERY IMAGE VIEW — FIXED BOTTOM NAV + RESTAURANT ID
// ============================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/view/chat_inbox_view.dart';
import 'package:image_picker/image_picker.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/bottom_nav_dart.dart';
import 'package:forfood/core/widgets/drawer_helpers.dart';
import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/database/firestore_provider.dart';
import 'package:forfood/service/restaurant/restaurant_bloc.dart';
import 'package:forfood/service/restaurant/restaurant_event.dart';
import 'package:forfood/service/restaurant/restaurant_state.dart';

import 'package:forfood/view/restaurant/home_page.dart';
import 'package:forfood/view/restaurant/incoming_order.dart';
import 'package:forfood/view/restaurant/menu.dart';
import 'package:forfood/view/restaurant/profile.dart';

class AddGalleryImageView extends StatefulWidget {
  const AddGalleryImageView({super.key});

  @override
  State<AddGalleryImageView> createState() => _AddGalleryImageViewState();
}

class _AddGalleryImageViewState extends State<AddGalleryImageView> {
  int _currentIndex = 0;
  bool _isUploading = false;
  File? _selectedImage;
  String? _restaurantId;
  final FirestoreProvider _firestoreProvider = FirestoreProvider();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchRestaurantId();
  }

  // ✅ FIXED: Fetch actual restaurant ID
  void _fetchRestaurantId() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthStateLoggedIn) {
      context.read<RestaurantBloc>().add(
            RestaurantEventFetchByOwnerId(ownerId: authState.user.id),
          );
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1080,
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

 Future<void> _handleUpload() async {
  if (_selectedImage == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select an image first')),
    );
    return;
  }

  if (_restaurantId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Restaurant not loaded yet. Please wait.')),
    );
    return;
  }

  setState(() => _isUploading = true);

  try {
    // ✅ Upload to ImgBB instead of Firebase Storage
    final imageUrl = await _firestoreProvider.uploadImage(
      file: _selectedImage!,
      path: 'gallery/${_restaurantId!}/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    // Save URL to Firestore
    await _firestoreProvider.addGalleryImage(
      restaurantId: _restaurantId!,
      imageUrl: imageUrl,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image uploaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  } finally {
    if (mounted) setState(() => _isUploading = false);
  }
}

  // ✅ FIXED: Bottom nav navigation
  void _handleBottomNavTap(int index) {
  if (index == _currentIndex) return;

  switch (index) {
    case 0:
      Navigator.of(context).pushAndRemoveUntil(
        fadeSlideRoute(const RestaurantHomeView()),
        (route) => false,
      );
      break;
    case 1:
      Navigator.of(context).pushAndRemoveUntil(
        fadeSlideRoute(const OrdersView()),
        (route) => false,
      );
      break;
    case 2:
      Navigator.of(context).push(fadeSlideRoute(const ChatInboxView()));
      break;
    case 3:
      Navigator.of(context).push(fadeSlideRoute(const MenuListView()));
      break;
    case 4:
      Navigator.of(context).push(
        fadeSlideRoute(const ProfileViewRestaurant()),
      );
      break;
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
        String restaurantName = '';
        String restaurantEmail = '';
        String? profileImageUrl;

        if (authState is AuthStateLoggedIn) {
          restaurantName = authState.user.fullName;
          restaurantEmail = authState.user.email;
          profileImageUrl = authState.user.profileImageUrl;
        }

        return BlocBuilder<RestaurantBloc, RestaurantState>(
          builder: (context, restaurantState) {
            if (restaurantState is RestaurantStateLoaded) {
              restaurantName = restaurantState.restaurant.name;
              if (_restaurantId != restaurantState.restaurant.id) {
                _restaurantId = restaurantState.restaurant.id;
              }
            }

            return Scaffold(
              endDrawer: buildRestaurantDrawer(
                name: restaurantName,
                email: restaurantEmail,
                profileImageUrl: profileImageUrl,
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
                      top: 75 * heightScale,
                      left: 141 * widthScale,
                      child: Text(
                        'Add Image',
                        style: TextStyle(
                          color: AppColor.nearWhite,
                          fontSize: 28 * widthScale,
                          fontFamily: 'League Spartan',
                          fontWeight: FontWeight.w700,
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
                      left: 0,
                      right: 0,
                      top: 160 * heightScale,
                      bottom: 0,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 20 * widthScale),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 30 * heightScale),

                            Center(
                              child: GestureDetector(
                                onTap: _isUploading ? null : _pickImage,
                                child: Container(
                                  width: 225 * widthScale,
                                  height: 366 * heightScale,
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(255, 170, 165, 163),
                                    border: Border.all(
                                      color: AppColor.black,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(21),
                                    image: _selectedImage != null
                                        ? DecorationImage(
                                            image: FileImage(_selectedImage!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: _selectedImage == null
                                      ? Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '+',
                                              style: TextStyle(
                                                color: AppColor.textDark,
                                                fontSize: 40 * widthScale,
                                                fontFamily: 'League Spartan',
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            SizedBox(height: 8 * heightScale),
                                            Text(
                                              'add image',
                                              style: TextStyle(
                                                color: AppColor.textDark,
                                                fontSize: 18 * widthScale,
                                                fontFamily: 'League Spartan',
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        )
                                      : null,
                                ),
                              ),
                            ),

                            SizedBox(height: 30 * heightScale),

                            Center(
                              child: GestureDetector(
                                onTap: _isUploading ? null : _handleUpload,
                                child: Container(
                                  width: 157 * widthScale,
                                  height: 38 * heightScale,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _isUploading ? AppColor.gray : AppColor.orange,
                                    border: Border.all(color: AppColor.orange, width: 1),
                                    borderRadius: BorderRadius.circular(51.57),
                                  ),
                                  child: _isUploading
                                      ? SizedBox(
                                          width: 24 * widthScale,
                                          height: 24 * heightScale,
                                          child: const CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          'Upload',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 23 * widthScale,
                                            fontFamily: 'League Spartan',
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                ),
                              ),
                            ),

                            SizedBox(height: 20 * heightScale),
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
                  isRestaurant: true,  // ✅ ADD THIS

              ),
            );
          },
        );
      },
    );
  }
}