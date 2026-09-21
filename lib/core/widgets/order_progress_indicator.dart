// ============================================================
// ORDER PROGRESS INDICATOR — 3 STAGES (USER FACING)
// ============================================================
// Simplified progress for users:
// Confirmed → In Progress → Done
//
// Maps restaurant statuses to user stages:
//   Accepted → Confirmed
//   Preparing/ReadyForPickup/OutForDelivery → In Progress
//   Completed → Done
// ============================================================

import 'package:flutter/material.dart';
import 'package:forfood/core/theme/app_color.dart';
import 'package:forfood/models/order_model.dart';

class OrderProgressIndicator extends StatelessWidget {
  final OrderStatus currentStatus;

  const OrderProgressIndicator({
    super.key,
    required this.currentStatus,
  });

  /// Maps restaurant status to simplified user stage index (0, 1, or 2).
  int get _stageIndex {
    switch (currentStatus) {
      case OrderStatus.pending:
      case OrderStatus.accepted:
        return 0; // Confirmed
      case OrderStatus.preparing:
      case OrderStatus.readyForPickup:
      case OrderStatus.outForDelivery:
        return 1; // In Progress
      case OrderStatus.completed:
        return 2; // Done
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    const stages = ['Confirmed', 'In Progress', 'Done'];

    return Column(
      children: [
        // Dots and connectors
        Row(
          children: List.generate(5, (index) {
            if (index.isOdd) {
              // Connector line
              final stepIndex = (index - 1) ~/ 2;
              final isCompleted = stepIndex < _stageIndex;
              return Expanded(
                child: Container(
                  height: 2,
                  color: isCompleted ? AppColor.orange : AppColor.gray,
                ),
              );
            }

            // Step circle
            final stepIndex = index ~/ 2;
            final isCompleted = stepIndex < _stageIndex;
            final isCurrent = stepIndex == _stageIndex;

            return Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? AppColor.orange
                    : AppColor.gray,
                shape: BoxShape.circle,
                border: isCurrent
                    ? Border.all(color: AppColor.yellow, width: 2)
                    : null,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isCurrent ? Colors.white : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
            );
          }),
        ),

        const SizedBox(height: 8),

        // Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: stages.map((label) {
            return Text(
              label,
              style: const TextStyle(
                color: AppColor.textDark,
                fontSize: 10,
                fontFamily: 'League Spartan',
                fontWeight: FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}