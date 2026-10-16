import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../model/game_table.dart';
import '../../../utils/theme.dart';
import '../general/linen_overlay.dart';
import '../general/player_slots.dart';

/// Oyun masası kart — Stitch "aktif_oyun_masalar" HTML'ine birebir.
///
/// Layout:
///   Header  (cover 64×80 | başlık + initials-circle host)  — border-bottom
///   Katılımcılar (avatar stack + boş "+" çemberler)          — border-bottom
///   Footer  (tarih + kapasite dots+sayı | Katıl/İzle butonu)
class TableCard extends StatefulWidget {
  const TableCard({super.key, required this.table, this.onTap, this.onJoin});

  final GameTable table;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;

  @override
  State<TableCard> createState() => _TableCardState();
}

class _TableCardState extends State<TableCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final table = widget.table;
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
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
            boxShadow: _hovering
                ? const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 6,
                      offset: Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              // Keten doku
              const Positioned.fill(
                child: LinenOverlay(baseColor: Colors.transparent, child: SizedBox.expand()),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(table),
                    const SizedBox(height: AppSpacing.xs),
                    Expanded(child: _participantsSection(table)),
                    const SizedBox(height: AppSpacing.xs),
                    _footer(table),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header: kapak + başlık + host ────────────────────────────────────────

  Widget _header(GameTable table) {
    return Container(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cover(table),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  table.game?.title ?? 'Oyun',
                  style: AppText.headlineMd.copyWith(
                    fontSize: 18,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                _hostRow(table),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cover(GameTable table) {
    final url = table.game?.coverUrl ?? '';
    return Container(
      width: 64,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        border: Border.all(color: AppColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty
          ? const Center(
              child: Icon(Icons.casino_outlined, color: AppColors.outline, size: 24),
            )
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, __) => const ColoredBox(color: AppColors.surfaceContainerHighest),
              errorWidget: (_, __, ___) => const Center(
                child: Icon(Icons.casino_outlined, color: AppColors.outline, size: 24),
              ),
            ),
    );
  }

  Widget _hostRow(GameTable table) {
    final name = table.host?.name ?? '';
    final initials = _initials(name);
    return Row(
      children: [
        _initialsCircle(initials, size: 24, bg: AppColors.secondaryContainer, fg: AppColors.onSecondaryContainer),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            name,
            style: AppText.caption.copyWith(color: AppColors.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── Katılımcılar: avatar stack ────────────────────────────────────────────

  Widget _participantsSection(GameTable table) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.15)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KATILIMCILAR',
            style: AppText.caption.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          _avatarStack(table),
        ],
      ),
    );
  }

  Widget _avatarStack(GameTable table) {
    const slotSize = 28.0;
    const step = 20.0; // slotSize(28) - overlap(8)
    const maxVisible = 4;

    Widget buildSlot({required bool filled, String name = '', String avatarUrl = ''}) {
      if (filled) {
        return Container(
          width: slotSize,
          height: slotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.surface, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: avatarUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: avatarUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _initialsCircle(
                    _initials(name),
                    size: slotSize,
                    bg: AppColors.surfaceContainerHigh,
                    fg: AppColors.onSurface,
                  ),
                )
              : _initialsCircle(
                  _initials(name),
                  size: slotSize,
                  bg: AppColors.surfaceContainerHigh,
                  fg: AppColors.onSurface,
                ),
        );
      }
      return Container(
        width: slotSize,
        height: slotSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceContainerHighest,
          border: Border.all(color: AppColors.outline, width: 1.5),
        ),
        child: const Icon(Icons.add, size: 14, color: AppColors.onSurfaceVariant),
      );
    }

    // Build filled + free slot list.
    final all = <Widget>[
      for (var i = 0; i < table.seatCount; i++)
        buildSlot(
          filled: true,
          name: table.seats.length > i ? table.seats[i].memberName : '',
          avatarUrl: table.seats.length > i ? (table.seats[i].memberAvatarUrl ?? '') : '',
        ),
      for (var i = 0; i < table.freeSeats; i++) buildSlot(filled: false),
    ];

    // When the backend returns no capacity info, show a placeholder row.
    if (all.isEmpty) {
      return Text(
        'Henüz katılımcı yok',
        style: AppText.caption.copyWith(
          color: AppColors.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final visible = all.take(maxVisible).toList();
    final overflowCount = all.length - visible.length;
    final totalItems = visible.length + (overflowCount > 0 ? 1 : 0);
    // Stack width: first item full width, remaining items offset by `step`.
    final stackWidth = totalItems <= 1 ? slotSize : (totalItems - 1) * step + slotSize;

    return SizedBox(
      height: slotSize,
      width: stackWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(left: i * step, child: visible[i]),
          if (overflowCount > 0)
            Positioned(
              left: visible.length * step,
              child: Container(
                width: slotSize,
                height: slotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceContainerHigh,
                  border: Border.all(color: AppColors.outline, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '+$overflowCount',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Footer: tarih + dots + buton ─────────────────────────────────────────

  Widget _footer(GameTable table) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      formatTableDate(table.scheduledAt),
                      style: AppText.caption.copyWith(color: AppColors.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  PlayerSlots(
                    filled: table.seatCount,
                    total: table.capacity,
                    size: 8,
                    gap: 4,
                    isFull: table.isFull,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${table.seatCount}/${table.capacity} Kişi',
                    style: AppText.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        _actionButton(table),
      ],
    );
  }

  Widget _actionButton(GameTable table) {
    if (table.isFull) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Text(
          'İzle',
          style: AppText.labelMd.copyWith(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      );
    }
    return Material(
      color: AppColors.secondary,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: widget.onJoin,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Text(
            'Katıl',
            style: AppText.labelMd.copyWith(color: AppColors.onSecondary),
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
  }

  Widget _initialsCircle(String initials, {required double size, required Color bg, required Color fg}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: size * 0.36,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ),
    );
  }
}

/// "Bugün, 19:00" / "24 Kas, 19:00"
String formatTableDate(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(dt.year, dt.month, dt.day);
  final time = DateFormat('HH:mm', 'tr_TR').format(dt);
  if (target == today) return 'Bugün, $time';
  if (target == today.add(const Duration(days: 1))) return 'Yarın, $time';
  return DateFormat('d MMM, HH:mm', 'tr_TR').format(dt);
}
