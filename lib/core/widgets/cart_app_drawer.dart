// ============================================================
// CART VIEW — WIRED TO CARTBLOC (CORRECTED)
// ============================================================
// Cart drawer shown from the user's home screen.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/core/widgets/cart_item_card.dart';
import 'package:forfood/models/order_model.dart';
import 'package:forfood/service/cart/cart_bloc.dart';
import 'package:forfood/service/cart/cart_event.dart';
import 'package:forfood/service/cart/cart_state.dart';
import 'package:forfood/utilities/haptic_feedback.dart';
import 'package:forfood/utilities/page_transition.dart';
import 'package:forfood/view/user/checkout_view.dart';

class CartView extends StatelessWidget {
  const CartView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        if (state is CartStateLoaded) {
          return _buildCartDrawer(
            context: context,
            items: state.items,
            total: state.total,
          );
        }

        if (state is CartStateError) {
          return _buildErrorDrawer(context, state.message);
        } 

        return _buildEmptyDrawer(context);
      },
    );
  }

  // ============================================================
  // DRAWER BUILDERS
  // ============================================================

  Widget _buildCartDrawer({
    required BuildContext context,
    required List<OrderItem> items,
    required double total,
  }) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(70),
          bottomLeft: Radius.circular(70),
        ),
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: AppColor.orange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(60),
              bottomLeft: Radius.circular(60),
            ),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 60),
            _Header(itemCount: items.length),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Divider(color: const Color(0xFFFFDECF)),
                        ),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return CartItemCard(
                            imageUrl: item.imageUrl ?? 'https://placehold.co/80x80',
                            name: item.name,
                            price: item.price,
                            quantity: item.quantity,
                            date: _formatDate(item.dateTime),
                            time: _formatTime(item.dateTime),
                            onIncrement: () {
                              context.read<CartBloc>().add(
                                    CartEventIncrementQuantity(
                                      menuItemId: item.menuItemId,
                                    ),
                                  );
                            },
                            onDecrement: () {
                              context.read<CartBloc>().add(
                                    CartEventDecrementQuantity(
                                      menuItemId: item.menuItemId,
                                    ),
                                  );
                            },
                          );
                        },
                      ),
                    ),
                    Divider(color: const Color(0xFFFFDECF).withOpacity(0.4)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontFamily: 'League Spartan',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '\$${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFFF8F8F8),
                            fontSize: 20,
                            fontFamily: 'League Spartan',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 150,
                      child: ElevatedButton(
                        onPressed: () {
                            HapticFeedbackUtil.medium();  // ✅ ADDED

                          Navigator.push(
                            context,
                            fadeSlideRoute( const CheckoutView()),
                          
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.yellow,
                          foregroundColor: AppColor.orange,
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Checkout',
                          style: TextStyle(
                            fontSize: 20,
                            fontFamily: 'League Spartan',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorDrawer(BuildContext context, String message) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(70),
          bottomLeft: Radius.circular(70),
        ),
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: AppColor.orange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(60),
              bottomLeft: Radius.circular(60),
            ),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 60),
            const _Header(itemCount: 0),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDrawer(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(70),
          bottomLeft: Radius.circular(70),
        ),
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: AppColor.orange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(60),
              bottomLeft: Radius.circular(60),
            ),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 60),
            const _Header(itemCount: 0),
            const Expanded(child: _EmptyCart()),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DATE/TIME FORMATTERS
  // ============================================================

  String _formatDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString().substring(2);
    return '$day/$month/$year';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

// ============================================================
// HEADER WIDGET
// ============================================================

class _Header extends StatelessWidget {
  final int itemCount;
  const _Header({required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 80),
                child: SizedBox(
                  height: 40,
                  width: 40,
                  child: SvgPicture.asset(
                    'assets/icons/cart.svg',
                    height: 40,
                    width: 40,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Cart',
                    style: TextStyle(
                      color: Color(0xFFF8F8F8),
                      fontSize: 25,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 80),
            ],
          ),
          const SizedBox(height: 30),
          Container(
            height: 0.75,
            width: 254,
            color: AppColor.yellow,
          ),
          const SizedBox(height: 15),
          Text(
            itemCount == 0
                ? ''
                : 'You have $itemCount item${itemCount == 1 ? '' : 's'} in the cart',
            style: const TextStyle(
              color: Color(0xFFF8F8F8),
              fontSize: 20,
              fontFamily: 'League Spartan',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// EMPTY CART WIDGET (WITH CTA)
// ============================================================

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Your cart is empty',
            style: TextStyle(
              color: const Color(0xFFF8F8F8),
              fontSize: 20,
              fontFamily: 'League Spartan',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 60),
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(92),
            child: Container(
              width: 184,
              height: 184,
              decoration: const BoxDecoration(
                color: Color(0xFFE95322),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 56),
            ),
          ),
          const SizedBox(height: 40),
          const SizedBox(
            width: 200,
            child: Text(
              'Want to add something?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontFamily: 'League Spartan',
                fontWeight: FontWeight.w700,
                height: 1.08,
              ),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: AppColor.yellow,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                'Browse Restaurants',
                style: TextStyle(
                  color: AppColor.orange,
                  fontSize: 16,
                  fontFamily: 'League Spartan',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}