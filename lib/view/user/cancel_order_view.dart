// ============================================================
// CANCEL ORDER VIEW
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/bottom_nav_dart.dart';
import 'package:forfood/core/widgets/cart_app_drawer.dart';
import 'package:forfood/core/widgets/drawer_helpers.dart';
import 'package:forfood/core/widgets/notification_drawer.dart';

import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/order/order_bloc.dart';
import 'package:forfood/service/order/order_event.dart';
import 'package:forfood/service/order/order_state.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/utilities/tab_route.dart';
import 'package:forfood/view/chat_inbox_view.dart';
import 'package:forfood/view/user/my_order_view.dart';

import 'package:forfood/view/user/order_cancelled_mssg_view.dart';
import 'package:forfood/view/user/home_page.dart';
import 'package:forfood/view/user/search_screen.dart';

class CancelOrderView extends StatefulWidget {
  final String orderId;

  const CancelOrderView({super.key, required this.orderId});

  @override
  State<CancelOrderView> createState() => _CancelOrderViewState();
}

class _CancelOrderViewState extends State<CancelOrderView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 3;
  bool _isSubmitting = false;

  // ✅ Which drawer to show
  DrawerType _activeDrawer = DrawerType.profile;

  final List<String> _reasons = [
    'Changed my mind',
    'Ordered by mistake',
    'Taking too long',
    'Found a better option',
    'Others',
  ];
  int? _selectedIndex;
  final TextEditingController _otherReasonController =
      TextEditingController();

  @override
  void dispose() {
    _otherReasonController.dispose();
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

  void _handleSubmit() {
    if (_selectedIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason')),
      );
      return;
    }

    String reason = _reasons[_selectedIndex!];
    if (_selectedIndex == _reasons.length - 1) {
      final customReason = _otherReasonController.text.trim();
      if (customReason.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your reason')),
        );
        return;
      }
      reason = customReason;
    }

    setState(() => _isSubmitting = true);

    context.read<OrderBloc>().add(
          OrderEventCancelOrder(
            orderId: widget.orderId,
            reason: reason,
          ),
        );
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

    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is OrderStateSuccess) {
          setState(() => _isSubmitting = false);
          Navigator.pushReplacement(
            context,
            fadeSlideRoute(const OrderCancelledView()),
          );
        } else if (state is OrderStateError) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
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
                      left: 116 * widthScale,
                      top: 76 * heightScale,
                      child: Text(
                        'Cancel Order',
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
                          SizedBox(height: 40 * heightScale),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 35 * widthScale),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 20 * heightScale),
                                  ...List.generate(_reasons.length, (index) {
                                    return Column(
                                      children: [
                                        Container(
                                            height: 1,
                                            color: AppColor.divider),
                                        GestureDetector(
                                          onTap: () => setState(
                                              () => _selectedIndex = index),
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 16 * heightScale),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  _reasons[index],
                                                  style: TextStyle(
                                                    color:
                                                        AppColor.textDark,
                                                    fontSize:
                                                        15 * widthScale,
                                                    fontFamily:
                                                        'League Spartan',
                                                  ),
                                                ),
                                                Icon(
                                                  _selectedIndex == index
                                                      ? Icons
                                                          .radio_button_checked
                                                      : Icons
                                                          .radio_button_off,
                                                  color: AppColor.orange,
                                                  size: 20 * widthScale,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                  if (_selectedIndex ==
                                      _reasons.length - 1) ...[
                                    SizedBox(height: 12 * heightScale),
                                    Container(
                                      height: 100 * heightScale,
                                      padding:
                                          EdgeInsets.all(16 * widthScale),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3E9B5),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: TextField(
                                        controller: _otherReasonController,
                                        maxLines: null,
                                        decoration: InputDecoration(
                                          hintText: 'Others reason...',
                                          hintStyle: TextStyle(
                                            color: AppColor.gray,
                                            fontSize: 14 * widthScale,
                                            fontFamily: 'League Spartan',
                                          ),
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                  ],
                                  SizedBox(height: 40 * heightScale),
                                  Center(
                                    child: GestureDetector(
                                      onTap: _isSubmitting
                                          ? null
                                          : _handleSubmit,
                                      child: Container(
                                        width: 142 * widthScale,
                                        padding: EdgeInsets.symmetric(
                                            vertical: 10 * heightScale),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: _isSubmitting
                                              ? AppColor.gray
                                              : AppColor.orange,
                                          borderRadius:
                                              BorderRadius.circular(100),
                                        ),
                                        child: _isSubmitting
                                            ? SizedBox(
                                                width: 24 * widthScale,
                                                height: 24 * heightScale,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : Text(
                                                'Submit',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize:
                                                      17 * widthScale,
                                                  fontFamily:
                                                      'League Spartan',
                                                  fontWeight:
                                                      FontWeight.w600,
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
      ),
    );
  }
}