// ============================================================
// GALLERY LIST VIEW — PRODUCTION READY
// Fixed: Restaurant ID + Bottom Nav + Refresh + Error + Empty + Shimmer
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/bottom_nav_dart.dart';
import 'package:forfood/core/widgets/drawer_helpers.dart';
import 'package:forfood/core/widgets/skeleton_loader.dart';

import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/database/firestore_provider.dart';
import 'package:forfood/service/restaurant/restaurant_bloc.dart';
import 'package:forfood/service/restaurant/restaurant_event.dart';
import 'package:forfood/service/restaurant/restaurant_state.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/view/chat_inbox_view.dart';

import 'package:forfood/view/restaurant/add_pic_to_galery.dart';
import 'package:forfood/view/restaurant/home_page.dart';
import 'package:forfood/view/restaurant/incoming_order.dart';
import 'package:forfood/view/restaurant/menu.dart';
import 'package:forfood/view/restaurant/profile.dart';

class GalleryListView extends StatefulWidget {
  const GalleryListView({super.key});

  @override
  State<GalleryListView> createState() => _GalleryListViewState();
}

class _GalleryListViewState extends State<GalleryListView> {
  int _currentIndex = 0;
  final FirestoreProvider _firestoreProvider = FirestoreProvider();
  StreamSubscription<List<String>>? _gallerySubscription;
  List<String> _galleryImages = [];
  bool _isLoading = true;
  String? _error;
  String? _restaurantId;

  @override
  void initState() {
    super.initState();
    _fetchRestaurantAndGallery();
  }

  @override
  void dispose() {
    _gallerySubscription?.cancel();
    super.dispose();
  }

