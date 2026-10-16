import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../controller/library_controllers/library_controller.dart';
import '../../../model/game.dart';
import '../../../service/api_service.dart';
import '../../../utils/theme.dart';
import '../../widget/general/double_divider.dart';
import '../../widget/general/linen_overlay.dart';
import '../../widget/general/tactile_card.dart';

/// Yeni Masa Kur — numbered step form (game, schedule, capacity, notes).
/// Pixel-faithful to `masaba_yeni_masa_g_ncellenmi/screen.png`.
class NewTableScreen extends StatefulWidget {
  const NewTableScreen({super.key});

  @override
  State<NewTableScreen> createState() => _NewTableScreenState();
}

class _NewTableScreenState extends State<NewTableScreen> {
  Game? _selectedGame;
  DateTime? _date;
  TimeOfDay? _time;
  final _locationController = TextEditingController();
  final _tableNoController = TextEditingController();
  final _notesController = TextEditingController();
  final List<TextEditingController> _ruleControllers = [];
  double _capacity = 4;
  bool _submitting = false;

  late final LibraryController _lib;

  @override
  void initState() {
    super.initState();
    // Reuse existing LibraryController (already seeded if library was visited);
    // put it if not registered yet.
    _lib = Get.put(LibraryController());
  }

  @override
  void dispose() {
    _locationController.dispose();
    _tableNoController.dispose();
    _notesController.dispose();
    for (final c in _ruleControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    if (_selectedGame == null || _date == null || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Oyun, tarih ve saat seçilmeli.'),
      ));
      return;
    }

