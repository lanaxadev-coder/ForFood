// ============================================================
// RESTAURANT DETAIL VIEW — FIXED DRAWER + REAL DATA + RESPONSIVE
// + Fullscreen viewer for gallery AND menu images
// ============================================================

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/bottom_nav_dart.dart';
import 'package:forfood/core/widgets/cart_app_drawer.dart';
import 'package:forfood/core/widgets/network_image_with_shimmer.dart';
import 'package:forfood/core/widgets/skeleton_loader.dart';
import 'package:forfood/core/widgets/star_rating.dart';
import 'package:forfood/core/widgets/detail_menu_item.dart';
import 'package:forfood/core/widgets/drawer_helpers.dart';
import 'package:forfood/core/widgets/rectangle_indicator.dart';
import 'package:forfood/models/menu_item_model.dart';
import 'package:forfood/models/order_model.dart';
import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/cart/cart_bloc.dart';
import 'package:forfood/service/cart/cart_event.dart';
import 'package:forfood/service/database/firestore_provider.dart';
import 'package:forfood/service/menu/menu_bloc.dart';
import 'package:forfood/service/menu/menu_event.dart';
import 'package:forfood/service/menu/menu_state.dart';
import 'package:forfood/service/restaurant/restaurant_bloc.dart';
import 'package:forfood/service/restaurant/restaurant_event.dart';
import 'package:forfood/service/restaurant/restaurant_state.dart';
import 'package:forfood/utilities/haptic_feedback.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/utilities/tab_route.dart';
import 'package:forfood/view/chat_inbox_view.dart';

import 'package:forfood/view/user/home_page.dart';
import 'package:forfood/view/user/my_order_view.dart';
import 'package:forfood/view/user/search_screen.dart';

class RestaurantDetailView extends StatefulWidget {
  final String restaurantName;
  final String restaurantId;

  const RestaurantDetailView({
    super.key,
    required this.restaurantName,
    required this.restaurantId,
  });

  @override
  State<RestaurantDetailView> createState() => _RestaurantDetailViewState();
}

class _RestaurantDetailViewState extends State<RestaurantDetailView> {
  int _currentIndex = 0;
  final Map<String, bool> _selectedItems = {};

  final FirestoreProvider _firestoreProvider = FirestoreProvider();
  StreamSubscription<List<String>>? _gallerySubscription;
  List<String> _galleryImages = [];
  bool _isGalleryLoading = true;

