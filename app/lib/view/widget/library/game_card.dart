import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../model/game.dart';
import '../../../utils/theme.dart';
import '../general/status_seal.dart';

/// Collection card matching the library `.card-texture` article:
/// recessed cover slot + corner seal, title, players/duration/complexity
/// rows, and genre chips.
class GameCard extends StatefulWidget {
  const GameCard({
    super.key,
    required this.game,
    this.onTap,
    this.isFavorite = false,
    this.onToggleFavorite,
    this.coverHeight = 180,
  });

  final Game game;
  final double coverHeight;
  final VoidCallback? onTap;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hovering ? -2 : 0, 0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.onSurface.withValues(alpha: 0.10)),
            boxShadow: _hovering
                ? const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cover(game),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: AppText.headlineMd.copyWith(color: AppColors.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(height: 1, color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                    const SizedBox(height: 12),
                    _metaRow(game),
                    const SizedBox(height: 8),
                    _complexityRow(game),
                    const SizedBox(height: 16),
                    _genreChips(game),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cover(Game game) {
    return Stack(
      children: [
        SizedBox(
          height: widget.coverHeight,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              border: Border(
                bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
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
            child: game.coverUrl.isEmpty
                ? const Center(child: Icon(Icons.casino_outlined, color: AppColors.outline, size: 32))
                : CachedNetworkImage(
                    imageUrl: game.coverUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    httpHeaders: const {'Referer': 'https://boardgamegeek.com/'},
                    placeholder: (_, __) => const ColoredBox(color: AppColors.surfaceContainerHigh),
                    errorWidget: (_, __, ___) => const Center(
                      child: Icon(Icons.casino_outlined, color: AppColors.outline, size: 32),
                    ),
                  ),
          ),
        ),
        if (widget.onToggleFavorite != null)
          Positioned(
            top: 4,
            left: 4,
            // GestureDetector.behavior: opaque → inner tap wins the arena,
            // outer card tap (navigate) is NOT triggered when bookmark is tapped.
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onToggleFavorite,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x26000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.isFavorite ? Icons.bookmark : Icons.bookmark_border,
                    size: 20,
                    color: widget.isFavorite
                        ? AppColors.primaryContainer
                        : AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          top: 8,
          right: 8,
          child: StatusSeal(
            kind: game.availability == GameAvailability.available
                ? SealKind.mevcut
                : SealKind.masada,
          ),
        ),
      ],
    );
  }

  Widget _metaRow(Game game) {
    return DefaultTextStyle(
      style: AppText.caption.copyWith(color: AppColors.onSurfaceVariant),
      child: Row(
        children: [
          const Icon(Icons.group_outlined, size: 16, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(game.playersLabel),
          const SizedBox(width: 8),
          const Text('•'),
          const SizedBox(width: 8),
          const Icon(Icons.schedule_outlined, size: 16, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(game.durationText),
        ],
      ),
    );
  }

  Widget _complexityRow(Game game) {
    return Row(
      children: [
        const Icon(Icons.psychology, size: 16, color: AppColors.surfaceTint),
        const SizedBox(width: 6),
        Text(
          'Zorluk: ${game.complexity.toStringAsFixed(1)}/5',
          style: AppText.caption.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _genreChips(Game game) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final genre in game.genres)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Text(
              genre.toUpperCase(),
              style: AppText.caption.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