    final scheduledAt = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    ).toUtc();

    final body = {
      'game_id': int.tryParse(_selectedGame!.id) ?? 0,
      'scheduled_at': scheduledAt.toIso8601String(),
      'location': _locationController.text.trim(),
      'table_no': _tableNoController.text.trim(),
      'capacity': _capacity.round(),
      'notes': _notesController.text.trim(),
      'house_rules': _ruleControllers
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
    };

    // Capture router before the await gap.
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _submitting = true);
    try {
      await ApiService.instance.createTable(body);
      router.go('/tables');
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Masa oluşturulamadı: $e'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
            constraints: const BoxConstraints(maxWidth: 768),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Yeni Masa Kur',
                  style: (isDesktop ? AppText.headlineLg : AppText.headlineLgMobile)
                      .copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Topluluğa yeni bir oyun oturumu açın.',
                  style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: DoubleDivider(),
                ),
                TactileCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _step(1, 'Oyun Seçimi', _gameStep()),
                      const SizedBox(height: AppSpacing.lg),
                      _step(2, 'Oturum Detayları', _scheduleStep(context)),
                      const SizedBox(height: AppSpacing.lg),
                      _step(3, 'Oyuncu Kapasitesi', _capacityStep()),
                      const SizedBox(height: AppSpacing.lg),
                      _step(4, 'Notlar & Gereksinimler', _notesStep()),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _actions(context),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _step(int number, String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$number',
                style: AppText.labelMd.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: AppText.headlineMd.copyWith(
                  fontSize: 18,
                  color: AppColors.onBackground,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        content,
      ],
    );
  }

  Widget _gameStep() {
    return Obx(() {
      final games = _lib.games.toList();
      return _GamePickerField(
        games: games,
        value: _selectedGame,
        onChanged: (g) => setState(() => _selectedGame = g),
        hintText: games.isEmpty ? 'Oyunlar yükleniyor...' : 'Kütüphaneden Seçiniz',
      );
    });
  }

  Widget _scheduleStep(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _PickerField(
                icon: Icons.calendar_today,
                label: _date == null
                    ? 'Tarih Seçin'
                    : DateFormat('d MMM yyyy', 'tr_TR').format(_date!),
                onTap: _pickDate,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _PickerField(
                icon: Icons.schedule,
                label: _time == null ? 'Saat Seçin' : _time!.format(context),
                onTap: _pickTime,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _FieldShell(
                child: TextField(
                  controller: _locationController,
                  style: AppText.bodyMd.copyWith(color: AppColors.onSurface),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Konum (Örn: Ana Salon)',
                    hintStyle:
                        AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _FieldShell(
                child: TextField(
                  controller: _tableNoController,
                  style: AppText.bodyMd.copyWith(color: AppColors.onSurface),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Masa No',
                    hintStyle:
                        AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _capacityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Maksimum oyuncu sayısı',
              style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Text(
                '${_capacity.round()}',
                style: AppText.labelMd.copyWith(
                  color: AppColors.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.surfaceContainerHighest,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.12),
          ),
          child: Slider(
            value: _capacity,
            min: 2,
            max: 8,
            divisions: 6,
            label: '${_capacity.round()}',
            onChanged: (v) => setState(() => _capacity = v),
          ),
        ),
      ],
    );
  }

  Widget _notesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldShell(
          child: TextField(
            controller: _notesController,
            maxLines: 4,
            style: AppText.bodyMd.copyWith(color: AppColors.onSurface),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: 'Senaryo, masa kuralları, beklentiler...',
              hintStyle: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Masa Kuralları',
          style: AppText.labelMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Oyuncuların uyması gereken özel kuralları ekleyin.',
          style: AppText.caption.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        ..._ruleControllers.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: _FieldShell(
                        child: TextField(
                          controller: entry.value,
                          style: AppText.bodyMd.copyWith(color: AppColors.onSurface),
                          decoration: InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: 'Kural ${entry.key + 1}',
                            hintStyle: AppText.bodyMd
                                .copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      onPressed: () => setState(() {
                        _ruleControllers[entry.key].dispose();
                        _ruleControllers.removeAt(entry.key);
                      }),
                      icon: const Icon(Icons.remove_circle_outline,
                          color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ),
        TextButton.icon(
          onPressed: () =>
              setState(() => _ruleControllers.add(TextEditingController())),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Kural Ekle'),
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
      ],
    );
  }

  Widget _actions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => context.go('/tables'),
          style: TextButton.styleFrom(foregroundColor: AppColors.onSurfaceVariant),
          child: Text('İptal', style: AppText.labelMd),
        ),
        const SizedBox(width: AppSpacing.sm),
        Material(
          color: _submitting ? AppColors.outline : AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: _submitting ? null : () => _submit(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                          color: AppColors.onPrimary, strokeWidth: 2),
                    )
                  : Text(
                      'Masayı Oluştur',
                      style: AppText.labelMd.copyWith(color: AppColors.onPrimary),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 19, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
  }
}

/// Recessed text-field shell matching the form inputs.
class _FieldShell extends StatelessWidget {
  const _FieldShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: child,
    );
  }
}

/// Anchored game picker with an in-overlay search field.
class _GamePickerField extends StatefulWidget {
  const _GamePickerField({
    required this.games,
    required this.value,
    required this.onChanged,
    this.hintText,
  });

  final List<Game> games;
  final Game? value;
  final ValueChanged<Game?> onChanged;
  final String? hintText;

  @override
  State<_GamePickerField> createState() => _GamePickerFieldState();
}

class _GamePickerFieldState extends State<_GamePickerField> {
  final LayerLink _link = LayerLink();
  final TextEditingController _searchCtrl = TextEditingController();
  OverlayEntry? _overlay;
  bool _open = false;

  @override
  void dispose() {
    _removeOverlay();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_open) {
      _close();
    } else {
      _openOverlay();
    }
  }

  void _openOverlay() {
    _searchCtrl.clear();
    _overlay = _buildOverlay();
    Overlay.of(context).insert(_overlay!);
    setState(() => _open = true);
  }

  void _close() {
    _removeOverlay();
    if (mounted) setState(() => _open = false);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  OverlayEntry _buildOverlay() {
    return OverlayEntry(
      builder: (context) {
        final size = (context.findRenderObject() as RenderBox?)?.size;
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _close,
                behavior: HitTestBehavior.translucent,
              ),
            ),
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              offset: const Offset(0, 56),
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: size?.width ?? 320,
                  child: Material(
                    color: AppColors.surfaceContainerLowest,
                    elevation: 6,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: StatefulBuilder(
                        builder: (context, setOverlayState) {
                          final query = _searchCtrl.text.trim().toLowerCase();
                          final filtered = query.isEmpty
                              ? widget.games
                              : widget.games
                                  .where((g) =>
                                      g.title.toLowerCase().contains(query))
                                  .toList();
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                child: TextField(
                                  controller: _searchCtrl,
                                  autofocus: true,
                                  onChanged: (_) => setOverlayState(() {}),
                                  style: AppText.bodyMd
                                      .copyWith(color: AppColors.onSurface),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: 'Ara...',
                                    hintStyle: AppText.bodyMd.copyWith(
                                        color: AppColors.onSurfaceVariant),
                                    prefixIcon: const Icon(Icons.search,
                                        size: 18,
                                        color: AppColors.onSurfaceVariant),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.lg),
                                      borderSide: const BorderSide(
                                          color: AppColors.outlineVariant),
                                    ),
                                  ),
                                ),
                              ),
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxHeight: 250),
                                child: filtered.isEmpty
                                    ? Padding(
                                        padding:
                                            const EdgeInsets.all(AppSpacing.md),
                                        child: Text(
                                          'Sonuç bulunamadı.',
                                          style: AppText.bodyMd.copyWith(
                                              color:
                                                  AppColors.onSurfaceVariant),
                                        ),
                                      )
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: filtered.length,
                                        itemBuilder: (context, index) {
                                          final game = filtered[index];
                                          return ListTile(
                                            dense: true,
                                            title: Text(
                                              game.title,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppText.bodyMd.copyWith(
                                                  color: AppColors.onSurface),
                                            ),
                                            onTap: () {
                                              widget.onChanged(game);
                                              _close();
                                            },
                                          );
                                        },
                                      ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.value;
    return CompositedTransformTarget(
      link: _link,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: _toggle,
        child: _FieldShell(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selected?.title ?? (widget.hintText ?? 'Seçiniz'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyMd.copyWith(
                    color: selected == null
                        ? AppColors.onSurfaceVariant
                        : AppColors.onSurface,
                  ),
                ),
              ),
              Icon(
                _open ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: _FieldShell(
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                label,
                style: AppText.bodyMd.copyWith(color: AppColors.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
