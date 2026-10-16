import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controller/vote_controllers/vote_controller.dart';
import '../../../model/vote.dart';
import '../../../utils/theme.dart';
import '../../widget/general/double_divider.dart';
import '../../widget/general/linen_overlay.dart';
import '../../widget/general/tactile_card.dart';

class VoteScreen extends StatelessWidget {
  const VoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => VoteController());
    final ctrl = Get.find<VoteController>();
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = AppBreakpoints.isDesktop(width);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.marginDesktop : AppSpacing.gutter,
        vertical: AppSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContent),
        child: Obx(() {
          if (ctrl.isLoading.value && ctrl.poll.value == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(80),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }
          if (ctrl.poll.value == null) {
            return _EmptyVote(error: ctrl.error.value);
          }
          return _PollBody(ctrl: ctrl);
        }),
      ),
    );
  }
}

class _PollBody extends StatelessWidget {
  const _PollBody({required this.ctrl});

  final VoteController ctrl;

  @override
  Widget build(BuildContext context) {
    final poll = ctrl.poll.value!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(poll),
        const SizedBox(height: AppSpacing.xl),
        const DoubleDivider(),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Text(
              '◆',
              style: AppText.bodyMd.copyWith(
                color: AppColors.primaryContainer,
                fontSize: 12.8,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'OYUN SEÇENEKLERİ',
              style: AppText.labelMd.copyWith(
                color: AppColors.onSurfaceVariant,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Obx(() {
          final voted = ctrl.hasVoted.value;
          return LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final crossCount = w > 800 ? 3 : (w > 500 ? 2 : 1);
              // Tek sütunda aspect ratio 0.68 kartları çok uzatıyor; dar ekranlarda
              // daha geniş bir oran kullan.
              final aspectRatio = crossCount == 1 ? 1.3 : 0.68;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossCount,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: aspectRatio,
                ),
                itemCount: poll.options.length,
                itemBuilder: (context, i) => _OptionCard(
                  option: poll.options[i],
                  totalVotes: poll.totalVotes,
                  isSelected: ctrl.myOptionId.value == poll.options[i].id,
                  showResults: voted,
                  onVote: voted ? null : () => ctrl.castVote(poll.options[i].id),
                ),
              );
            },
          );
        }),
        const SizedBox(height: AppSpacing.xl),
        const DoubleDivider(),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: Text(
            '© 2024 Masabaşı Oyun Kulübü · Tüm Hakları Saklıdır',
            style: AppText.caption.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _header(VotePoll poll) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = AppBreakpoints.isMobile(constraints.maxWidth);
        final iconSize = isMobile ? 44.0 : 56.0;
        final titleStyle = isMobile
            ? AppText.headlineLgMobile.copyWith(color: AppColors.primary)
            : AppText.headlineLg.copyWith(color: AppColors.primary);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(Icons.casino, color: AppColors.onPrimary, size: isMobile ? 22 : 28),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    poll.title.isEmpty ? 'Haftanın Oyun Gecesi' : poll.title,
                    style: titleStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    poll.description.isEmpty
                        ? 'Masabaşı Oyun Kulübü\'nün haftalık etkinliği için oyunlarımızı seçin.'
                        : poll.description,
                    style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.option,
    required this.totalVotes,
    required this.isSelected,
    required this.showResults,
    this.onVote,
  });

  final VoteOption option;
  final int totalVotes;
  final bool isSelected;
  final bool showResults;
  final VoidCallback? onVote;

  @override
  Widget build(BuildContext context) {
    final game = option.game;
    final pct = totalVotes == 0 ? 0.0 : option.voteCount / totalVotes;

    return TactileCard(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.hardEdge,
      topBorder: isSelected
          ? const Border(
              top: BorderSide(color: AppColors.primaryContainer, width: 4))
          : null,
      child: LinenOverlay(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            Expanded(
              child: Container(
                width: double.infinity,
                color: AppColors.surfaceContainerHigh,
                child: game?.coverImageUrl.isNotEmpty == true
                    ? Image.network(
                        game!.coverImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const _CoverPlaceholder(),
                      )
                    : const _CoverPlaceholder(),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game?.title ?? 'Bilinmiyor',
                    style: AppText.headlineMd.copyWith(
                      color: AppColors.primary,
                      fontSize: 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (game != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.group, size: 13,
                            color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Text(
                          '${game.minPlayers}-${game.maxPlayers}',
                          style: AppText.caption
                              .copyWith(color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Icon(Icons.timer_outlined, size: 13,
                            color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Text(
                          '${game.durationMin} dk.',
                          style: AppText.caption
                              .copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                  if (showResults) ...[
                    const SizedBox(height: AppSpacing.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: AppColors.surfaceContainerHigh,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isSelected
                              ? AppColors.primaryContainer
                              : AppColors.secondary,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${option.voteCount} oy (${(pct * 100).round()}%)',
                      style: AppText.caption
                          .copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onVote,
                      icon: Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.how_to_vote_outlined,
                        size: 16,
                      ),
                      label: Text(
                        showResults
                            ? (isSelected ? 'Oyunuz' : 'Sonuç')
                            : 'Oy Ver',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isSelected
                            ? AppColors.primaryContainer
                            : AppColors.onSurface,
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primaryContainer
                              : AppColors.outline,
                        ),
                        padding:
                            const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                    ),
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

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.image_outlined, size: 40, color: AppColors.outline),
    );
  }
}

class _EmptyVote extends StatelessWidget {
  const _EmptyVote({this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.how_to_vote_outlined,
                size: 56, color: AppColors.outline),
            const SizedBox(height: AppSpacing.md),
            Text(
              error != null ? 'Oylama yüklenemedi' : 'Henüz oylama yok',
              style: AppText.headlineMd.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              error ?? 'Yeni bir oylama açıldığında burada görüntülenecek.',
              style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
