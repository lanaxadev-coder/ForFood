import 'package:flutter/material.dart';
import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/utilities/haptic_feedback.dart';

class OrderCard extends StatelessWidget {
  final String itemName;
  final String quantity;
  final String customerName;
  final String customerPhoneNumber;
  final String customerEmail;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onReject;
  final VoidCallback onTap;
  final VoidCallback? onReportIssue;     // 👈 NEW


  // 👈 Optional — enables the ticket header
  final String? orderNumber;
  final DateTime? createdAt;

  const OrderCard({
    super.key,
    required this.itemName,
    required this.quantity,
    required this.customerName,
    required this.customerPhoneNumber,
    required this.customerEmail,
    this.actionLabel,
    required this.onTap,
    this.onAction,
    this.onReject,
      this.onReportIssue,                  // 👈 NEW

    this.orderNumber,
    this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthScale = screenWidth / 393;

    return GestureDetector(
      onTap: () {
        HapticFeedbackUtil.light();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: 16 * widthScale,
          vertical: 12 * widthScale,
        ),
        decoration: BoxDecoration(
          color: AppColor.redFaint,
          border: Border.all(color: AppColor.orange, width: 1),
          borderRadius: BorderRadius.circular(26 * widthScale),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─────────────────────────────────────
            // HEADER — #ID  +  time
            // ─────────────────────────────────────
            if (orderNumber != null || createdAt != null) ...[
              
              SizedBox(height: 4 * widthScale),


              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (orderNumber != null)
                    Text(
                      '#$orderNumber',
                      style: TextStyle(
                        color: AppColor.orange,
                        fontSize: 13 * widthScale,
                        fontFamily: 'League Spartan',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const Spacer(),
                  if (createdAt != null)
                    Text(
                      _formatTime(createdAt!),
                      style: TextStyle(
                        color: AppColor.gray,
                        fontSize: 12 * widthScale,
                        fontFamily: 'League Spartan',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                     if (onReportIssue != null) ...[
      const SizedBox(width: 8),
      GestureDetector(
        onTap: () {
          HapticFeedbackUtil.light();
          onReportIssue!();
        },
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(
            Icons.more_vert,
            color: AppColor.gray,
            size: 18 * widthScale,
          ),
        ),
      ),
                    ],     ],
              ),
              SizedBox(height: 10 * widthScale),

              // Divider (matches OrderListCard style)
              Container(
                height: 0.5,
                color: AppColor.orange,
              ),
              SizedBox(height: 12 * widthScale),
            ],

            // ─────────────────────────────────────
            // ITEM ROW — name + quantity
            // ─────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    itemName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColor.textDark,
                      fontSize: 20 * widthScale,
                      fontFamily: 'League Spartan',
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                ),
                SizedBox(width: 12 * widthScale),
                Text(
                  quantity,
                  style: TextStyle(
                    color: AppColor.orange,
                    fontSize: 18 * widthScale,
                    fontFamily: 'League Spartan',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            SizedBox(height: 10 * widthScale),

            // ─────────────────────────────────────
            // CUSTOMER INFO
            // ─────────────────────────────────────
            if (customerName.isNotEmpty)
              Text(
                customerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColor.textDark,
                  fontSize: 14 * widthScale,
                  fontFamily: 'League Spartan',
                  fontWeight: FontWeight.w600,
                ),
              ),

            if (customerPhoneNumber.isNotEmpty || customerEmail.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 2 * widthScale),
                child: Text(
                  [
                    if (customerPhoneNumber.isNotEmpty) customerPhoneNumber,
                    if (customerEmail.isNotEmpty) customerEmail,
                  ].join('  •  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColor.textDark.withOpacity(0.7),
                    fontSize: 12 * widthScale,
                    fontFamily: 'League Spartan',
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),

            SizedBox(height: 12 * widthScale),

            // Divider
            Container(
              height: 0.5,
              color: AppColor.orange,
            ),

            SizedBox(height: 12 * widthScale),

            // ─────────────────────────────────────
            // ACTION ROW
            // ─────────────────────────────────────
            Row(
              children: [
                // Reject button (secondary — matches dialog style)
                if (onReject != null)
                  GestureDetector(
                    onTap: () {
                      HapticFeedbackUtil.heavy();
                      onReject?.call();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18 * widthScale,
                        vertical: 7 * widthScale,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFDECF),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        'Reject',
                        style: TextStyle(
                          color: AppColor.orange,
                          fontSize: 14 * widthScale,
                          fontFamily: 'League Spartan',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                const Spacer(),

                // Primary CTA — orange pill (matches dialog style)
                if (onAction != null && actionLabel != null)
                  GestureDetector(
                    onTap: () {
                      HapticFeedbackUtil.medium();
                      onAction?.call();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18 * widthScale,
                        vertical: 7 * widthScale,
                      ),
                      decoration: BoxDecoration(
                        color: AppColor.orange,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        actionLabel!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14 * widthScale,
                          fontFamily: 'League Spartan',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} d ago';
  }
}