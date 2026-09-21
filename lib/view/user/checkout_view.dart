// ============================================================
// CHECKOUT VIEW — UX REDESIGN
// - Real delivery address (from Firestore)
// - Context card under toggle (Pickup shows map, Delivery shows address)
// - Fixed: pickup map link works even if restaurant has delivery off
// - Total shown in Place Order button
// - Haptics on toggle
// - Full-width CTA
// - Success screen after order
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/bottom_nav_dart.dart';
import 'package:forfood/core/widgets/cart_app_drawer.dart';
import 'package:forfood/core/widgets/drawer_helpers.dart';
import 'package:forfood/core/widgets/location_map_view.dart';
import 'package:forfood/core/widgets/notification_drawer.dart';
import 'package:forfood/models/address_model.dart';
import 'package:forfood/models/order_model.dart';
import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/cart/cart_bloc.dart';
import 'package:forfood/service/cart/cart_event.dart';
import 'package:forfood/service/cart/cart_state.dart';
import 'package:forfood/service/database/firestore_provider.dart';
import 'package:forfood/service/order/order_bloc.dart';
import 'package:forfood/service/order/order_event.dart';
import 'package:forfood/service/order/order_state.dart';
import 'package:forfood/service/restaurant/restaurant_bloc.dart';
import 'package:forfood/service/restaurant/restaurant_event.dart';
import 'package:forfood/service/restaurant/restaurant_state.dart';
import 'package:forfood/utilities/haptic_feedback.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/utilities/tab_route.dart';
import 'package:forfood/view/chat_inbox_view.dart';

import 'package:forfood/view/user/add_address_view.dart';
import 'package:forfood/view/user/delivery_adress.dart';
import 'package:forfood/view/user/home_page.dart';
import 'package:forfood/view/user/my_order_view.dart';
import 'package:forfood/view/user/order_confirmed_view.dart';
import 'package:forfood/view/user/search_screen.dart';

class CheckoutView extends StatefulWidget {
  const CheckoutView({super.key});

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  int _currentIndex = 0;

  // ✅ Scaffold key so bottom-nav can open the drawer reliably
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ✅ Which drawer to show
  DrawerType _activeDrawer = DrawerType.profile;

  // Delivery method
  bool _isDelivery = false;              // default to pickup
  bool _userChangedMethod = false;       // if user toggled manually, don't override

  // Restaurant info
  bool _restaurantDelivers = true;
  String _restaurantAddress = '';
  String _restaurantName = '';
  double _restaurantLatitude = 0;
  double _restaurantLongitude = 0;

