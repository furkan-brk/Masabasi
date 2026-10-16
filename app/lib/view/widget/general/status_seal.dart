import 'package:flutter/material.dart';

import '../../../utils/theme.dart';

/// The status pill used on game cards / session cards.
/// Two canonical variants from CSS:
///  - bekliyor (`.status-bekliyor`): green outline + bbeacf fill
///  - dolu (`.status-dolu`): red outline + ffdad6 fill
/// Plus the card-corner seals "Mevcut" (secondary) and "Masada" (error).
enum SealKind { bekliyor, dolu, mevcut, masada }

class StatusSeal extends StatelessWidget {
  const StatusSeal({super.key, required this.kind, this.label, this.icon});

  final SealKind kind;
  final String? label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    late final Color border;
    late final String text;

    switch (kind) {
      case SealKind.bekliyor:
        bg = AppColors.statusBekliyorBg;
        fg = AppColors.statusBekliyorBorder;
        border = AppColors.statusBekliyorBorder;
        text = label ?? 'Bekliyor';
        break;
      case SealKind.dolu:
        bg = AppColors.statusDoluBg;
        fg = AppColors.statusDoluBorder;
        border = AppColors.statusDoluBorder;
        text = label ?? 'Dolu';
        break;
      case SealKind.mevcut:
        bg = AppColors.secondary;
        fg = AppColors.onSecondary;
        border = AppColors.secondaryContainer;
        text = label ?? 'Mevcut';
        break;
      case SealKind.masada:
        bg = AppColors.error;
        fg = AppColors.onError;
        border = AppColors.errorContainer;
        text = label ?? 'Masada';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: AppText.caption.copyWith(color: fg, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
