import 'package:flutter/material.dart';

import '../../../utils/theme.dart';

/// Row of seat indicators matching `.slot-filled` / `.slot-empty`:
/// filled seats are solid bordeaux (#570000), empty seats are transparent
/// with a muted outline (#8e706c).
class PlayerSlots extends StatelessWidget {
  const PlayerSlots({
    super.key,
    required this.filled,
    required this.total,
    this.size = 14,
    this.gap = 6,
    this.isFull = false,
  });

  final int filled;
  final int total;
  final double size;
  final double gap;

  /// When true, filled dots use error red instead of primary (matching the
  /// HTML `.bg-error` rule for fully-booked tables).
  final bool isFull;

  @override
  Widget build(BuildContext context) {
    final filledColor = isFull ? AppColors.error : AppColors.slotFilled;
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (var i = 0; i < total; i++)
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < filled ? filledColor : Colors.transparent,
              border: Border.all(
                color: i < filled ? filledColor : AppColors.slotEmptyBorder,
                width: 1.5,
              ),
            ),
          ),
      ],
    );
  }
}
