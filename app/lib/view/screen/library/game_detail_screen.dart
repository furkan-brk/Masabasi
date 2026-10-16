import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../model/game.dart';
import '../../../service/api_service.dart';
import '../../../utils/theme.dart';
import '../../widget/general/double_divider.dart';
import '../../widget/general/linen_overlay.dart';
import '../../widget/general/status_seal.dart';

/// Oyun Detayı — oyun kapağı, meta bilgi, türler, açıklama ve kural notları.
class GameDetailScreen extends StatefulWidget {
  const GameDetailScreen({super.key, required this.gameId});

  final String gameId;

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  late Future<Game> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.instance.getGame(widget.gameId);
  }

  @override
  Widget build(BuildContext context) {
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
            child: FutureBuilder<Game>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return _ErrorView(onBack: () => context.go('/library'));
                }
                return _Content(game: snapshot.data!, isDesktop: isDesktop);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.game, required this.isDesktop});

  final Game game;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button
        TextButton.icon(
          onPressed: () => context.go('/library'),
          icon: const Icon(Icons.arrow_back, size: 18, color: AppColors.primary),
          label: Text(
            'Koleksiyona Dön',
            style: AppText.bodyMd.copyWith(color: AppColors.primary),
          ),
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
        ),
        const SizedBox(height: AppSpacing.md),

        // Main layout: desktop = side-by-side, mobile = stacked
        if (isDesktop)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover column (fixed width)
                SizedBox(
                  width: 280,
                  child: _CoverColumn(game: game),
                ),
                const SizedBox(width: AppSpacing.xl),
                // Info column (flex)
                Expanded(child: _InfoColumn(game: game)),
              ],
            ),
          )
        else ...[
          _CoverColumn(game: game),
          const SizedBox(height: AppSpacing.lg),
          _InfoColumn(game: game),
        ],

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _CoverColumn extends StatelessWidget {
  const _CoverColumn({required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cover image
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: CachedNetworkImage(
              imageUrl: game.coverUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  const ColoredBox(color: AppColors.surfaceContainerHigh),
              errorWidget: (_, __, ___) => const ColoredBox(
                color: AppColors.surfaceContainerHigh,
                child: Center(
                  child: Icon(Icons.casino_outlined, color: AppColors.outline, size: 48),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Availability seal
        Center(
          child: StatusSeal(
            kind: game.availability == GameAvailability.available
                ? SealKind.mevcut
                : SealKind.masada,
          ),
        ),
      ],
    );
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + divider
        Text(game.title, style: AppText.display.copyWith(color: AppColors.primary)),
        const SizedBox(height: AppSpacing.sm),
        const DoubleDivider(withDiamond: true, maxWidth: 420),
        const SizedBox(height: AppSpacing.lg),

        // Meta rows
        _MetaRow(
          icon: Icons.group_outlined,
          text: game.playersLabel,
        ),
        const SizedBox(height: AppSpacing.xs),
        _MetaRow(
          icon: Icons.schedule_outlined,
          text: game.durationText,
        ),
        const SizedBox(height: AppSpacing.xs),
        _MetaRow(
          icon: Icons.psychology,
          text: 'Zorluk: ${game.complexity.toStringAsFixed(1)}/5',
        ),
        const SizedBox(height: AppSpacing.md),

        // Genre chips
        if (game.genres.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final genre in game.genres)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Text(
                    genre.toUpperCase(),
                    style: AppText.caption.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Description
        if (game.description != null && game.description!.trim().isNotEmpty) ...[
          const _SectionHeader(label: 'Açıklama'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            game.description!.trim(),
            style: AppText.bodyMd.copyWith(
              color: AppColors.onSurface,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Rules notes
        if (game.rulesNotes != null && game.rulesNotes!.trim().isNotEmpty) ...[
          const _SectionHeader(label: 'Kurallar / Notlar'),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Text(
              game.rulesNotes!.trim(),
              style: AppText.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.6,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(text, style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppText.headlineMd.copyWith(color: AppColors.primaryContainer),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Oyun detayları yüklenemedi.',
            style: AppText.bodyLg.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.outlineVariant),
            ),
            child: const Text('Koleksiyona Dön'),
          ),
        ],
      ),
    );
  }
}
