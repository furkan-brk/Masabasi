import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../controller/auth_controller.dart';
import '../../../controller/table_controllers/table_controller.dart';
import '../../../model/game_table.dart';
import '../../../service/api_service.dart';
import '../../../utils/theme.dart';
import '../../widget/general/diamond_list.dart';
import '../../widget/general/double_divider.dart';
import '../../widget/general/linen_overlay.dart';
import '../../widget/general/tactile_card.dart';
import '../../widget/general/tactile_inset.dart';

/// Masa Detayı — pixel-faithful to the premium `code.html`.
/// 8/4 split on desktop (cover + description + rules | status + host + roster),
/// single column on mobile.
class TableDetailScreen extends StatefulWidget {
  const TableDetailScreen({super.key, required this.tableId});

  final String tableId;

  @override
  State<TableDetailScreen> createState() => _TableDetailScreenState();
}

class _TableDetailScreenState extends State<TableDetailScreen> {
  late Future<GameTable> _future;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _future = ApiService.instance.getTable(widget.tableId);
  }

  /// Masa listesi controller'ı yeniler (varsa) — koltuk sayısı/durum tutarlı kalsın.
  void _refreshList() {
    if (Get.isRegistered<TableController>()) {
      Get.find<TableController>().loadTables();
    }
  }

  Future<void> _handleJoin() async {
    setState(() => _actionLoading = true);
    String? err;
    try {
      // joinTable 200 + güncel tablo döndürüyor — bunu doğrudan kullan,
      // ikinci getTable turu atmaya gerek yok.
      final updated = await ApiService.instance.joinTable(widget.tableId);
      if (!mounted) return;
      setState(() {
        _actionLoading = false;
        _future = Future.value(updated);
      });
      _refreshList();
      return;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 409) {
        final msg = e.response?.data?['error'] as String? ?? '';
        err = msg.contains('already') ? 'Zaten bu masadasın.' : 'Masa dolu.';
      } else if (status == 404) {
        err = 'Masa bulunamadı.';
      } else {
        err = 'Katılım başarısız oldu.';
      }
    } catch (_) {
      err = 'Katılım başarısız oldu.';
    }
    if (!mounted) return;
    setState(() => _actionLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err),
      backgroundColor: AppColors.error,
    ));
  }

  Future<void> _handleLeave() async {
    setState(() => _actionLoading = true);
    String? err;
    try {
      final updated = await ApiService.instance.leaveTable(widget.tableId);
      if (!mounted) return;
      setState(() {
        _actionLoading = false;
        _future = Future.value(updated);
      });
      _refreshList();
      return;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 403) {
        err = 'Masa sahibi masadan ayrılamaz.';
      } else if (status == 409) {
        err = 'Bu masada değilsiniz.';
      } else if (status == 404) {
        err = 'Masa bulunamadı.';
      } else {
        err = 'Ayrılma başarısız oldu.';
      }
    } catch (_) {
      err = 'Ayrılma başarısız oldu.';
    }
    if (!mounted) return;
    setState(() => _actionLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err),
      backgroundColor: AppColors.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = AppBreakpoints.isDesktop(width);

    return LinenOverlay(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? AppSpacing.marginDesktop : AppSpacing.marginMobile,
          vertical: AppSpacing.xl,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContent),
            child: FutureBuilder<GameTable>(
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
                  return _error();
                }
                return _content(context, snapshot.data!, isDesktop);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _error() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Masa bulunamadı.',
            style: AppText.bodyLg.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: () => context.go('/tables'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.outlineVariant),
            ),
            child: const Text('Masalara Dön'),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, GameTable table, bool isDesktop) {
    final auth = Get.find<AuthController>();
    final myId = auth.currentUser.value?.id ?? '';
    final isHost = table.hostId.toString() == myId;
    final isMember = table.seats.any((s) => s.memberId.toString() == myId);

    final left = _LeftColumn(table: table, isDesktop: isDesktop);
    final right = _RightColumn(
      table: table,
      isHost: isHost,
      isMember: isMember,
      actionLoading: _actionLoading,
      onJoin: _handleJoin,
      onLeave: _handleLeave,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _BackButton(),
        const SizedBox(height: AppSpacing.lg),
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 8, child: left),
              const SizedBox(width: AppSpacing.gutter),
              SizedBox(width: 350, child: right),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              left,
              const SizedBox(height: AppSpacing.md),
              right,
            ],
          ),
      ],
    );
  }
}

