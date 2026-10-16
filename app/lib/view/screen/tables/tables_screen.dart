import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../controller/table_controllers/table_controller.dart';
import '../../../utils/theme.dart';
import '../../widget/general/linen_overlay.dart';
import '../../widget/table/table_card.dart';

/// Oyun Masaları — open/mine tabs, responsive card grid.
/// Pixel-faithful to the table list `code.html`.
class TablesScreen extends StatelessWidget {
  const TablesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TableController());
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = AppBreakpoints.isDesktop(width);

    return LinenOverlay(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? AppSpacing.marginDesktop : AppSpacing.marginMobile,
          vertical: AppSpacing.gutter,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContent),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(controller: controller, isDesktop: isDesktop),
                const SizedBox(height: AppSpacing.lg),
                if (!isDesktop) ...[
                  _MobileNewTableButton(
                    onTap: () => context.go('/tables/new'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                _grid(context, controller),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _grid(BuildContext context, TableController controller) {
    return Obx(() {
      if (controller.loading.value) {
        return const Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        );
      }
      if (controller.error.value != null) {
        return _ErrorState(
          message: controller.error.value!,
          onRetry: controller.loadTables,
        );
      }
      final tables = controller.tables;
      if (tables.isEmpty) {
        return const _EmptyState();
      }

      final width = MediaQuery.sizeOf(context).width;
      final crossAxisCount = _columnsFor(width);
      // Tek sütunda kart daha geniş olduğu için biraz daha kısa duruyor;
      // çok sütunda başlık uzun olabileceğinden yükseklik artıyor.
      final cardHeight = crossAxisCount == 1 ? 240.0 : 245.0;

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tables.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: AppSpacing.gutter,
          crossAxisSpacing: AppSpacing.gutter,
          mainAxisExtent: cardHeight,
        ),
        itemBuilder: (context, index) {
          final table = tables[index];
          return TableCard(
            table: table,
            onTap: () => context.go('/tables/${table.id}'),
            onJoin: () => context.go('/tables/${table.id}'),
          );
        },
      );
    });
  }

  int _columnsFor(double width) {
    if (width >= AppBreakpoints.lg) return 3;
    if (width >= AppBreakpoints.md) return 2;
    return 1;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller, required this.isDesktop});

  final TableController controller;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Oyun Masaları',
          style: (isDesktop ? AppText.headlineLg : AppText.headlineLgMobile)
              .copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Yeni bir masa kurun veya mevcut bir maceraya katılın.',
          style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );

    final tabs = _TabSwitcher(controller: controller);

    return Container(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: titleBlock),
                tabs,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleBlock,
                const SizedBox(height: AppSpacing.sm),
                tabs,
              ],
            ),
    );
  }
}

class _TabSwitcher extends StatelessWidget {
  const _TabSwitcher({required this.controller});

  final TableController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Obx(() {
        final active = controller.activeTab.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TabButton(
              label: 'Açık Masalar',
              active: active == 'open',
              onTap: () => controller.setTab('open'),
            ),
            _TabButton(
              label: 'Benim Masalarım',
              active: active == 'mine',
              onTap: () => controller.setTab('mine'),
            ),
          ],
        );
      }),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: active ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            boxShadow: active
                ? const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: AppText.labelMd.copyWith(
              color: active ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileNewTableButton extends StatelessWidget {
  const _MobileNewTableButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, size: 18, color: AppColors.onPrimary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Yeni Masa Kur',
                style: AppText.labelMd.copyWith(color: AppColors.onPrimary),
              ),
            ],
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
          const Icon(Icons.event_busy, size: 48, color: AppColors.outline),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Henüz açık masa yok.',
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