  String _description = '';
  double _rating = 0.0;
  bool _isDeliveryEnabled = true;
  String _profileImageUrl = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showCartDrawer = false;
  final PageController _galleryPageController =
      PageController(viewportFraction: 0.75);
  int _galleryIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchRestaurant();
    _fetchMenu();
    _fetchGallery();
  }

  @override
  void dispose() {
    _gallerySubscription?.cancel();
    _galleryPageController.dispose();
    super.dispose();
  }

  void _fetchRestaurant() {
    if (widget.restaurantId.isNotEmpty) {
      _firestoreProvider.incrementRestaurantViews(widget.restaurantId);
      context.read<RestaurantBloc>().add(
            RestaurantEventFetchById(restaurantId: widget.restaurantId),
          );
    }
  }

  void _fetchMenu() {
    if (widget.restaurantId.isNotEmpty) {
      context.read<MenuBloc>().add(
            MenuEventFetchByRestaurant(restaurantId: widget.restaurantId),
          );
    }
  }

  void _fetchGallery() {
    if (widget.restaurantId.isNotEmpty) {
      _gallerySubscription?.cancel();
      _gallerySubscription = _firestoreProvider
          .streamGalleryImagesByRestaurantId(widget.restaurantId)
          .listen(
        (images) {
          if (mounted) {
            setState(() {
              _galleryImages = images;
              _isGalleryLoading = false;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isGalleryLoading = false;
            });
          }
        },
      );
    } else {
      setState(() {
        _isGalleryLoading = false;
      });
    }
  }

  List<OrderItem> _getSelectedOrderItems(List<MenuItemModel> menuItems) {
    final selectedItems = <OrderItem>[];

    for (final item in menuItems) {
      if (_selectedItems[item.id] == true) {
        selectedItems.add(
          OrderItem(
            menuItemId: item.id,
            name: item.name,
            price: item.price,
            quantity: 1,
            imageUrl: item.imageUrl,
            dateTime: DateTime.now(),
          ),
        );
      }
    }

    return selectedItems;
  }

  void _handleAddToCart(List<MenuItemModel> menuItems) {
    HapticFeedbackUtil.medium();

    final selectedItems = _getSelectedOrderItems(menuItems);

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one item'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    for (final item in selectedItems) {
      context.read<CartBloc>().add(
            CartEventAddItem(
              item: item,
              restaurantId: widget.restaurantId,
              restaurantName: widget.restaurantName,
            ),
          );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${selectedItems.length} item${selectedItems.length == 1 ? '' : 's'} added to cart',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );

    setState(() {
      _selectedItems.clear();
    });
        Navigator.of(context).push(tabRoute(const MyOrdersView()));
  }

  // ✅ Drawer openers (already existed)
  void _openCartDrawer() {
    setState(() => _showCartDrawer = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scaffoldKey.currentState?.openEndDrawer();
    });
  }

  void _openProfileDrawer() {
    setState(() => _showCartDrawer = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scaffoldKey.currentState?.openEndDrawer();
    });
  }

  // ============================================================
  // FULLSCREEN — GALLERY IMAGES
  // ============================================================
  void _openFullscreenImage(int initialIndex) {
    if (_galleryImages.isEmpty) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.95),
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, _, __) => _FullscreenGalleryViewer(
          images: _galleryImages,
          initialIndex: initialIndex,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  // ============================================================
  // FULLSCREEN — MENU IMAGES
  // ============================================================
  void _openMenuImage(MenuItemModel tappedItem, List<MenuItemModel> menuItems) {
    final validItems = menuItems
        .where((i) => i.imageUrl != null && i.imageUrl!.isNotEmpty)
        .toList();

    if (validItems.isEmpty) return;

    final images = validItems.map((i) => i.imageUrl!).toList();
    final initialIndex =
        validItems.indexWhere((i) => i.id == tappedItem.id);

    if (initialIndex == -1) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.95),
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, _, __) => _FullscreenGalleryViewer(
          images: images,
          initialIndex: initialIndex,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  // ✅ Bottom nav uses the right opener for each tab
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

        return BlocBuilder<RestaurantBloc, RestaurantState>(
          builder: (context, restaurantState) {
            if (restaurantState is RestaurantStateLoaded) {
              _description = restaurantState.restaurant.description.isNotEmpty
                  ? restaurantState.restaurant.description
                  : 'Burgers, fries, and milkshakes — fast, fresh, and made to order.';
              _rating = restaurantState.restaurant.rating;
              _isDeliveryEnabled = restaurantState.restaurant.isDeliveryEnabled;
              _profileImageUrl =
                  restaurantState.restaurant.profileImageUrl ?? '';
            }

            return Scaffold(
              key: _scaffoldKey,
              onEndDrawerChanged: (isOpen) {
                if (!isOpen && _showCartDrawer) {
                  setState(() => _showCartDrawer = false);
                }
              },
              endDrawer: _showCartDrawer
                  ? const CartView()
                  : buildUserDrawer(
                      name: userName,
                      email: userEmail,
                      profileImageUrl: profileImageUrl,
                    ),
              body: Container(
                width: screenWidth,
                height: screenHeight,
                color: const Color(0xFFF5CB58),
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
                      left: 70 * widthScale,
                      top: 76 * heightScale,
                      child: Text(
                        widget.restaurantName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColor.textDark,
                          fontSize: 26 * widthScale,
                          fontFamily: 'League Spartan',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Rating badge
                    Positioned(
                      top: 110 * heightScale,
                      left: 70 * widthScale,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8 * widthScale,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColor.orange,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _rating.toStringAsFixed(1),
                              style: TextStyle(
                                color: AppColor.nearWhite,
                                fontSize: 12 * widthScale,
                                fontFamily: 'League Spartan',
                              ),
                            ),
                            SizedBox(width: 2 * widthScale),
                            Icon(
                              Icons.star,
                              color: AppColor.yellow,
                              size: 12 * widthScale,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Delivery badge
                    Positioned(
                      top: 110 * heightScale,
                      right: 20 * widthScale,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10 * widthScale,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _isDeliveryEnabled
                              ? const Color(0xFFB7F8A9)
                              : const Color(0xFFFFE0B2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isDeliveryEnabled
                                  ? Icons.delivery_dining
                                  : Icons.storefront,
                              size: 14 * widthScale,
                              color: AppColor.textDark,
                            ),
                            SizedBox(width: 4 * widthScale),
                            Text(
                              _isDeliveryEnabled
                                  ? 'Delivery Available'
                                  : 'Pickup Only',
                              style: TextStyle(
                                color: AppColor.textDark,
                                fontSize: 11 * widthScale,
                                fontFamily: 'League Spartan',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Content
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 170 * heightScale,
                      bottom: 0,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20 * widthScale,
                            vertical: 16 * heightScale,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  StarRating(rating: _rating.round()),
                                ],
                              ),
                              SizedBox(height: 10 * heightScale),

                              Center(
                                child: NetworkImageWithShimmer(
                                  imageUrl: _profileImageUrl.isNotEmpty
                                      ? _profileImageUrl
                                      : 'https://placehold.co/163x160',
                                  width: 163 * widthScale,
                                  height: 160 * heightScale,
                                  fit: BoxFit.cover,
                                ),
                              ),

                              SizedBox(height: 12 * heightScale),
                              Center(
                                child: Text(
                                  widget.restaurantName,
                                  style: TextStyle(
                                    color: AppColor.textDark,
                                    fontSize: 22 * widthScale,
                                    fontFamily: 'League Spartan',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),

                              SizedBox(height: 20 * heightScale),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Description',
                                    style: TextStyle(
                                      color: AppColor.orange,
                                      fontSize: 24 * widthScale,
                                      fontFamily: 'League Spartan',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 8 * heightScale),
                                  Text(
                                    _description,
                                    style: TextStyle(
                                      color: AppColor.textDark,
                                      fontSize: 13 * widthScale,
                                      fontFamily: 'League Spartan',
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 12 * heightScale),
                              Container(height: 1, color: AppColor.divider),
                              SizedBox(height: 20 * heightScale),

                              Text(
                                'Galery',
                                style: TextStyle(
                                  color: AppColor.orange,
                                  fontSize: 24 * widthScale,
                                  fontFamily: 'League Spartan',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 12 * heightScale),
                              SizedBox(
                                height: 200 * heightScale,
                                child: _isGalleryLoading
                                    ? ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: 3,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 20 * widthScale),
                                        separatorBuilder: (context, index) =>
                                            SizedBox(width: 8 * widthScale),
                                        itemBuilder: (context, index) =>
                                            const GalleryCardSkeleton(),
                                      )
                                    : _galleryImages.isEmpty
                                        ? const Center(
                                            child: Text(
                                              'No gallery images',
                                              style: TextStyle(
                                                color: AppColor.gray,
                                                fontSize: 14,
                                                fontFamily:
                                                    'League Spartan',
                                              ),
                                            ),
                                          )
                                        : PageView.builder(
                                            controller:
                                                _galleryPageController,
                                            itemCount: _galleryImages.length,
                                            onPageChanged: (index) => setState(
                                                () => _galleryIndex = index),
                                            itemBuilder: (context, index) {
                                              return AnimatedPadding(
                                                duration: const Duration(
                                                    milliseconds: 200),
                                                padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      4 * widthScale,
                                                  vertical:
                                                      _galleryIndex == index
                                                          ? 0
                                                          : 12 * heightScale,
                                                ),
                                                child: GestureDetector(
                                                  onTap: () =>
                                                      _openFullscreenImage(
                                                          index),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    child:
                                                        NetworkImageWithShimmer(
                                                      imageUrl:
                                                          _galleryImages[index],
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                      fit: BoxFit.cover,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                              ),
                              SizedBox(height: 8 * heightScale),

                              Center(
                                child: DotsIndicator(
                                  count: _galleryImages.isNotEmpty
                                      ? _galleryImages.length
                                      : 1,
                                  activeIndex: _galleryIndex,
                                ),
                              ),
                              SizedBox(height: 20 * heightScale),

                              Text(
                                'Menu',
                                style: TextStyle(
                                  color: AppColor.orange,
                                  fontSize: 24 * widthScale,
                                  fontFamily: 'League Spartan',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              BlocBuilder<MenuBloc, MenuState>(
                                builder: (context, menuState) {
                                  if (menuState is MenuStateLoading) {
                                    return Column(
                                      children: List.generate(
                                        4,
                                        (index) => Padding(
                                          padding: EdgeInsets.only(
                                              bottom: 10 * heightScale),
                                          child:
                                              const MenuListItemSkeleton(),
                                        ),
                                      ),
                                    );
                                  }

                                  if (menuState is MenuStateLoaded) {
                                    final menuItems = menuState.menuItems;

                                    if (menuItems.isEmpty) {
                                      return Padding(
                                        padding: EdgeInsets.all(
                                            20 * heightScale),
                                        child: Center(
                                          child: Text(
                                            'No menu items available',
                                            style: TextStyle(
                                              color: AppColor.gray,
                                              fontSize: 16 * widthScale,
                                              fontFamily: 'League Spartan',
                                              fontWeight: FontWeight.w300,
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    return Column(
                                      children: [
                                        ...menuItems.map((item) {
                                          return DetailMenuItem(
                                            imageUrl: item.imageUrl ??
                                                'https://placehold.co/80x80',
                                            name: item.name,
                                            price:
                                                '\$${item.price.toStringAsFixed(2)}',
                                            isSelected:
                                                _selectedItems[item.id] ??
                                                    false,
                                            onImageTap: () => _openMenuImage(
                                                item, menuItems),
                                            onBookmark: () {
                                              setState(() {
                                                _selectedItems[item.id] =
                                                    !(_selectedItems[item.id] ??
                                                        false);
                                              });
                                            },
                                          );
                                        }),
                                        SizedBox(height: 20 * heightScale),
                                        Center(
                                          child: GestureDetector(
                                            onTap: () =>
                                                _handleAddToCart(menuItems),
                                            child: Container(
                                              padding:
                                                  EdgeInsets.symmetric(
                                                horizontal: 28 * widthScale,
                                                vertical: 5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColor.orange,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        44.79),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .shopping_bag_outlined,
                                                    color: Colors.white,
                                                    size: 25 * widthScale,
                                                  ),
                                                  SizedBox(
                                                      width: 8 * widthScale),
                                                  Text(
                                                    ' Add to Cart',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize:
                                                          18 * widthScale,
                                                      fontFamily:
                                                          'League Spartan',
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }

                                  if (menuState is MenuStateError) {
                                    return Padding(
                                      padding: EdgeInsets.all(
                                          20 * heightScale),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.error_outline,
                                              color: Colors.red,
                                              size: 50 * widthScale,
                                            ),
                                            SizedBox(
                                                height: 15 * heightScale),
                                            Text(
                                              menuState.message,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 16 * widthScale,
                                                fontFamily:
                                                    'League Spartan',
                                              ),
                                            ),
                                            SizedBox(
                                                height: 15 * heightScale),
                                            GestureDetector(
                                              onTap: () {
                                                _fetchMenu();
                                              },
                                              child: Container(
                                                padding:
                                                    EdgeInsets.symmetric(
                                                  horizontal:
                                                      24 * widthScale,
                                                  vertical:
                                                      10 * heightScale,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColor.orange,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          30),
                                                ),
                                                child: Text(
                                                  'Retry',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                        14 * widthScale,
                                                    fontFamily:
                                                        'League Spartan',
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  return const SizedBox.shrink();
                                },
                              ),

                              SizedBox(height: 20 * heightScale),
                            ],
                          ),
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
      },
    );
  }
}

// ============================================================
// FULLSCREEN VIEWER — used for BOTH gallery and menu images
// ============================================================
class _FullscreenGalleryViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullscreenGalleryViewer({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullscreenGalleryViewer> createState() =>
      _FullscreenGalleryViewerState();
}

class _FullscreenGalleryViewerState extends State<_FullscreenGalleryViewer> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Stack(
          children: [
            // Swipeable fullscreen images
            PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Center(
                      child: CachedNetworkImage(
                      imageUrl: widget.images[index],
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      errorWidget: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.white54,
                          size: 60,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Counter "3 / 12" at top-center
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'League Spartan',
                    ),
                  ),
                ),
              ),
            ),

            // Close button at top-right
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}