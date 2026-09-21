// ============================================================
// RESTAURANT REVIEWS VIEW — see what customers say
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/bottom_nav_dart.dart';
import 'package:forfood/core/widgets/drawer_helpers.dart';
import 'package:forfood/models/review_model.dart';
import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/database/firestore_provider.dart';
import 'package:forfood/service/restaurant/restaurant_bloc.dart';
import 'package:forfood/service/restaurant/restaurant_event.dart';
import 'package:forfood/service/restaurant/restaurant_state.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/utilities/tab_route.dart';
import 'package:forfood/view/chat_inbox_view.dart';

import 'package:forfood/view/restaurant/home_page.dart';
import 'package:forfood/view/restaurant/incoming_order.dart';
import 'package:forfood/view/restaurant/menu.dart';
import 'package:forfood/view/restaurant/profile.dart';

class ReviewsView extends StatefulWidget {
  const ReviewsView({super.key});

  @override
  State<ReviewsView> createState() => _ReviewsViewState();
}

class _ReviewsViewState extends State<ReviewsView> {
  int _currentIndex = 0;
  final FirestoreProvider _firestoreProvider = FirestoreProvider();
  StreamSubscription<List<ReviewModel>>? _reviewsSubscription;
  List<ReviewModel> _reviews = [];
  bool _isLoading = true;
  String? _restaurantId;

  @override
  void initState() {
    super.initState();
    _fetchRestaurant();
  }

  @override
  void dispose() {
    _reviewsSubscription?.cancel();
    super.dispose();
  }