  void _fetchRestaurantAndGallery() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthStateLoggedIn) {
      context.read<RestaurantBloc>().add(
            RestaurantEventFetchByOwnerId(ownerId: authState.user.id),
          );
    }
  }

  void _fetchGallery(String restaurantId) {
    _gallerySubscription?.cancel();
    _gallerySubscription = _firestoreProvider
        .streamGalleryImagesByRestaurantId(restaurantId)
        .listen(
      (images) {
        if (mounted) {
          setState(() {
            _galleryImages = images;
            _isLoading = false;
            _error = null;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = error.toString();
          });
        }
      },
    );
  }

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
                _fetchGallery(_restaurantId!);
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
                        'Galery',
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
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: 20 * widthScale,
                          left: 20 * widthScale,
                          top: 30 * heightScale,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                   fadeSlideRoute( const AddGalleryImageView(),
                                    ),
                                  );
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Add',
                                      style: TextStyle(
                                        color: AppColor.orange,
                                        fontFamily: 'League Spartan',
                                        fontSize: 18 * widthScale,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 8 * widthScale),
                                    SvgPicture.asset(
                                      'assets/icons/AddDocumenticon.svg',
                                      width: 20 * widthScale,
                                      height: 20 * heightScale,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: 20 * heightScale),

                            Text(
                              'Galery',
                              style: TextStyle(
                                color: AppColor.black,
                                fontSize: 20 * widthScale,
                                fontFamily: 'League Spartan',
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            SizedBox(height: 20 * heightScale),

                            Expanded(
                              child: _isLoading
                                  ? GridView.builder(
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 12 * widthScale,
                                        mainAxisSpacing: 12 * heightScale,
                                        childAspectRatio: 175 / 222,
                                      ),
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: 4,
                                      itemBuilder: (context, index) =>
                                          const GalleryCardSkeleton(),
                                    )
                                  : _error != null
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.error_outline,
                                                color: Colors.red,
                                                size: 60 * widthScale,
                                              ),
                                              SizedBox(height: 20 * heightScale),
                                              Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 40 * widthScale),
                                                child: Text(
                                                  _error!,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 16 * widthScale,
                                                    fontFamily: 'League Spartan',
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 20 * heightScale),
                                              GestureDetector(
                                                onTap: () {
                                                  if (_restaurantId != null) {
                                                    _fetchGallery(_restaurantId!);
                                                  }
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 24 * widthScale,
                                                    vertical: 10 * heightScale,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppColor.orange,
                                                    borderRadius: BorderRadius.circular(30),
                                                  ),
                                                  child: Text(
                                                    'Retry',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16 * widthScale,
                                                      fontFamily: 'League Spartan',
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : _galleryImages.isEmpty
                                          ? Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.photo_library,
                                                    color: AppColor.orange,
                                                    size: 60 * widthScale,
                                                  ),
                                                  SizedBox(height: 20 * heightScale),
                                                  Text(
                                                    'No images yet',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: AppColor.textDark,
                                                      fontSize: 20 * widthScale,
                                                      fontFamily: 'League Spartan',
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                  SizedBox(height: 8 * heightScale),
                                                  Text(
                                                    'Upload photos of your food to attract customers',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: AppColor.gray,
                                                      fontSize: 14 * widthScale,
                                                      fontFamily: 'League Spartan',
                                                      fontWeight: FontWeight.w300,
                                                    ),
                                                  ),
                                                  SizedBox(height: 20 * heightScale),
                                                  GestureDetector(
                                                    onTap: () {
                                                      Navigator.of(context).push(
                                                      fadeSlideRoute( const AddGalleryImageView(),
                                                        ),
                                                      );
                                                    },
                                                    child: Container(
                                                      padding: EdgeInsets.symmetric(
                                                        horizontal: 24 * widthScale,
                                                        vertical: 10 * heightScale,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: AppColor.orange,
                                                        borderRadius: BorderRadius.circular(30),
                                                      ),
                                                      child: Text(
                                                        'Upload Image',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16 * widthScale,
                                                          fontFamily: 'League Spartan',
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : RefreshIndicator(
                                              color: AppColor.orange,
                                              onRefresh: () async {
                                                if (_restaurantId != null) {
                                                  _fetchGallery(_restaurantId!);
                                                }
                                                await Future.delayed(const Duration(milliseconds: 500));
                                              },
                                              child: GridView.builder(
                                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: 2,
                                                  crossAxisSpacing: 12 * widthScale,
                                                  mainAxisSpacing: 12 * heightScale,
                                                  childAspectRatio: 0.6,
                                                ),
                                                physics: const AlwaysScrollableScrollPhysics(),
                                                itemCount: _galleryImages.length,
                                                itemBuilder: (context, index) {
                                                  return GestureDetector(
                                                    onTap: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) => Dialog(
                                                          backgroundColor: Colors.transparent,
                                                          child: Stack(
                                                            children: [
                                                              ClipRRect(
                                                                  borderRadius: BorderRadius.zero,              // ← change to zero (or remove ClipRRect)

                                                                child: Image.network(

                                                                  _galleryImages[index],
                                                                  fit: BoxFit.contain,
                                                                  errorBuilder: (_, __, ___) => Container(
                                                                    color: const Color(0xFFFFDECF),
                                                                    child: const Icon(
                                                                      Icons.image,
                                                                      color: AppColor.orange,
                                                                      size: 60,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              Positioned(
                                                                top: 10,
                                                                right: 10,
                                                                child: GestureDetector(
                                                                  onTap: () => Navigator.pop(context),
                                                                  child: Container(
                                                                    padding: const EdgeInsets.all(8),
                                                                    decoration: const BoxDecoration(
                                                                      color: Colors.black54,
                                                                      shape: BoxShape.circle,
                                                                    ),
                                                                    child: const Icon(
                                                                      Icons.close,
                                                                      color: Colors.white,
                                                                      size: 20,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(5),
                                                      ),
                                                      child: ClipRRect(
                                                        borderRadius: BorderRadius.circular(5),
                                                        child: Image.network(
                                                          _galleryImages[index],
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (_, __, ___) => Container(
                                                            color: const Color(0xFFFFDECF),
                                                            child: const Icon(
                                                              Icons.image,
                                                              color: AppColor.orange,
                                                              size: 40,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
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