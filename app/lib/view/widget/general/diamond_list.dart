import 'package:flutter/material.dart';

import '../../../utils/theme.dart';

/// Bulleted list matching `.diamond-list`: each item prefixed with a
/// primary-container ◆ marker, 1.5rem indent.
class DiamondList extends StatelessWidget {
  const DiamondList({super.key, required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12, top: 2),
                  child: Text(
                    '◆',
                    style: AppText.bodyMd.copyWith(
                      color: AppColors.primaryContainer,
                      fontSize: 12.8, // 0.8em of 16px
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: AppText.bodyMd.copyWith(color: AppColors.onSurface),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
