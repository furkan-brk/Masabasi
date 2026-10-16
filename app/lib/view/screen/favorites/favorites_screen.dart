import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controller/favorites_controllers/favorites_controller.dart';
import '../../../utils/theme.dart';
import '../../widget/general/double_divider.dart';
import '../../widget/general/linen_overlay.dart';
import '../../widget/library/game_card.dart';

/// Favorilerim screen — the user's bookmarked games in a card grid.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<FavoritesController>();
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = AppBreakpoints.isDesktop(width);

    return LinenOverlay(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? AppSpacing.gutter : AppSpacing.marginMobile,
          vertical: AppSpacing.gutter,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContent),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(),
                const SizedBox(height: AppSpacing.md),
                _grid(context, ctrl),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      children: [
        Text('Favorilerim', style: AppText.display.copyWith(color: AppColors.primary)),
        const SizedBox(height: AppSpacing.sm),
        const Center(child: DoubleDivider(withDiamond: true, maxWidth: 420)),
      ],
    );
  }

  Widget _grid(BuildContext context, FavoritesController ctrl) {
    return Obx(() {
      if (ctrl.loading.value) {
        return const Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        );
      }
      final games = ctrl.favorites;
      if (games.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              const Icon(Icons.bookmark_border, size: 48, color: AppColors.outline),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Henüz favori oyun eklemediniz.',
                style: AppText.bodyLg.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Kütüphaneden bir oyuna yer imi ekleyin.',
                style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        );
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final cols = _columnsFor(constraints.maxWidth);
          const spacing = AppSpacing.md;
          final colW = (constraints.maxWidth - spacing * (cols - 1)) / cols;
          final coverH = (colW * 11 / 16).clamp(0.0, 180.0);
          final cardH = coverH + 210;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: games.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              mainAxisExtent: cardH,
            ),
            itemBuilder: (context, index) {
              final game = games[index];
              return Obx(
                () => GameCard(
                  game: game,
                  coverHeight: coverH,
                  isFavorite: ctrl.isFavorite(game.id),
                  onToggleFavorite: () => ctrl.toggle(game),
                ),
              );
            },
          );
        },
      );
    });
  }

  int _columnsFor(double width) {
    if (width >= 1280) return 4;
    if (width >= 1024) return 3;
    if (width >= AppBreakpoints.md) return 2;
    if (width >= 560) return 2;
    return 1;
  }
}
