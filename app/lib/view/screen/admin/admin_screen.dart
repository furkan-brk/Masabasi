import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controller/admin_controllers/admin_game_controller.dart';
import '../../../controller/admin_controllers/admin_table_controller.dart';
import '../../../controller/vote_controllers/admin_vote_controller.dart';
import '../../../model/game.dart';
import '../../../model/game_table.dart';
import '../../../model/vote.dart';
import '../../../utils/theme.dart';
import '../../widget/general/double_divider.dart';
import '../../widget/general/linen_overlay.dart';
import '../../widget/general/tactile_card.dart';
import '../../widget/table/table_card.dart';

/// 3-sekmeli admin paneli: Oylama | Oyunlar | Masalar
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = AppBreakpoints.isDesktop(width);

    return LinenOverlay(
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              isDesktop ? AppSpacing.gutter : AppSpacing.marginMobile,
              AppSpacing.lg,
              isDesktop ? AppSpacing.gutter : AppSpacing.marginMobile,
              0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContent),
                child: Column(
                  children: [
                    Text('Admin Paneli', style: AppText.display.copyWith(color: AppColors.primary), textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.sm),
                    const Center(child: DoubleDivider(withDiamond: true, maxWidth: 420)),
                    const SizedBox(height: AppSpacing.md),
                    TabBar(
                      controller: _tab,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelStyle: AppText.labelMd,
                      labelColor: AppColors.primaryContainer,
                      unselectedLabelColor: AppColors.onSurfaceVariant,
                      indicatorColor: AppColors.primaryContainer,
                      dividerColor: AppColors.outlineVariant,
                      tabs: const [
                        Tab(text: 'Oylama'),
                        Tab(text: 'Oyunlar'),
                        Tab(text: 'Masalar'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ── Tab content ─────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [
                _VotesTab(),
                _GamesTab(),
                _TablesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Oylama sekmesi (AdminVotesScreen içeriği buraya taşındı) ──────────────

class _VotesTab extends StatelessWidget {
  const _VotesTab();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(AdminVoteController());
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = AppBreakpoints.isDesktop(width);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.gutter : AppSpacing.marginMobile,
        vertical: AppSpacing.md,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContent),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PollList(ctrl: ctrl),
              const SizedBox(height: AppSpacing.xl),
              _CreatePollForm(ctrl: ctrl),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _PollList extends StatelessWidget {
  const _PollList({required this.ctrl});
  final AdminVoteController ctrl;

  @override
  Widget build(BuildContext context) {
    return TactileCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mevcut Anketler', style: AppText.headlineMd.copyWith(color: AppColors.primary)),
            const SizedBox(height: AppSpacing.sm),
            Obx(() {
              if (ctrl.loadingPolls.value) {
                return const Center(child: Padding(padding: EdgeInsets.all(AppSpacing.lg), child: CircularProgressIndicator(color: AppColors.primary)));
              }
              if (ctrl.polls.isEmpty) {
                return Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Text('Henüz anket yok.', style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant)));
              }
              return Column(children: [for (final p in ctrl.polls) _PollRow(poll: p)]);
            }),
          ],
        ),
      ),
    );
  }
}

class _PollRow extends StatelessWidget {
  const _PollRow({required this.poll});
  final VotePoll poll;

