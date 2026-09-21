// ============================================================
// LEAVE REVIEW VIEW — PRODUCTION READY
// Real drawer + Bottom Nav + Responsive + Shimmer
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/bottom_nav_dart.dart';
import 'package:forfood/core/widgets/cart_app_drawer.dart';
import 'package:forfood/core/widgets/drawer_helpers.dart';
import 'package:forfood/core/widgets/notification_drawer.dart';

import 'package:forfood/models/review_model.dart';
import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/database/firestore_provider.dart';
import 'package:forfood/service/exceptions/domain_exceptions.dart';
import 'package:forfood/service/notification/notification_trigger.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/utilities/tab_route.dart';
import 'package:forfood/view/chat_inbox_view.dart';

import 'package:forfood/view/user/home_page.dart';
import 'package:forfood/view/user/search_screen.dart';

class LeaveReviewView extends StatefulWidget {
  final String itemName;
  final String itemImageUrl;
  final String restaurantId;

  const LeaveReviewView({
    super.key,
    required this.itemName,
    required this.itemImageUrl,
    this.restaurantId = '',
  });

  @override
  State<LeaveReviewView> createState() => _LeaveReviewViewState();
}

class _LeaveReviewViewState extends State<LeaveReviewView> {
  int _rating = 0;
  int _currentIndex = 0;
  bool _isSubmitting = false;
  final TextEditingController _commentController = TextEditingController();
  final FirestoreProvider _firestoreProvider = FirestoreProvider();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ✅ Which drawer to show
  DrawerType _activeDrawer = DrawerType.profile;

  @override
  void dispose() {
    _commentController.dispose();
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

  Future<void> _handleSubmitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthStateLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to leave a review')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Capture the messenger + navigator BEFORE any await
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final review = ReviewModel(
        id: '',
        restaurantId: widget.restaurantId,
        userId: authState.user.id,
        userName: authState.user.fullName,
        rating: _rating,
        comment: _commentController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _firestoreProvider.createReview(review);

      if (widget.restaurantId.isNotEmpty) {
        await _firestoreProvider.updateRestaurantRating(
          restaurantId: widget.restaurantId,
          newRating: _rating,
        );

        try {
          final restaurant =
              await _firestoreProvider.getRestaurantById(widget.restaurantId);
          final trigger = NotificationTriggerService(_firestoreProvider);
          await trigger.onReviewAdded(
            restaurantId: widget.restaurantId,
            restaurantName: restaurant.name,
            review: review,
          );
        } catch (_) {
          // silent — review already saved
        }
      }

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Review submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      navigator.pop();
    } on FirestoreOperationException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to submit review: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
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
                      'Leave a Review',
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
                      padding: EdgeInsets.symmetric(horizontal: 35 * widthScale),
                      child: Column(
                        children: [
                          SizedBox(height: 40 * heightScale),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: Image.network(
                              widget.itemImageUrl,
                              width: 150 * widthScale,
                              height: 150 * heightScale,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: 150 * widthScale,
                                  height: 150 * heightScale,
                                  color: const Color(0xFFFFDECF),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColor.orange,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => Container(
                                width: 150 * widthScale,
                                height: 150 * heightScale,
                                color: const Color(0xFFFFDECF),
                                child: const Icon(
                                  Icons.restaurant,
                                  color: AppColor.orange,
                                  size: 50,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20 * heightScale),
                          Text(
                            widget.itemName,
                            style: TextStyle(
                              color: AppColor.textDark,
                              fontSize: 24 * widthScale,
                              fontFamily: 'League Spartan',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 20 * heightScale),
                          Text(
                            "We'd love to know what you think of your dish.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColor.textDark,
                              fontSize: 19 * widthScale,
                              fontFamily: 'League Spartan',
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          SizedBox(height: 16 * heightScale),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              return GestureDetector(
                                onTap: () => setState(() => _rating = index + 1),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4 * widthScale),
                                  child: Icon(
                                    index < _rating
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: AppColor.orange,
                                    size: 36 * widthScale,
                                  ),
                                ),
                              );
                            }),
                          ),
                          SizedBox(height: 24 * heightScale),
                          Text(
                            'Leave us your comment!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColor.textDark,
                              fontSize: 19 * widthScale,
                              fontFamily: 'League Spartan',
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          SizedBox(height: 12 * heightScale),
                          Container(
                            height: 95 * heightScale,
                            padding: EdgeInsets.only(top: 5 * heightScale, left: 16 * widthScale),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E9B5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextField(
                              controller: _commentController,
                              textAlignVertical: TextAlignVertical.top,
                              maxLines: null,
                              decoration: InputDecoration(
                                hintText: 'Write Review...',
                                hintStyle: TextStyle(
                                  color: AppColor.gray,
                                  fontSize: 14 * widthScale,
                                  fontFamily: 'League Spartan',
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          SizedBox(height: 30 * heightScale),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: 5 * heightScale),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFDECF),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: AppColor.orange,
                                        fontSize: 17 * widthScale,
                                        fontFamily: 'League Spartan',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12 * widthScale),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _isSubmitting ? null : _handleSubmitReview,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: 5 * heightScale),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: _isSubmitting ? AppColor.gray : AppColor.orange,
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: _isSubmitting
                                        ? SizedBox(
                                            width: 24 * widthScale,
                                            height: 24 * heightScale,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            'Submit',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 17 * widthScale,
                                              fontFamily: 'League Spartan',
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
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
            ),
          ),
        );
      },
    );
  }
}