// ============================================================
// STATISTICS VIEW — FIXED BOTTOM NAV + REAL DATA
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/bottom_nav_dart.dart';
import 'package:forfood/core/widgets/drawer_helpers.dart';
import 'package:forfood/models/order_model.dart';
import 'package:forfood/service/auth/auth_bloc.dart';
import 'package:forfood/service/auth/auth_state.dart';
import 'package:forfood/service/order/order_bloc.dart';
import 'package:forfood/service/order/order_event.dart';
import 'package:forfood/service/order/order_state.dart';
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

enum TimeRange { week, month, allTime }

class StatisticsView extends StatefulWidget {
  const StatisticsView({super.key});

  @override
  State<StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<StatisticsView> {
  int _currentIndex = 0;
  TimeRange _selectedRange = TimeRange.week;
  String? _restaurantId;

  // ✅ Real data from Firestore
  List<OrderModel> _allOrders = [];
  int _totalViews = 0;
  double _averageRating = 0.0;
  int _ratingCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthStateLoggedIn) {
      context.read<RestaurantBloc>().add(
            RestaurantEventFetchByOwnerId(ownerId: authState.user.id),
          );
    }
  }

  // ✅ Calculate real stats from orders
  void _calculateStats(List<OrderModel> orders) {
    _allOrders = orders;
       
  }

  // ✅ Filter orders by time range
  List<OrderModel> get _filteredOrders {
    final now = DateTime.now();
    switch (_selectedRange) {
      case TimeRange.week:
        final weekAgo = now.subtract(const Duration(days: 7));
        return _allOrders.where((o) => o.createdAt.isAfter(weekAgo)).toList();
      case TimeRange.month:
        final monthAgo = now.subtract(const Duration(days: 30));
        return _allOrders.where((o) => o.createdAt.isAfter(monthAgo)).toList();
      case TimeRange.allTime:
        return _allOrders;
    }
  }

  // ✅ Real top items
  List<Map<String, dynamic>> get _topItems {
    final itemCounts = <String, int>{};
    for (final order in _filteredOrders) {
      for (final item in order.items) {
        itemCounts[item.name] = (itemCounts[item.name] ?? 0) + item.quantity;
      }
    }
    final sorted = itemCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .take(5)
        .map((e) => {'name': e.key, 'orders': e.value})
        .toList();
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
              userName = restaurantState.restaurant.name;
              _totalViews = restaurantState.restaurant.views;
              _averageRating = restaurantState.restaurant.rating;
              _ratingCount = restaurantState.restaurant.ratingCount;

              if (_restaurantId != restaurantState.restaurant.id) {
                _restaurantId = restaurantState.restaurant.id;
                context.read<OrderBloc>().add(
                      OrderEventFetchRestaurantOrders(
                        restaurantId: _restaurantId!,
                      ),
                    );
              }
            }

            return BlocBuilder<OrderBloc, OrderState>(
              builder: (context, orderState) {
                  if (orderState is OrderStateLoading) {
  return Column(
    children: [
      Row(
        children: [
          _buildStatCardSkeleton(widthScale, heightScale),
          SizedBox(width: 10 * widthScale),
          _buildStatCardSkeleton(widthScale, heightScale),
        ],
      ),
      SizedBox(height: 10 * heightScale),
      Row(
        children: [
          _buildStatCardSkeleton(widthScale, heightScale),
          SizedBox(width: 10 * widthScale),
          _buildStatCardSkeleton(widthScale, heightScale),
        ],
      ),
    ],
  );
}


                if (orderState is OrderStateLoaded) {
                  _calculateStats(orderState.orders);
                }

                final filteredOrders = _filteredOrders;
                final ordersCount = filteredOrders.length;
                final revenue = filteredOrders
                    .where((o) => o.status == OrderStatus.completed)
                    .fold(0.0, (sum, o) => sum + o.total);

                return Scaffold(
                  endDrawer: buildRestaurantDrawer(
                    name: userName,
                    email: userEmail,
                    profileImageUrl: profileImageUrl,
                  ),
                  body: Container(
                    width: screenWidth,
                    height: screenHeight,
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      color: AppColor.yellow,
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
                          left: 130 * widthScale,
                          top: 76 * heightScale,
                          child: Text(
                            'Statistics',
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
                            padding: EdgeInsets.symmetric(horizontal: 20 * widthScale),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 20 * heightScale),

                                // Time range selector
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildTimeRangeChip('This Week', TimeRange.week, widthScale, heightScale),
                                    SizedBox(width: 8 * widthScale),
                                    _buildTimeRangeChip('This Month', TimeRange.month, widthScale, heightScale),
                                    SizedBox(width: 8 * widthScale),
                                    _buildTimeRangeChip('All Time', TimeRange.allTime, widthScale, heightScale),
                                  ],
                                ),

                                SizedBox(height: 20 * heightScale),

                                // ✅ Real stats cards
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        _buildStatCard('Views', '$_totalViews', Icons.visibility_outlined, widthScale, heightScale),
                                        SizedBox(width: 10 * widthScale),
                                        _buildStatCard('Orders', '$ordersCount', Icons.receipt_long_outlined, widthScale, heightScale),
                                      ],
                                    ),
                                    SizedBox(height: 10 * heightScale),
                                    Row(
                                      children: [
                                        _buildStatCard('Revenue', '\$${revenue.toStringAsFixed(0)}', Icons.attach_money, widthScale, heightScale),
                                        SizedBox(width: 10 * widthScale),
                                        _buildStatCard('Rating', '${_averageRating.toStringAsFixed(1)} ($_ratingCount)', Icons.star_outline, widthScale, heightScale),
                                      ],
                                    ),
                                  ],
                                ),

                                SizedBox(height: 30 * heightScale),

                                Text(
                                  'Orders Overview',
                                  style: TextStyle(
                                    color: AppColor.textDark,
                                    fontSize: 18 * widthScale,
                                    fontFamily: 'League Spartan',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 15 * heightScale),
                                Container(
                                  height: 200 * heightScale,
                                  padding: EdgeInsets.all(15 * widthScale),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: filteredOrders.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'No orders in this period',
                                            style: TextStyle(
                                              color: AppColor.gray,
                                              fontSize: 14,
                                              fontFamily: 'League Spartan',
                                            ),
                                          ),
                                        )
                                      : BarChart(
                                          BarChartData(
                                            barGroups: _getBarGroups(filteredOrders),
                                            borderData: FlBorderData(show: false),
                                            gridData: const FlGridData(show: true),
                                            titlesData: FlTitlesData(
                                              leftTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  reservedSize: 30,
                                                  getTitlesWidget: (value, meta) {
                                                    return Text(
                                                      value.toInt().toString(),
                                                      style: const TextStyle(fontSize: 10, color: AppColor.gray),
                                                    );
                                                  },
                                                ),
                                              ),
                                              bottomTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  getTitlesWidget: (value, meta) {
                                                    return Text(
                                                      _getXAxisLabel(value.toInt()),
                                                      style: const TextStyle(fontSize: 10, color: AppColor.gray),
                                                    );
                                                  },
                                                ),
                                              ),
                                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                            ),
                                          ),
                                        ),
                                ),

                                SizedBox(height: 30 * heightScale),

                                Text(
                                  'Top Items',
                                  style: TextStyle(
                                    color: AppColor.textDark,
                                    fontSize: 18 * widthScale,
                                    fontFamily: 'League Spartan',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 15 * heightScale),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: _topItems.isEmpty
                                      ? const Padding(
                                          padding: EdgeInsets.all(20),
                                          child: Center(
                                            child: Text(
                                              'No items ordered yet',
                                              style: TextStyle(
                                                color: AppColor.gray,
                                                fontSize: 14,
                                                fontFamily: 'League Spartan',
                                              ),
                                            ),
                                          ),
                                        )
                                      : Column(
                                          children: List.generate(_topItems.length, (index) {
                                            final item = _topItems[index];
                                            return _buildTopItem(
                                              index + 1,
                                              item['name'] as String,
                                              item['orders'] as int,
                                              widthScale,
                                              heightScale,
                                            );
                                          }),
                                        ),
                                ),

                                SizedBox(height: 30 * heightScale),
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
      },
    );
  }

  // ✅ Generate bar groups from real orders
  List<BarChartGroupData> _getBarGroups(List<OrderModel> orders) {
    final counts = <int, int>{};
    for (final order in orders) {
      final day = order.createdAt.day;
      counts[day] = (counts[day] ?? 0) + 1;
    }
    final sortedDays = counts.keys.toList()..sort();
    return List.generate(sortedDays.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: counts[sortedDays[index]]!.toDouble(),
            color: AppColor.orange,
            width: 15,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  String _getXAxisLabel(int index) {
    switch (_selectedRange) {
      case TimeRange.week:
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return index < days.length ? days[index] : '';
      case TimeRange.month:
        return 'D${index + 1}';
      case TimeRange.allTime:
        return 'D${index + 1}';
    }
  }

  Widget _buildTopItem(int rank, String name, int orders, double widthScale, double heightScale) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 15 * widthScale,
        vertical: 12 * heightScale,
      ),
      child: Row(
        children: [
          Text('$rank.', style: TextStyle(color: AppColor.orange, fontSize: 16 * widthScale, fontFamily: 'League Spartan', fontWeight: FontWeight.w700)),
          SizedBox(width: 10 * widthScale),
          Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColor.textDark, fontSize: 15 * widthScale, fontFamily: 'League Spartan', fontWeight: FontWeight.w500))),
          Text('$orders orders', style: TextStyle(color: AppColor.gray, fontSize: 14 * widthScale, fontFamily: 'League Spartan')),
        ],
      ),
    );
  }

  Widget _buildTimeRangeChip(String label, TimeRange range, double widthScale, double heightScale) {
    final isSelected = _selectedRange == range;
    return GestureDetector(
      onTap: () => setState(() => _selectedRange = range),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12 * widthScale, vertical: 6 * heightScale),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.orange : const Color(0xFFFFDECF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColor.orange,
            fontSize: 11 * widthScale,
            fontFamily: 'League Spartan',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, double widthScale, double heightScale) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(15 * widthScale),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColor.orange, size: 24 * widthScale),
            SizedBox(height: 10 * heightScale),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColor.textDark, fontSize: 22 * widthScale, fontFamily: 'League Spartan', fontWeight: FontWeight.w700)),
            SizedBox(height: 4 * heightScale),
            Text(label, style: TextStyle(color: AppColor.gray, fontSize: 12 * widthScale, fontFamily: 'League Spartan')),
          ],
        ),
      ),
    );
  }

  
// Add helper method at bottom of class:
Widget _buildStatCardSkeleton(double widthScale, double heightScale) {
  return Expanded(
    child: Container(
      padding: EdgeInsets.all(15 * widthScale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24 * widthScale,
            height: 24 * widthScale,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          SizedBox(height: 10 * heightScale),
          Container(
            width: 60 * widthScale,
            height: 22 * widthScale,
            color: const Color(0xFFE0E0E0),
          ),
          SizedBox(height: 4 * heightScale),
          Container(
            width: 40 * widthScale,
            height: 12 * widthScale,
            color: const Color(0xFFE0E0E0),
          ),
        ],
      ),
    ),
  );
}
}