  // User address
  final FirestoreProvider _firestoreProvider = FirestoreProvider();
  StreamSubscription<List<AddressModel>>? _addressSubscription;
  AddressModel? _defaultAddress;
  bool _addressLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRestaurant();
      _loadAddresses();
    });
  }

  @override
  void dispose() {
    _addressSubscription?.cancel();
    super.dispose();
  }

  // ============================================================
  // DRAWER OPENERS
  // ============================================================
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

  // ============================================================
  // DATA LOADING
  // ============================================================

  void _fetchRestaurant() {
    final cartState = context.read<CartBloc>().state;
    if (cartState is CartStateLoaded) {
      context.read<RestaurantBloc>().add(
            RestaurantEventFetchById(restaurantId: cartState.restaurantId),
          );
    }
  }

  void _loadAddresses() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthStateLoggedIn) {
      setState(() => _addressLoading = false);
      return;
    }

    _addressSubscription?.cancel();
    _addressSubscription = _firestoreProvider
        .streamAddressesByUserId(authState.user.id)
        .listen(
      (addresses) {
        if (!mounted) return;
        setState(() {
          _addressLoading = false;
          if (addresses.isEmpty) {
            _defaultAddress = null;
          } else {
            _defaultAddress = addresses.firstWhere(
              (a) => a.isDefault,
              orElse: () => addresses.first,
            );
          }
        });
      },
      onError: (_) {
        if (mounted) setState(() => _addressLoading = false);
      },
    );
  }

  // ============================================================
  // TOGGLE HANDLERS
  // ============================================================

  void _selectPickup() {
    HapticFeedbackUtil.light();
    setState(() {
      _isDelivery = false;
      _userChangedMethod = true;
    });
  }

  void _selectDelivery() {
    if (!_restaurantDelivers) return;
    HapticFeedbackUtil.light();
    setState(() {
      _isDelivery = true;
      _userChangedMethod = true;
    });
  }

  // ============================================================
  // ORDER BUILDING
  // ============================================================

  OrderModel? _buildOrder(
    CartStateLoaded cartState,
    AuthStateLoggedIn authState,
  ) {
    if (cartState.items.isEmpty) return null;

    return OrderModel(
      id: '',
      userId: authState.user.id,
      restaurantId: cartState.restaurantId,
      restaurantName: cartState.restaurantName,
      items: cartState.items,
      total: cartState.total,
      status: OrderStatus.pending,
      deliveryMethod:
          _isDelivery ? DeliveryMethod.delivery : DeliveryMethod.pickup,
      paymentMethod: PaymentMethod.cashOnDelivery,
      deliveryAddress:
          _isDelivery ? _defaultAddress?.fullAddress : null,
      customerName: authState.user.fullName,
      customerPhone: authState.user.phoneNumber,
      customerEmail: authState.user.email,
      createdAt: DateTime.now(),
    );
  }

  void _handlePlaceOrder() {
    final cartState = context.read<CartBloc>().state;
    final authState = context.read<AuthBloc>().state;

    if (cartState is! CartStateLoaded) {
      _snack('Your cart is empty');
      return;
    }

    if (authState is! AuthStateLoggedIn) {
      _snack('Please log in to place an order');
      return;
    }

    // Block delivery with no address
    if (_isDelivery && _defaultAddress == null) {
      HapticFeedbackUtil.heavy();
      _snack('Please add a delivery address first');
      return;
    }

    final order = _buildOrder(cartState, authState);
    if (order == null) {
      _snack('Your cart is empty');
      return;
    }

    HapticFeedbackUtil.medium();
    context.read<OrderBloc>().add(OrderEventPlaceOrder(order: order));
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ============================================================
  // NAVIGATION HELPERS
  // ============================================================

  void _openRestaurantMap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LocationMapView(
          title: 'Restaurant Location',
          destinationName: _restaurantName,
          destinationAddress: _restaurantAddress,
          destinationLatitude: _restaurantLatitude,
          destinationLongitude: _restaurantLongitude,
        ),
      ),
    );
  }

  void _openAddressPicker() {
    Navigator.of(context).push(
      fadeSlideRoute(const DeliveryAddressView()),
    );
  }

  void _openAddAddress() {
    Navigator.of(context).push(
      fadeSlideRoute(const AddAddressView()),
    );
  }

  // ✅ Bottom nav now opens the CORRECT drawer via the scaffold key
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

        _openCartDrawer();
        break;
      case 4:
            setState(() => _currentIndex = index);   // ✅ highlight

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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final widthScale = screenWidth / 393;
    final heightScale = screenHeight / 852;

    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is OrderStateSuccess) {
          final placedOrder = state.order;
          context.read<CartBloc>().add(const CartEventClear());

          if (placedOrder != null) {
            Navigator.pushReplacement(
              context,
              fadeSlideRoute(
                OrderConfirmedView(
                  order: placedOrder,
                  isDelivery: _isDelivery,
                  restaurantName: _restaurantName,
                ),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              fadeSlideRoute(const MyOrdersView()),
            );
          }
        } else if (state is OrderStateError) {
          _snack(state.message);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
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
                _restaurantDelivers =
                    restaurantState.restaurant.isDeliveryEnabled;
                _restaurantAddress = restaurantState.restaurant.address;
                _restaurantName = restaurantState.restaurant.name;
                _restaurantLatitude = restaurantState.restaurant.latitude;
                _restaurantLongitude = restaurantState.restaurant.longitude;

                if (!_restaurantDelivers && _isDelivery) {
                  _isDelivery = false;
                }
              }

              return Scaffold(
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
                  color: const Color(0xFFF5CB58),
                  child: Stack(
                    children: [
                      // White bottom section
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

                      // Back arrow
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

                      // Title
                      Positioned(
                        left: 130 * widthScale,
                        top: 76 * heightScale,
                        child: Text(
                          'Checkout',
                          style: TextStyle(
                            color: AppColor.nearWhite,
                            fontSize: 30 * widthScale,
                            fontFamily: 'League Spartan',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // Content
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 200 * heightScale,
                        bottom: 0,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: 25 * widthScale,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 8 * heightScale),

                              // ─────────────────────────────────────
                              // ORDER SUMMARY
                              // ─────────────────────────────────────
                              _sectionTitle('Order Summary', widthScale),

                              SizedBox(height: 16 * heightScale),

                              BlocBuilder<CartBloc, CartState>(
                                builder: (context, state) {
                                  if (state is! CartStateLoaded) {
                                    return _emptyCart(widthScale);
                                  }
                                  return Column(
                                    children: [
                                      ...state.items.map((item) {
                                        return _orderItemRow(
                                          name: item.name,
                                          qty: item.quantity,
                                          price: '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                                          widthScale: widthScale,
                                          heightScale: heightScale,
                                        );
                                      }),
                                      SizedBox(height: 20 * heightScale),
                                      Container(
                                          height: 1, color: AppColor.divider),
                                      SizedBox(height: 16 * heightScale),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Total',
                                            style: TextStyle(
                                              color: AppColor.textDark,
                                              fontSize: 20 * widthScale,
                                              fontFamily: 'League Spartan',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            '\$${state.total.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: AppColor.orange,
                                              fontSize: 20 * widthScale,
                                              fontFamily: 'League Spartan',
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),

                              SizedBox(height: 30 * heightScale),

                              // ─────────────────────────────────────
                              // DELIVERY METHOD
                              // ─────────────────────────────────────
                              _sectionTitle('How do you want it?', widthScale),

                              SizedBox(height: 16 * heightScale),

                              // Toggle row
                              Row(
                                children: [
                                  Expanded(
                                    child: _methodButton(
                                      label: 'Pickup',
                                      icon: Icons.storefront_outlined,
                                      isSelected: !_isDelivery,
                                      onTap: _selectPickup,
                                      widthScale: widthScale,
                                    ),
                                  ),
                                  SizedBox(width: 10 * widthScale),
                                  Expanded(
                                    child: _methodButton(
                                      label: _restaurantDelivers
                                          ? 'Delivery'
                                          : 'Pickup only',
                                      icon: _restaurantDelivers
                                          ? Icons.delivery_dining_outlined
                                          : Icons.block_outlined,
                                      isSelected:
                                          _isDelivery && _restaurantDelivers,
                                      onTap: _restaurantDelivers
                                          ? _selectDelivery
                                          : null,
                                      widthScale: widthScale,
                                      disabled: !_restaurantDelivers,
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 16 * heightScale),

                              // ─────────────────────────────────────
                              // CONTEXT CARD — changes based on selection
                              // ─────────────────────────────────────
                              _contextCard(widthScale, heightScale),

                              SizedBox(height: 30 * heightScale),

                              // ─────────────────────────────────────
                              // PLACE ORDER BUTTON (full-width with total)
                              // ─────────────────────────────────────
                              BlocBuilder<CartBloc, CartState>(
                                builder: (context, cartState) {
                                  final total = cartState is CartStateLoaded
                                      ? cartState.total
                                      : 0.0;

                                  return BlocBuilder<OrderBloc, OrderState>(
                                    builder: (context, orderState) {
                                      final isLoading =
                                          orderState is OrderStateLoading;

                                      return _placeOrderButton(
                                        total: total,
                                        isLoading: isLoading,
                                        onTap: _handlePlaceOrder,
                                        widthScale: widthScale,
                                        heightScale: heightScale,
                                      );
                                    },
                                  );
                                },
                              ),

                              SizedBox(height: 24 * heightScale),
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
        },
      ),
    );
  }

  // ============================================================
  // WIDGET BUILDERS
  // ============================================================

  Widget _sectionTitle(String text, double widthScale) {
    return Text(
      text,
      style: TextStyle(
        color: AppColor.textDark,
        fontSize: 20 * widthScale,
        fontFamily: 'League Spartan',
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _emptyCart(double widthScale) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 40 * widthScale),
      child: Center(
        child: Text(
          'Your cart is empty',
          style: TextStyle(
            color: AppColor.gray,
            fontSize: 16 * widthScale,
            fontFamily: 'League Spartan',
          ),
        ),
      ),
    );
  }

  Widget _orderItemRow({
    required String name,
    required int qty,
    required String price,
    required double widthScale,
    required double heightScale,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12 * heightScale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColor.textDark,
                fontSize: 15 * widthScale,
                fontFamily: 'League Spartan',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 8 * widthScale),
          Text(
            'x$qty',
            style: TextStyle(
              color: AppColor.gray,
              fontSize: 13 * widthScale,
              fontFamily: 'League Spartan',
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(width: 16 * widthScale),
          Text(
            price,
            style: TextStyle(
              color: AppColor.textDark,
              fontSize: 15 * widthScale,
              fontFamily: 'League Spartan',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Method toggle button (Pickup / Delivery)
  Widget _methodButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback? onTap,
    required double widthScale,
    bool disabled = false,
  }) {
    final bg = disabled
        ? AppColor.gray.withOpacity(0.3)
        : isSelected
            ? AppColor.orange
            : const Color(0xFFFFDECF);

    final fg = disabled
        ? AppColor.gray
        : isSelected
            ? Colors.white
            : AppColor.orange;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(vertical: 14 * widthScale),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg, size: 18 * widthScale),
            SizedBox(width: 6 * widthScale),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 15 * widthScale,
                fontFamily: 'League Spartan',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // The context card that changes with the toggle
  Widget _contextCard(double widthScale, double heightScale) {
    if (_isDelivery) {
      return _buildDeliveryCard(widthScale, heightScale);
    }
    return _buildPickupCard(widthScale, heightScale);
  }

  // Pickup card — shows restaurant address + Get Directions
  Widget _buildPickupCard(double widthScale, double heightScale) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * widthScale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20 * widthScale),
        border: Border.all(color: AppColor.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront, color: AppColor.orange,
                  size: 22 * widthScale),
              SizedBox(width: 8 * widthScale),
              Expanded(
                child: Text(
                  'Pickup from',
                  style: TextStyle(
                    color: AppColor.gray,
                    fontSize: 13 * widthScale,
                    fontFamily: 'League Spartan',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8 * widthScale,
                  vertical: 3 * widthScale,
                ),
                decoration: BoxDecoration(
                  color: AppColor.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Ready in ~20 min',
                  style: TextStyle(
                    color: AppColor.orange,
                    fontSize: 11 * widthScale,
                    fontFamily: 'League Spartan',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8 * heightScale),
          Padding(
            padding: EdgeInsets.only(left: 30 * widthScale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _restaurantName.isEmpty ? 'Restaurant' : _restaurantName,
                  style: TextStyle(
                    color: AppColor.textDark,
                    fontSize: 16 * widthScale,
                    fontFamily: 'League Spartan',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_restaurantAddress.isNotEmpty) ...[
                  SizedBox(height: 2 * heightScale),
                  Text(
                    _restaurantAddress,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColor.textDark.withOpacity(0.7),
                      fontSize: 13 * widthScale,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 14 * heightScale),
          GestureDetector(
            onTap: _openRestaurantMap,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 10 * heightScale),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDECF),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined,
                      color: AppColor.orange, size: 18 * widthScale),
                  SizedBox(width: 6 * widthScale),
                  Text(
                    'Get Directions',
                    style: TextStyle(
                      color: AppColor.orange,
                      fontSize: 14 * widthScale,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Delivery card — shows user address + Change + Cash on Delivery
  Widget _buildDeliveryCard(double widthScale, double heightScale) {
    final hasAddress = _defaultAddress != null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * widthScale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20 * widthScale),
        border: Border.all(color: AppColor.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.delivery_dining, color: AppColor.orange,
                  size: 22 * widthScale),
              SizedBox(width: 8 * widthScale),
              Expanded(
                child: Text(
                  'Deliver to',
                  style: TextStyle(
                    color: AppColor.gray,
                    fontSize: 13 * widthScale,
                    fontFamily: 'League Spartan',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8 * widthScale,
                  vertical: 3 * widthScale,
                ),
                decoration: BoxDecoration(
                  color: AppColor.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '~35 min',
                  style: TextStyle(
                    color: AppColor.orange,
                    fontSize: 11 * widthScale,
                    fontFamily: 'League Spartan',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8 * heightScale),

          if (_addressLoading)
            Padding(
              padding: EdgeInsets.only(left: 30 * widthScale),
              child: SizedBox(
                width: 16 * widthScale,
                height: 16 * widthScale,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColor.orange,
                ),
              ),
            )
          else if (hasAddress)
            Padding(
              padding: EdgeInsets.only(left: 30 * widthScale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _defaultAddress!.label,
                    style: TextStyle(
                      color: AppColor.textDark,
                      fontSize: 15 * widthScale,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2 * heightScale),
                  Text(
                    _defaultAddress!.fullAddress,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColor.textDark.withOpacity(0.7),
                      fontSize: 13 * widthScale,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: EdgeInsets.only(left: 30 * widthScale),
              child: Text(
                'No address saved yet',
                style: TextStyle(
                  color: AppColor.red,
                  fontSize: 14 * widthScale,
                  fontFamily: 'League Spartan',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          SizedBox(height: 14 * heightScale),

          // Change / Add address
          GestureDetector(
            onTap: hasAddress ? _openAddressPicker : _openAddAddress,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 10 * heightScale),
              decoration: BoxDecoration(
                color: hasAddress
                    ? const Color(0xFFFFDECF)
                    : AppColor.orange,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasAddress ? Icons.edit_outlined : Icons.add,
                    color: hasAddress ? AppColor.orange : Colors.white,
                    size: 18 * widthScale,
                  ),
                  SizedBox(width: 6 * widthScale),
                  Text(
                    hasAddress ? 'Change address' : 'Add an address',
                    style: TextStyle(
                      color: hasAddress ? AppColor.orange : Colors.white,
                      fontSize: 14 * widthScale,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 12 * heightScale),

          // Payment info
          Padding(
            padding: EdgeInsets.only(left: 4 * widthScale),
            child: Row(
              children: [
                Icon(Icons.money,
                    color: AppColor.orange, size: 16 * widthScale),
                SizedBox(width: 6 * widthScale),
                Text(
                  'Cash on Delivery',
                  style: TextStyle(
                    color: AppColor.textDark.withOpacity(0.7),
                    fontSize: 13 * widthScale,
                    fontFamily: 'League Spartan',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Full-width Place Order button with total
  Widget _placeOrderButton({
    required double total,
    required bool isLoading,
    required VoidCallback onTap,
    required double widthScale,
    required double heightScale,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16 * heightScale),
        decoration: BoxDecoration(
          color: isLoading ? AppColor.gray : AppColor.orange,
          borderRadius: BorderRadius.circular(50),
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 22 * widthScale,
                  height: 22 * widthScale,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Place Order',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17 * widthScale,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8 * widthScale),
                  Text(
                    '•',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 17 * widthScale,
                    ),
                  ),
                  SizedBox(width: 8 * widthScale),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17 * widthScale,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}