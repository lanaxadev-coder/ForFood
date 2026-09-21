import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/bottom_nav_dart.dart';
import 'package:forfood/core/widgets/cart_app_drawer.dart';
import 'package:forfood/core/widgets/drawer_helpers.dart';
import 'package:forfood/core/widgets/notification_drawer.dart';
import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/utilities/tab_route.dart';
import 'package:forfood/view/chat_inbox_view.dart';
import 'package:forfood/view/user/home_page.dart';
import 'package:forfood/view/user/search_screen.dart';

class SupportView extends StatefulWidget {
  const SupportView({super.key});

  @override
  State<SupportView> createState() => _SupportViewState();
}

class _SupportViewState extends State<SupportView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 4;
  bool _showFaq = true;
  final TextEditingController _searchController = TextEditingController();

  // ✅ Which drawer to show
  DrawerType _activeDrawer = DrawerType.profile;

  final List<Map<String, String>> _faqs = [
    {
      'question': 'Can restaurants pay to appear on the home screen?',
      'answer':
          'Yes! Restaurants can subscribe to our premium plan to appear in the "Recommended" section on the home screen.',
    },
    {
      'question': 'How is the cheapest match calculated?',
      'answer':
          'ForFood ranks restaurants by price first, then by distance, and finally by rating.',
    },
    {
      'question': 'How do I cancel an order?',
      'answer': 'Go to "My Orders" → "Active" tab → Tap "Cancel Order".',
    },
    {
      'question': 'How do I pay for my order?',
      'answer': 'Currently, ForFood supports Cash on Delivery (COD) only.',
    },
    {
      'question': 'How do I change my delivery address?',
      'answer':
          'Go to "Delivery Address" from the menu → Select "Add New Address".',
    },
    {
      'question': 'Can I track my order?',
      'answer':
          'Yes! Go to "My Orders" → "Active" tab to see your order status.',
    },
    {
      'question': 'How do I leave a review?',
      'answer':
          'After delivery, go to "My Orders" → "Completed" → Tap "Leave a review".',
    },
    {
      'question': 'How do I contact a restaurant directly?',
      'answer':
          'Open the restaurant detail page → Tap "See in Map" for directions.',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
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

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@forfood.com',
      query: 'subject=Support Request',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open email client')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open email: $e')),
        );
      }
    }
  }

  List<Map<String, String>> get _filteredFaqs {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return _faqs;
    return _faqs
        .where((faq) =>
            faq['question']!.toLowerCase().contains(query) ||
            faq['answer']!.toLowerCase().contains(query))
        .toList();
  }

  void _showAnswer(Map<String, String> faq) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColor.nearWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          faq['question']!,
          style: const TextStyle(
            color: AppColor.orange,
            fontSize: 18,
            fontFamily: 'League Spartan',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          faq['answer']!,
          style: const TextStyle(
            color: AppColor.textDark,
            fontSize: 15,
            fontFamily: 'League Spartan',
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(
                color: AppColor.orange,
                fontFamily: 'League Spartan',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
        _openCartDrawer();
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
                      color: Color.fromARGB(255, 243, 240, 240),
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
                  left: 130 * widthScale,
                  top: 60 * heightScale,
                  child: Text(
                    _showFaq ? 'Help & FAQs' : 'Contact Us',
                    style: TextStyle(
                      color: AppColor.nearWhite,
                      fontSize: 32 * widthScale,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Positioned(
                  left: 115 * widthScale,
                  top: 110 * heightScale,
                  child: Text(
                    'How Can We Help You ?',
                    style: TextStyle(
                      color: AppColor.orange,
                      fontSize: 18 * widthScale,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 195 * heightScale,
                  bottom: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _showFaq = true),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 70 * widthScale,
                                  vertical: 5 * heightScale,
                                ),
                                decoration: BoxDecoration(
                                  color: _showFaq
                                      ? AppColor.orange
                                      : const Color(0xFFFFDECF),
                                  borderRadius: BorderRadius.circular(38),
                                ),
                                child: Text(
                                  'FAQ',
                                  style: TextStyle(
                                    color: _showFaq
                                        ? AppColor.white
                                        : AppColor.orange,
                                    fontFamily: 'League Spartan',
                                    fontSize: 14 * widthScale,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10 * widthScale),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _showFaq = false),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 50 * widthScale,
                                  vertical: 5 * heightScale,
                                ),
                                decoration: BoxDecoration(
                                  color: !_showFaq
                                      ? AppColor.orange
                                      : const Color(0xFFFFDECF),
                                  borderRadius: BorderRadius.circular(38),
                                ),
                                child: Text(
                                  'Contact Us',
                                  style: TextStyle(
                                    color: !_showFaq
                                        ? AppColor.white
                                        : AppColor.orange,
                                    fontFamily: 'League Spartan',
                                    fontSize: 14 * widthScale,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20 * heightScale),
                      Expanded(
                        child: _showFaq
                            ? Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 35 * widthScale),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 42 * heightScale,
                                      decoration: BoxDecoration(
                                        color: AppColor.white,
                                        borderRadius:
                                            BorderRadius.circular(48),
                                      ),
                                      child: TextField(
                                        controller: _searchController,
                                        onChanged: (_) => setState(() {}),
                                        decoration: InputDecoration(
                                          hintText: 'Search',
                                          hintStyle: TextStyle(
                                              color: AppColor.gray),
                                          border: InputBorder.none,
                                          contentPadding:
                                              EdgeInsets.symmetric(
                                            horizontal: 20 * widthScale,
                                            vertical: 10 * heightScale,
                                          ),
                                          suffixIcon: Padding(
                                            padding: EdgeInsets.all(
                                                7 * widthScale),
                                            child: SvgPicture.asset(
                                              'assets/icons/searchFilter.svg',
                                              width: 20 * widthScale,
                                              height: 20 * heightScale,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 20 * heightScale),
                                    Expanded(
                                      child: _filteredFaqs.isEmpty
                                          ? Center(
                                              child: Text(
                                                'No results found',
                                                style: TextStyle(
                                                  color: AppColor.gray,
                                                  fontSize:
                                                      16 * widthScale,
                                                  fontFamily:
                                                      'League Spartan',
                                                ),
                                              ),
                                            )
                                          : ListView.builder(
                                              itemCount:
                                                  _filteredFaqs.length,
                                              itemBuilder:
                                                  (context, index) =>
                                                      Column(
                                                children: [
                                                  Container(
                                                      height: 1,
                                                      color: AppColor
                                                          .divider),
                                                  ListTile(
                                                    contentPadding:
                                                        EdgeInsets.only(
                                                      top: 5 * heightScale,
                                                      bottom:
                                                          5 * heightScale,
                                                    ),
                                                    title: Text(
                                                      _filteredFaqs[
                                                              index]
                                                          ['question']!,
                                                      style: TextStyle(
                                                        color: AppColor
                                                            .orange,
                                                        fontSize:
                                                            18 * widthScale,
                                                        fontFamily:
                                                            'League Spartan',
                                                        fontWeight:
                                                            FontWeight
                                                                .w500,
                                                      ),
                                                    ),
                                                    trailing:
                                                        Transform.rotate(
                                                      angle:
                                                          math.pi / 2,
                                                      child:
                                                          Image.asset(
                                                        'assets/icons/BackiconArrow.png',
                                                        height:
                                                            15 * heightScale,
                                                        width:
                                                            15 * widthScale,
                                                        fit: BoxFit
                                                            .contain,
                                                      ),
                                                    ),
                                                    onTap: () =>
                                                        _showAnswer(
                                                            _filteredFaqs[
                                                                index]),
                                                  ),
                                                ],
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              )
                            : Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 35 * widthScale),
                                child: Column(
                                  children: [
                                    SizedBox(height: 40 * heightScale),
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: SvgPicture.asset(
                                        'assets/icons/Gmail.svg',
                                        height: 40 * heightScale,
                                        width: 40 * widthScale,
                                        fit: BoxFit.contain,
                                      ),
                                      title: Padding(
                                        padding: EdgeInsets.only(
                                            top: 12 * heightScale),
                                        child: Text(
                                          'Email',
                                          style: TextStyle(
                                            color: AppColor.textDark,
                                            fontSize: 20 * widthScale,
                                            fontFamily:
                                                'League Spartan',
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      subtitle: const Text(
                                        'support@forfood.com',
                                        style: TextStyle(
                                          color: AppColor.gray,
                                          fontSize: 14,
                                          fontFamily: 'League Spartan',
                                        ),
                                      ),
                                      trailing: Transform.rotate(
                                        angle: math.pi / 2,
                                        child: Image.asset(
                                          'assets/icons/BackiconArrow.png',
                                          height: 15 * heightScale,
                                          width: 15 * widthScale,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      onTap: _launchEmail,
                                    ),
                                    Container(
                                        height: 1,
                                        color: AppColor.divider),
                                    const SizedBox(height: 20),
                                    Center(
                                      child: Text(
                                        'We typically respond within 24 hours.',
                                        style: TextStyle(
                                          color: AppColor.gray,
                                          fontSize: 14 * widthScale,
                                          fontFamily: 'League Spartan',
                                          fontWeight: FontWeight.w300,
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
        );
      },
    );
  }
}