class _BackButton extends StatefulWidget {
  const _BackButton();

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final color = _hovering ? AppColors.primary : AppColors.onSurfaceVariant;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: () => context.go('/tables'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSlide(
              duration: const Duration(milliseconds: 200),
              offset: _hovering ? const Offset(-0.15, 0) : Offset.zero,
              child: Icon(Icons.arrow_back, size: 18, color: color),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Gelecek Oturumlara Dön',
              style: AppText.labelMd.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeftColumn extends StatelessWidget {
  const _LeftColumn({required this.table, required this.isDesktop});

  final GameTable table;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final game = table.game;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Cover(url: game?.coverUrl ?? ''),
        const SizedBox(height: AppSpacing.md),
        Text(
          '${game?.title ?? 'Oyun'} - Masa Detayı',
          style: (isDesktop ? AppText.headlineLg : AppText.headlineLgMobile)
              .copyWith(color: AppColors.primaryContainer),
        ),
        const SizedBox(height: AppSpacing.xs),
        _MetaRow(table: table),
        if (game != null && (game.complexity > 0 || (game.description != null && game.description!.trim().isNotEmpty))) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: DoubleDivider(),
          ),
          Text(
            'Oyun Hakkında',
            style: AppText.headlineMd.copyWith(color: AppColors.onBackground),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (game.complexity > 0)
            Row(
              children: [
                const Icon(Icons.psychology, size: 18, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'Zorluk: ${game.complexity.toStringAsFixed(1)}/5',
                  style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          if (game.description != null && game.description!.trim().isNotEmpty) ...[
            if (game.complexity > 0) const SizedBox(height: AppSpacing.xs),
            Text(
              game.description!.trim(),
              style: AppText.bodyMd.copyWith(color: AppColors.onSurface, height: 1.6),
            ),
          ],
        ],
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: DoubleDivider(),
        ),
        Text(
          'Oturum Hakkında',
          style: AppText.headlineMd.copyWith(color: AppColors.onBackground),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          table.notes.isEmpty
              ? 'Bu oturum için ek bir açıklama girilmemiş.'
              : table.notes,
          style: AppText.bodyLg.copyWith(color: AppColors.onSurface),
        ),
        if (table.houseRules.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _HouseRules(rules: table.houseRules),
        ],
        // Oyuncular bölümü — sol sütuna taşındı
        const SizedBox(height: AppSpacing.md),
        _ParticipantsCard(table: table),
      ],
    );
  }
}

class _Cover extends StatefulWidget {
  const _Cover({required this.url});

  final String url;

  @override
  State<_Cover> createState() => _CoverState();
}

class _CoverState extends State<_Cover> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: TactileInset(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOut,
                scale: _hovering ? 1.05 : 1,
                child: widget.url.isEmpty
                    ? const ColoredBox(
                        color: AppColors.surfaceDim,
                        child: Center(
                          child: Icon(Icons.casino_outlined,
                              color: AppColors.outline, size: 48),
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: widget.url,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            const ColoredBox(color: AppColors.surfaceDim),
                        errorWidget: (_, __, ___) => const ColoredBox(
                          color: AppColors.surfaceDim,
                          child: Center(
                            child: Icon(Icons.casino_outlined,
                                color: AppColors.outline, size: 48),
                          ),
                        ),
                      ),
              ),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.table});

  final GameTable table;

  @override
  Widget build(BuildContext context) {
    final game = table.game;
    final items = <Widget>[
      _metaItem(Icons.category, game?.genres.isNotEmpty == true ? game!.genres.first : 'Oyun'),
      if (game != null) _metaItem(Icons.schedule, game.durationText),
      if (game != null) _metaItem(Icons.group, game.playersLabel),
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          items[i],
          if (i < items.length - 1)
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.outlineVariant,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ],
    );
  }

  Widget _metaItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 2),
        Text(label, style: AppText.caption.copyWith(color: AppColors.onSurfaceVariant)),
      ],
    );
  }
}

class _HouseRules extends StatelessWidget {
  const _HouseRules({required this.rules});

  final List<String> rules;

  @override
  Widget build(BuildContext context) {
    return TactileCard(
      backgroundColor: AppColors.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gavel, size: 22, color: AppColors.primaryContainer),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  'Masa Kuralları (House Rules)',
                  style: AppText.headlineMd.copyWith(color: AppColors.primaryContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          DiamondList(items: rules),
        ],
      ),
    );
  }
}

class _RightColumn extends StatelessWidget {
  const _RightColumn({
    required this.table,
    required this.isHost,
    required this.isMember,
    required this.actionLoading,
    required this.onJoin,
    required this.onLeave,
  });

