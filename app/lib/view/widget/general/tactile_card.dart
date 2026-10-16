import 'package:flutter/material.dart';

import '../../../utils/theme.dart';

/// Skeuomorphic card matching `.tactile-card`:
/// 1px border (on-surface @ 15%), 4px radius, surface-container-lowest bg,
/// hover lifts -2px with a soft shadow.
class TactileCard extends StatefulWidget {
  const TactileCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.backgroundColor = AppColors.surfaceContainerLowest,
    this.onTap,
    this.topBorder,
    this.clipBehavior = Clip.none,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final VoidCallback? onTap;

  /// Optional accent top border (e.g. `border-t-4 border-t-secondary`).
  final Border? topBorder;
  final Clip clipBehavior;

  @override
  State<TactileCard> createState() => _TactileCardState();
}

class _TactileCardState extends State<TactileCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final base = Border.all(color: AppColors.onSurface.withValues(alpha: 0.15));
    final border = widget.topBorder == null
        ? base
        : Border(
            top: widget.topBorder!.top,
            left: base.left,
            right: base.right,
            bottom: base.bottom,
          );

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hovering ? -2 : 0, 0),
          clipBehavior: widget.clipBehavior,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: border,
            boxShadow: _hovering
                ? const [
                    BoxShadow(
                      color: Color(0x0D000000), // rgba(0,0,0,0.05)
                      blurRadius: 6,
                      offset: Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Color(0x08000000), // rgba(0,0,0,0.03)
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