  void _fetchRestaurant() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthStateLoggedIn) {
      context.read<RestaurantBloc>().add(
            RestaurantEventFetchByOwnerId(ownerId: authState.user.id),
          );
    }
  }

  void _fetchReviews(String restaurantId) {
    _reviewsSubscription?.cancel();
    _reviewsSubscription = _firestoreProvider
        .streamReviewsByRestaurantId(restaurantId)
        .listen(
      (reviews) {
        if (mounted) {
          setState(() {
            _reviews = reviews;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  void _handleBottomNavTap(int index) {
  if (index == _currentIndex) return;

  switch (index) {
    case 0:
      Navigator.of(context).pushAndRemoveUntil(
        tabRoute(const RestaurantHomeView()),
        (route) => false,
      );
      break;
    case 1:
      Navigator.of(context).pushAndRemoveUntil(
        tabRoute(const OrdersView()),
        (route) => false,
      );
      break;
    case 2:
      Navigator.of(context).push(tabRoute(const ChatInboxView()));
      break;
    case 3:
      Navigator.of(context).push(tabRoute(const MenuListView()));
      break;
    case 4:
      Navigator.of(context).push(
        tabRoute(const ProfileViewRestaurant()),
      );
      break;
  }
}

  // ============================================================
  // COMPUTED — rating stats
  // ============================================================

  double get _averageRating {
    if (_reviews.isEmpty) return 0;
    final sum = _reviews.fold<int>(0, (acc, r) => acc + r.rating);
    return sum / _reviews.length;
  }

  int _countFor(int star) {
    return _reviews.where((r) => r.rating == star).length;
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
                _fetchReviews(_restaurantId!);
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

                    // Back
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
                        'Reviews',
                        style: TextStyle(
                          color: AppColor.nearWhite,
                          fontSize: 28 * widthScale,
                          fontFamily: 'League Spartan',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Content
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 163 * heightScale,
                      bottom: 0,
                      child: _isLoading
                          ? _buildSkeleton(widthScale, heightScale)
                          : _reviews.isEmpty
                              ? _buildEmpty(widthScale, heightScale)
                              : RefreshIndicator(
                                  color: AppColor.orange,
                                  onRefresh: () async {
                                    if (_restaurantId != null) {
                                      _fetchReviews(_restaurantId!);
                                    }
                                    await Future.delayed(
                                      const Duration(milliseconds: 500),
                                    );
                                  },
                                  child: ListView(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24 * widthScale,
                                      vertical: 16 * heightScale,
                                    ),
                                    children: [
                                      _buildSummaryCard(
                                          widthScale, heightScale),
                                      SizedBox(height: 24 * heightScale),
                                      Text(
                                        'All reviews (${_reviews.length})',
                                        style: TextStyle(
                                          color: AppColor.textDark,
                                          fontSize: 16 * widthScale,
                                          fontFamily: 'League Spartan',
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(height: 12 * heightScale),
                                      ..._reviews.map(
                                        (r) => Padding(
                                          padding: EdgeInsets.only(
                                              bottom: 12 * heightScale),
                                          child: _ReviewCard(
                                            review: r,
                                            widthScale: widthScale,
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
                isRestaurant: true,
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // SUMMARY CARD — avg rating + distribution
  // ============================================================
  Widget _buildSummaryCard(double widthScale, double heightScale) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20 * widthScale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20 * widthScale),
        border: Border.all(color: AppColor.divider, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left — big average
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _averageRating.toStringAsFixed(1),
                style: TextStyle(
                  color: AppColor.orange,
                  fontSize: 48 * widthScale,
                  fontFamily: 'League Spartan',
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
              SizedBox(height: 4 * heightScale),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Icon(
                    i < _averageRating.round()
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: const Color(0xFFF4BA1A),
                    size: 16 * widthScale,
                  );
                }),
              ),
              SizedBox(height: 4 * heightScale),
              Text(
                '${_reviews.length} review${_reviews.length == 1 ? '' : 's'}',
                style: TextStyle(
                  color: AppColor.gray,
                  fontSize: 11 * widthScale,
                  fontFamily: 'League Spartan',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),

          SizedBox(width: 20 * widthScale),

          // Right — distribution
          Expanded(
            child: Column(
              children: [
                ...List.generate(5, (i) {
                  final star = 5 - i;
                  return _DistributionBar(
                    star: star,
                    count: _countFor(star),
                    total: _reviews.length,
                    widthScale: widthScale,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY & SKELETON
  // ============================================================
  Widget _buildEmpty(double widthScale, double heightScale) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40 * widthScale),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_border_rounded,
              color: AppColor.orange,
              size: 72 * widthScale,
            ),
            SizedBox(height: 20 * heightScale),
            Text(
              'No reviews yet',
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
              'When customers review your food,\nthey\'ll show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColor.gray,
                fontSize: 14 * widthScale,
                fontFamily: 'League Spartan',
                fontWeight: FontWeight.w300,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton(double widthScale, double heightScale) {
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: 24 * widthScale,
        vertical: 16 * heightScale,
      ),
      children: [
        Container(
          height: 160 * heightScale,
          decoration: BoxDecoration(
            color: const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(20 * widthScale),
          ),
        ),
        SizedBox(height: 24 * heightScale),
        ...List.generate(
          3,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: 12 * heightScale),
            child: Container(
              height: 110 * heightScale,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(16 * widthScale),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// DISTRIBUTION BAR — one row of the star breakdown
// ============================================================
class _DistributionBar extends StatelessWidget {
  final int star;
  final int count;
  final int total;
  final double widthScale;

  const _DistributionBar({
    required this.star,
    required this.count,
    required this.total,
    required this.widthScale,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : count / total;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3 * widthScale),
      child: Row(
        children: [
          Text(
            '$star',
            style: TextStyle(
              color: AppColor.textDark,
              fontSize: 12 * widthScale,
              fontFamily: 'League Spartan',
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 2 * widthScale),
          Icon(
            Icons.star_rounded,
            color: const Color(0xFFF4BA1A),
            size: 12 * widthScale,
          ),
          SizedBox(width: 6 * widthScale),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  Container(
                    height: 8 * widthScale,
                    color: AppColor.divider,
                  ),
                  FractionallySizedBox(
                    widthFactor: fraction,
                    child: Container(
                      height: 8 * widthScale,
                      color: AppColor.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 8 * widthScale),
          SizedBox(
            width: 26 * widthScale,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppColor.gray,
                fontSize: 11 * widthScale,
                fontFamily: 'League Spartan',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// REVIEW CARD — one customer review
// ============================================================
class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final double widthScale;

  const _ReviewCard({required this.review, required this.widthScale});

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';

    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return '$day/$month/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * widthScale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * widthScale),
        border: Border.all(color: AppColor.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — name + stars
          Row(
            children: [
              // Avatar circle
              Container(
                width: 36 * widthScale,
                height: 36 * widthScale,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColor.orange.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  review.userName.isNotEmpty
                      ? review.userName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: AppColor.orange,
                    fontSize: 16 * widthScale,
                    fontFamily: 'League Spartan',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 10 * widthScale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColor.textDark,
                        fontSize: 14 * widthScale,
                        fontFamily: 'League Spartan',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2 ),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < review.rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: const Color(0xFFF4BA1A),
                          size: 14 * widthScale,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(review.createdAt),
                style: TextStyle(
                  color: AppColor.gray,
                  fontSize: 11 * widthScale,
                  fontFamily: 'League Spartan',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            SizedBox(height: 12 * widthScale),
            Text(
              review.comment,
              style: TextStyle(
                color: AppColor.textDark.withOpacity(0.85),
                fontSize: 13 * widthScale,
                fontFamily: 'League Spartan',
                fontWeight: FontWeight.w400,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Tiny helper just to keep vertical spacing responsive (avoids magic 2.0)
}