  final GameTable table;
  final bool isHost;
  final bool isMember;
  final bool actionLoading;
  final VoidCallback onJoin;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusCard(
          table: table,
          isHost: isHost,
          isMember: isMember,
          actionLoading: actionLoading,
          onJoin: onJoin,
          onLeave: onLeave,
        ),
        const SizedBox(height: AppSpacing.md),
        if (table.host != null) _HostCard(table: table),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.table,
    required this.isHost,
    required this.isMember,
    required this.actionLoading,
    required this.onJoin,
    required this.onLeave,
  });

  final GameTable table;
  final bool isHost;
  final bool isMember;
  final bool actionLoading;
  final VoidCallback onJoin;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final open = !table.isFull && table.status != TableStatus.bitti;
    return TactileCard(
      topBorder: const Border(
        top: BorderSide(color: AppColors.secondary, width: 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (open)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle,
                      size: 14, color: AppColors.onSecondaryContainer),
                  const SizedBox(width: 4),
                  Text(
                    'Kayıt Açık',
                    style: AppText.caption.copyWith(
                      color: AppColors.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Oturum Detayları',
            style: AppText.headlineMd.copyWith(color: AppColors.onBackground),
          ),
          const SizedBox(height: AppSpacing.md),
          _detailRow(Icons.calendar_today, _fullDate(table.scheduledAt)),
          const SizedBox(height: AppSpacing.sm),
          _detailRow(Icons.location_on, table.locationLabel),
          if (table.estimatedHours != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _detailRow(Icons.hourglass_empty, 'Tahmini ${table.estimatedHours} Saat'),
          ],
          const SizedBox(height: AppSpacing.lg),
          _actionWidget(open),
          if (open && !isMember && !isHost && table.freeSeats > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: Text(
                'Son ${table.freeSeats} boş koltuk',
                style: AppText.caption.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primaryContainer),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _actionWidget(bool open) {
    // Host can't leave — show a "you're the host" badge instead.
    if (isHost) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, size: 18, color: AppColors.secondary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Bu masanın ustasısın',
              style: AppText.labelMd.copyWith(color: AppColors.onSurface),
            ),
          ],
        ),
      );
    }

    // Already joined → show Leave button.
    if (isMember) {
      return Material(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: actionLoading ? null : onLeave,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (actionLoading)
                  const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        color: AppColors.onSurface, strokeWidth: 2),
                  )
                else ...[
                  const Icon(Icons.exit_to_app, size: 20, color: AppColors.onSurface),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Masadan Ayrıl',
                    style: AppText.labelMd.copyWith(color: AppColors.onSurface),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    // Not member — show Join or Full.
    if (!open) {
      return Opacity(
        opacity: 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.outline),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Center(
            child: Text(
              'Masa Dolu',
              style: AppText.labelMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
        ),
      );
    }

    return Material(
      color: AppColors.secondary,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: actionLoading ? null : onJoin,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (actionLoading)
                const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      color: AppColors.onSecondary, strokeWidth: 2),
                )
              else ...[
                const Icon(Icons.event_seat, size: 20, color: AppColors.onSecondary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Masaya Katıl',
                  style: AppText.labelMd.copyWith(color: AppColors.onSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _fullDate(DateTime dt) {
    return DateFormat('d MMMM EEEE, HH:mm', 'tr_TR').format(dt);
  }
}

class _HostCard extends StatelessWidget {
  const _HostCard({required this.table});

  final GameTable table;

  @override
  Widget build(BuildContext context) {
    final host = table.host!;
    return TactileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(label: 'Oyun Ustası'),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(url: host.avatarUrl, size: 48),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      host.name,
                      style: AppText.headlineMd
                          .copyWith(fontSize: 18, color: AppColors.onBackground),
                    ),
                    if (table.hostBio != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        table.hostBio!,
                        style:
                            AppText.caption.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ParticipantsCard extends StatelessWidget {
  const _ParticipantsCard({required this.table});

  final GameTable table;

  @override
  Widget build(BuildContext context) {
    final emptyCount = (table.capacity - table.seatCount).clamp(0, table.capacity);
    return TactileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(child: _SectionLabel(label: 'Katılımcılar')),
                Text(
                  '${table.seatCount}/${table.capacity}',
                  style: AppText.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final seat in table.seats) ...[
            _Participant(seat: seat),
            const SizedBox(height: AppSpacing.sm),
          ],
          for (var i = 0; i < emptyCount; i++) ...[
            const _EmptySeat(),
            if (i < emptyCount - 1) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _Participant extends StatelessWidget {
  const _Participant({required this.seat});

  final TableSeat seat;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _Avatar(url: seat.memberAvatarUrl, size: 40),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                seat.memberName,
                style: AppText.bodyMd.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.onBackground,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (seat.role != null)
                Text(
                  seat.role!,
                  style: AppText.caption.copyWith(color: AppColors.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptySeat extends StatelessWidget {
  const _EmptySeat();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.6,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.outlineVariant,
                style: BorderStyle.solid,
              ),
            ),
            child: const Icon(Icons.person_add,
                size: 18, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Boş Koltuk',
            style: AppText.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.size});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: (url == null || url!.isEmpty)
          ? Icon(Icons.person, size: size * 0.5, color: AppColors.onSurfaceVariant)
          : CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  const ColoredBox(color: AppColors.surfaceContainer),
              errorWidget: (_, __, ___) =>
                  Icon(Icons.person, size: size * 0.5, color: AppColors.onSurfaceVariant),
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppText.labelMd.copyWith(
        color: AppColors.onSurfaceVariant,
        letterSpacing: 1.0,
      ),
    );
  }
}
