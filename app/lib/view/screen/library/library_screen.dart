// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../controller/favorites_controllers/favorites_controller.dart';
import '../../../controller/library_controllers/library_controller.dart';
import '../../../utils/theme.dart';
import '../../widget/general/double_divider.dart';
import '../../widget/general/linen_overlay.dart';
import '../../widget/library/game_card.dart';

/// Koleksiyon / library screen — search, filter chips, title, card grid.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LibraryController());
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
                _SearchArea(controller: controller),
                const SizedBox(height: AppSpacing.lg),
                _header(),
                const SizedBox(height: AppSpacing.md),
                _grid(context, controller),
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
        Text('Koleksiyon', style: AppText.display.copyWith(color: AppColors.primary)),
        const SizedBox(height: AppSpacing.sm),
        const Center(child: DoubleDivider(withDiamond: true, maxWidth: 420)),
      ],
    );
  }

  Widget _grid(BuildContext context, LibraryController controller) {
    return Obx(() {
      if (controller.loading.value) {
        return const Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }
      if (controller.error.value != null) {
        return _ErrorState(message: controller.error.value!, onRetry: controller.loadGames);
      }
      final games = controller.filteredGames;
      if (games.isEmpty) {
        return const _EmptyState();
      }

      final fav = Get.find<FavoritesController>();

      return LayoutBuilder(
        builder: (context, constraints) {
          final cols = _columnsFor(constraints.maxWidth);
          const spacing = AppSpacing.md;
          final colW = (constraints.maxWidth - spacing * (cols - 1)) / cols;
          // Kare kapak: BGG kutu görselleri kare/dikey — 11/16 yatay kırpma
          // kutunun üst/altını kesiyordu. colW = 1:1 kare, BoxFit.cover tam oturur.
          final coverH = colW;
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
                  isFavorite: fav.isFavorite(game.id),
                  onToggleFavorite: () => fav.toggle(game),
                  onTap: () => context.go('/library/${game.id}'),
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

class _SearchArea extends StatelessWidget {
  const _SearchArea({required this.controller});

  final LibraryController controller;

  static const _chips = [
    'Ağır Strateji',
    '2 Kişilik',
    'Parti Oyunları',
    'Solo',
    'Hızlı (<45dk)',
    'Uzun Oyun (90dk+)',
    'Yeni Başlayan',
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 672), // max-w-2xl
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.inverseOnSurface,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: const Border(
                  bottom: BorderSide(color: AppColors.outlineVariant),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 4,
                    spreadRadius: -2,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: controller.setQuery,
                style: AppText.bodyLg.copyWith(color: AppColors.onSurface),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: AppColors.onSurfaceVariant),
                  suffixIcon: Obx(() {
                    final count = controller.activeFilterCount;
                    return GestureDetector(
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: AppColors.surface,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
                        ),
                        builder: (_) => _FilterSheet(controller: controller),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.tune,
                              color: count > 0
                                  ? AppColors.primaryContainer
                                  : AppColors.onSurfaceVariant,
                            ),
                            if (count > 0)
                              Positioned(
                                top: 8,
                                right: 0,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$count',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.onPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  hintText: 'Kütüphanede Ara... (Örn: Catan, Strateji, 4 Oyuncu)',
                  hintStyle: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Obx(
              () => Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final c in _chips)
                    _FilterChip(
                      label: c,
                      active: controller.isFilterActive(c),
                      onTap: () => controller.toggleFilter(c),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatefulWidget {
  const _FilterChip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.active;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary
                : (_hovering ? AppColors.surfaceVariant : AppColors.surfaceContainerLow),
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            widget.label,
            style: AppText.caption.copyWith(
              color: isActive ? AppColors.onPrimary : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 48, color: AppColors.outline),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Eşleşen oyun bulunamadı.',
            style: AppText.bodyLg.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: AppSpacing.sm),
          Text(message, style: AppText.bodyLg.copyWith(color: AppColors.onSurface)),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.outlineVariant),
            ),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({required this.controller});
  final LibraryController controller;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Text('Filtreler',
                      style: AppText.headlineMd.copyWith(color: AppColors.onBackground)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      controller.clearFilters();
                      Navigator.pop(context);
                    },
                    child:
                        Text('Temizle', style: AppText.labelMd.copyWith(color: AppColors.error)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _SheetSection(
                    label: 'Oyuncu Sayısı',
                    child: Obx(() {
                      final current = controller.playerCount.value;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final n in [2, 3, 4, 5, 6, 7, 8])
                            _SheetChip(
                              label: '$n kişi',
                              active: current == n,
                              onTap: () =>
                                  controller.playerCount.value = (current == n) ? null : n,
                            ),
                        ],
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SheetSection(
                    label: 'Zorluk',
                    child: Obx(() {
                      final cr = controller.complexityRange.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RangeSlider(
                            values: cr,
                            min: 0,
                            max: 5,
                            divisions: 10,
                            activeColor: AppColors.primaryContainer,
                            inactiveColor: AppColors.surfaceContainerHigh,
                            labels: RangeLabels(
                                cr.start.toStringAsFixed(1), cr.end.toStringAsFixed(1)),
                            onChanged: (v) => controller.complexityRange.value = v,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Kolay (${cr.start.toStringAsFixed(1)})',
                                  style: AppText.caption
                                      .copyWith(color: AppColors.onSurfaceVariant)),
                              Text('Ağır (${cr.end.toStringAsFixed(1)})',
                                  style: AppText.caption
                                      .copyWith(color: AppColors.onSurfaceVariant)),
                            ],
                          ),
                        ],
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SheetSection(
                    label: 'Maks. Süre',
                    child: Obx(() {
                      final cur = controller.maxDuration.value;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final entry
                              in {null: 'Tümü', 30: '≤30dk', 60: '≤60dk', 90: '≤90dk'}.entries)
                            _SheetChip(
                              label: entry.value,
                              active: cur == entry.key,
                              onTap: () => controller.maxDuration.value = entry.key,
                            ),
                        ],
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SheetSection(
                    label: 'Tür',
                    child: Obx(() {
                      final genres = controller.allGenres;
                      final selected = controller.selectedGenres;
                      if (genres.isEmpty) {
                        return Text('Tür yükleniyor...',
                            style:
                                AppText.caption.copyWith(color: AppColors.onSurfaceVariant));
                      }
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final g in genres)
                            _SheetChip(
                              label: g,
                              active: selected.contains(g),
                              onTap: () {
                                if (selected.contains(g)) {
                                  controller.selectedGenres.remove(g);
                                } else {
                                  controller.selectedGenres.add(g);
                                }
                              },
                            ),
                        ],
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SheetSection(
                    label: 'Durum',
                    child: Obx(() => SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Sadece müsait oyunlar',
                              style: AppText.bodyMd.copyWith(color: AppColors.onSurface)),
                          value: controller.onlyAvailable.value,
                          activeColor: AppColors.primaryContainer,
                          onChanged: (v) => controller.onlyAvailable.value = v,
                        )),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md,
                  MediaQuery.of(context).viewPadding.bottom + AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg)),
                  ),
                  child:
                      Text('Uygula', style: AppText.labelMd.copyWith(color: AppColors.onPrimary)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SheetSection extends StatelessWidget {
  const _SheetSection({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppText.caption.copyWith(
            color: AppColors.onSurfaceVariant,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        child,
      ],
    );
  }
}

class _SheetChip extends StatelessWidget {
  const _SheetChip({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryContainer : AppColors.surfaceContainerLow,
          border: Border.all(
              color: active ? AppColors.primaryContainer : AppColors.outlineVariant),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(
          label,
          style: AppText.caption.copyWith(
            color: active ? AppColors.onPrimary : AppColors.onSurfaceVariant,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