  @override
  Widget build(BuildContext context) {
    final isActive = poll.status == 'active';
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(poll.title, style: AppText.bodyLg.copyWith(color: AppColors.onSurface)),
              const SizedBox(height: 2),
              Text('${poll.totalVotes} oy · ${poll.endsAt.substring(0, 10)}', style: AppText.caption.copyWith(color: AppColors.onSurfaceVariant)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isActive ? AppColors.secondaryContainer : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              isActive ? 'Aktif' : poll.status,
              style: AppText.caption.copyWith(
                color: isActive ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatePollForm extends StatelessWidget {
  const _CreatePollForm({required this.ctrl});
  final AdminVoteController ctrl;

  @override
  Widget build(BuildContext context) {
    return TactileCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yeni Anket Oluştur', style: AppText.headlineMd.copyWith(color: AppColors.primary)),
            const SizedBox(height: AppSpacing.md),
            _LabeledField(label: 'Başlık', onChanged: (v) => ctrl.title.value = v),
            const SizedBox(height: AppSpacing.md),
            _LabeledField(label: 'Açıklama (isteğe bağlı)', onChanged: (v) => ctrl.description.value = v, maxLines: 3),
            const SizedBox(height: AppSpacing.md),
            Obx(() => _DateField(value: ctrl.endsAt.value, onPick: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) ctrl.endsAt.value = picked;
                })),
            const SizedBox(height: AppSpacing.md),
            Text('Oyunları Seç', style: AppText.labelMd.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.sm),
            Obx(() {
              final games = ctrl.allGames;
              if (games.isEmpty) return Text('Oyunlar yükleniyor...', style: AppText.caption.copyWith(color: AppColors.onSurfaceVariant));
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final game in games)
                    Obx(() {
                      final id = int.tryParse(game.id) ?? 0;
                      final selected = ctrl.isGameSelected(id);
                      return FilterChip(
                        label: Text(game.title),
                        selected: selected,
                        onSelected: (_) => ctrl.toggleGame(id),
                        selectedColor: AppColors.primaryContainer,
                        labelStyle: AppText.caption.copyWith(color: selected ? AppColors.onPrimary : AppColors.onSurfaceVariant),
                        checkmarkColor: AppColors.onPrimary,
                        side: BorderSide(color: selected ? AppColors.primary : AppColors.outlineVariant),
                      );
                    }),
                ],
              );
            }),
            const SizedBox(height: AppSpacing.lg),
            Obx(() => FilledButton(
                  onPressed: ctrl.submitting.value
                      ? null
                      : () async {
                          final err = await ctrl.createPoll();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(err ?? 'Anket oluşturuldu!'),
                            backgroundColor: err != null ? AppColors.error : null,
                          ));
                        },
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  child: ctrl.submitting.value
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: AppColors.onPrimary, strokeWidth: 2))
                      : Text('Anketi Oluştur', style: AppText.labelMd.copyWith(color: AppColors.onPrimary)),
                )),
          ],
        ),
      ),
    );
  }
}

// ── Oyunlar sekmesi ───────────────────────────────────────────────────────

class _GamesTab extends StatelessWidget {
  const _GamesTab();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(AdminGameController());
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = AppBreakpoints.isDesktop(width);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.gutter : AppSpacing.marginMobile,
        vertical: AppSpacing.md,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContent),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Yeni oyun butonu ─────────────────────────────────────
              FilledButton.icon(
                onPressed: () {
                  ctrl.clearForm();
                  _showGameDialog(context, ctrl);
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Yeni Oyun Ekle'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.md),
              // ── Oyun listesi ─────────────────────────────────────────
              Obx(() {
                if (ctrl.loading.value) return const Center(child: Padding(padding: EdgeInsets.all(AppSpacing.xl), child: CircularProgressIndicator(color: AppColors.primary)));
                if (ctrl.error.value != null) return Text(ctrl.error.value!, style: AppText.bodyMd.copyWith(color: AppColors.error));
                if (ctrl.games.isEmpty) return Text('Henüz oyun yok.', style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant));
                return Column(children: [
                  for (final game in ctrl.games)
                    _GameRow(
                      game: game,
                      onEdit: () {
                        ctrl.startEdit(game);
                        _showGameDialog(context, ctrl);
                      },
                      onDelete: () => _confirmDelete(context, 'Bu oyunu silmek istediğinize emin misiniz?', () async {
                        final err = await ctrl.deleteGame(game.id);
                        if (!context.mounted) return;
                        if (err != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
                      }),
                    ),
                ]);
              }),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  void _showGameDialog(BuildContext context, AdminGameController ctrl) {
    showDialog(
      context: context,
      builder: (_) => _GameFormDialog(ctrl: ctrl),
    );
  }

  void _confirmDelete(BuildContext context, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Onayla', style: AppText.headlineMd.copyWith(color: AppColors.onBackground)),
        content: Text(message, style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

class _GameRow extends StatelessWidget {
  const _GameRow({required this.game, required this.onEdit, required this.onDelete});
  final Game game;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(game.title, style: AppText.bodyLg.copyWith(color: AppColors.onSurface)),
              const SizedBox(height: 2),
              Text(
                '${game.minPlayers}-${game.maxPlayers} kişi · ${game.durationMin}dk · Zorluk ${game.complexity.toStringAsFixed(1)}',
                style: AppText.caption.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ]),
          ),
          IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.onSurfaceVariant), onPressed: onEdit, tooltip: 'Düzenle'),
          IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error), onPressed: onDelete, tooltip: 'Sil'),
        ],
      ),
    );
  }
}

