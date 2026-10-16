import 'package:flutter/material.dart';

import '../../../utils/theme.dart';

/// Recessed surface matching `.tactile-inset`:
/// inner top shadow, 1px border (on-surface @ 10%), 4px radius.
class TactileInset extends StatelessWidget {
  const TactileInset({
    super.key,
    required this.child,
    this.backgroundColor = AppColors.surfaceDim,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final Color backgroundColor;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.onSurface.withValues(alpha: 0.10)),
        boxShadow: const [
          // inset 0 2px 4px rgba(0,0,0,0.05) — approximated via inner overlay below.
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 4,
            spreadRadius: -2,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        clipBehavior: clipBehavior,
        child: Stack(
          children: [
            child,
            // Subtle top-inner shadow gradient to mimic the recessed CSS look.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 8,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
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
}
