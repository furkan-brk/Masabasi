import 'package:flutter/material.dart';

import '../../../utils/theme.dart';

/// Scholarly twin-line rule matching `.double-divider`:
/// 1px top + 1px bottom outline-variant lines, 3px tall, with an optional
/// centered diamond (◆ rotated square) like the Koleksiyon header.
class DoubleDivider extends StatelessWidget {
  const DoubleDivider({
    super.key,
    this.withDiamond = false,
    this.color = AppColors.doubleDividerLine,
    this.maxWidth,
  });

  final bool withDiamond;
  final Color color;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final line = Container(
      height: 3,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: color),
          bottom: BorderSide(color: color),
        ),
      ),
    );

    Widget content = withDiamond
        ? Stack(
            alignment: Alignment.center,
            children: [
              line,
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                transform: Matrix4.rotationZ(0.785398), // 45deg
                transformAlignment: Alignment.center,
                color: AppColors.primary,
              ),
            ],
          )
        : line;

    if (maxWidth != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: content,
      );
    }
    return content;
  }
}