class _GameFormDialog extends StatelessWidget {
  const _GameFormDialog({required this.ctrl});
  final AdminGameController ctrl;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(() => Text(
                    ctrl.editingId.value != null ? 'Oyunu Düzenle' : 'Yeni Oyun Ekle',
                    style: AppText.headlineMd.copyWith(color: AppColors.primary),
                  )),
              const SizedBox(height: AppSpacing.md),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _LabeledField(label: 'Oyun Adı *', initialValue: ctrl.title.value, onChanged: (v) => ctrl.title.value = v),
                      const SizedBox(height: AppSpacing.sm),
                      _LabeledField(label: 'Kapak URL', initialValue: ctrl.coverUrl.value, onChanged: (v) => ctrl.coverUrl.value = v),
                      const SizedBox(height: AppSpacing.sm),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final narrow = constraints.maxWidth < 360;
                          Widget minMax = narrow
                              ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                  _LabeledField(label: 'Min Kişi', initialValue: ctrl.minPlayers.value.toString(), onChanged: (v) => ctrl.minPlayers.value = int.tryParse(v) ?? 2, keyboardType: TextInputType.number),
                                  const SizedBox(height: AppSpacing.sm),
                                  _LabeledField(label: 'Max Kişi', initialValue: ctrl.maxPlayers.value.toString(), onChanged: (v) => ctrl.maxPlayers.value = int.tryParse(v) ?? 4, keyboardType: TextInputType.number),
                                ])
                              : Row(children: [
                                  Expanded(child: _LabeledField(label: 'Min Kişi', initialValue: ctrl.minPlayers.value.toString(), onChanged: (v) => ctrl.minPlayers.value = int.tryParse(v) ?? 2, keyboardType: TextInputType.number)),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(child: _LabeledField(label: 'Max Kişi', initialValue: ctrl.maxPlayers.value.toString(), onChanged: (v) => ctrl.maxPlayers.value = int.tryParse(v) ?? 4, keyboardType: TextInputType.number)),
                                ]);
                          Widget durComp = narrow
                              ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                  _LabeledField(label: 'Süre (dk)', initialValue: ctrl.durationMin.value.toString(), onChanged: (v) => ctrl.durationMin.value = int.tryParse(v) ?? 60, keyboardType: TextInputType.number),
                                  const SizedBox(height: AppSpacing.sm),
                                  _LabeledField(label: 'Zorluk (0-5)', initialValue: ctrl.complexity.value.toString(), onChanged: (v) => ctrl.complexity.value = double.tryParse(v) ?? 2.5, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                                ])
                              : Row(children: [
                                  Expanded(child: _LabeledField(label: 'Süre (dk)', initialValue: ctrl.durationMin.value.toString(), onChanged: (v) => ctrl.durationMin.value = int.tryParse(v) ?? 60, keyboardType: TextInputType.number)),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(child: _LabeledField(label: 'Zorluk (0-5)', initialValue: ctrl.complexity.value.toString(), onChanged: (v) => ctrl.complexity.value = double.tryParse(v) ?? 2.5, keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                                ]);
                          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [minMax, const SizedBox(height: AppSpacing.sm), durComp]);
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _LabeledField(label: 'Türler (JSON, örn: ["Strateji"])', initialValue: ctrl.genres.value, onChanged: (v) => ctrl.genres.value = v),
                      const SizedBox(height: AppSpacing.sm),
                      _LabeledField(label: 'Açıklama', initialValue: ctrl.description.value, onChanged: (v) => ctrl.description.value = v, maxLines: 3),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
                  const SizedBox(width: AppSpacing.sm),
                  Obx(() => FilledButton(
                        onPressed: ctrl.submitting.value
                            ? null
                            : () async {
                                final err = await ctrl.saveGame();
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                if (err != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
                              },
                        style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                        child: ctrl.submitting.value
                            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: AppColors.onPrimary, strokeWidth: 2))
                            : const Text('Kaydet'),
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Masalar sekmesi ──────────────────────────────────────────────────────

class _TablesTab extends StatelessWidget {
  const _TablesTab();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(AdminTableController());
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = AppBreakpoints.isDesktop(width);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.gutter : AppSpacing.marginMobile,
        vertical: AppSpacing.md,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContent),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Obx(() {
                if (ctrl.loading.value) return const Center(child: Padding(padding: EdgeInsets.all(AppSpacing.xl), child: CircularProgressIndicator(color: AppColors.primary)));
                if (ctrl.error.value != null) return Text(ctrl.error.value!, style: AppText.bodyMd.copyWith(color: AppColors.error));
                if (ctrl.tables.isEmpty) return Text('Henüz masa yok.', style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant));
                return Column(
                  children: [
                    for (final t in ctrl.tables)
                      _TableAdminRow(
                        table: t,
                        onDelete: () => _confirmDelete(context, '"${t.game?.title ?? "Masa"}" masasını silmek istediğinize emin misiniz?', () async {
                          final err = await ctrl.deleteTable(t.id.toString());
                          if (!context.mounted) return;
                          if (err != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.error));
                        }),
                      ),
                  ],
                );
              }),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Onayla', style: AppText.headlineMd.copyWith(color: AppColors.onBackground)),
        content: Text(message, style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

class _TableAdminRow extends StatelessWidget {
  const _TableAdminRow({required this.table, required this.onDelete});
  final GameTable table;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(table.game?.title ?? 'Oyun', style: AppText.bodyLg.copyWith(color: AppColors.onSurface)),
              const SizedBox(height: 2),
              Text(
                'Masa ${table.tableNo} · ${table.seatCount}/${table.capacity} kişi · ${formatTableDate(table.scheduledAt)}',
                style: AppText.caption.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: table.isFull ? AppColors.error.withValues(alpha: 0.15) : AppColors.secondaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              table.isFull ? 'Dolu' : 'Açık',
              style: AppText.caption.copyWith(
                color: table.isFull ? AppColors.error : AppColors.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error), onPressed: onDelete, tooltip: 'Masayı Sil'),
        ],
      ),
    );
  }
}

// ── Shared form widgets (sadece admin_screen'de kullanılır) ──────────────

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.onChanged,
    this.initialValue,
    this.maxLines = 1,
    this.keyboardType,
  });
  final String label;
  final ValueChanged<String> onChanged;
  final String? initialValue;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: AppText.bodyMd.copyWith(color: AppColors.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppText.labelMd.copyWith(color: AppColors.onSurfaceVariant),
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 2)),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.value, required this.onPick});
  final DateTime? value;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.outlineVariant),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: AppColors.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            Text(
              value != null ? '${value!.day}.${value!.month}.${value!.year}' : 'Bitiş tarihi seç',
              style: AppText.bodyMd.copyWith(color: value != null ? AppColors.onSurface : AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
