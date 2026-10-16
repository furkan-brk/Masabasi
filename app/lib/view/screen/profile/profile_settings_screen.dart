// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../controller/auth_controller.dart';
import '../../../utils/theme.dart';
import '../../widget/general/double_divider.dart';
import '../../widget/general/linen_overlay.dart';
import '../../widget/general/tactile_card.dart';

/// Profil Ayarları — pixel-faithful to masaba_profil_ayarlar/screen.png.
///
/// Desktop (lg): 4/8 col split — avatar+status card sol, form sağ.
/// Mobile: tek sütun, form üstte avatar kartı.
class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  String _experience = 'intermediate'; // beginner | intermediate | expert

  final Map<String, bool> _genres = {
    'Strateji': false,
    'Rol Yapma (RPG)': false,
    'Parti Oyunları': false,
    'Kart Oyunları': false,
    'Kooperatif': false,
    'Zar Oyunları': false,
  };

  bool _saving = false;
  bool _avatarUploading = false;

  @override
  void initState() {
    super.initState();
    _hydrateFromCurrentUser();
  }

  void _hydrateFromCurrentUser() {
    final auth = Get.find<AuthController>();
    final user = auth.currentUser.value;
    if (user == null) return;

    _nameCtrl.text = user.name;
    _emailCtrl.text = user.email ?? '';
    _bioCtrl.text = user.bio ?? '';

    if (user.experienceLevel != null) {
      // Backend values: 'beginner', 'intermediate', 'expert' (or Turkish equivalents).
      final lvl = user.experienceLevel!.toLowerCase();
      if (lvl.contains('başlangıç') || lvl == 'beginner') {
        _experience = 'beginner';
      } else if (lvl.contains('ileri') || lvl.contains('expert') || lvl.contains('usta')) {
        _experience = 'expert';
      } else {
        _experience = 'intermediate';
      }
    }

    if (user.favoriteGenres != null && user.favoriteGenres!.isNotEmpty) {
      final saved = user.favoriteGenres!.split(',').map((s) => s.trim()).toSet();
      for (final key in _genres.keys.toList()) {
        _genres[key] = saved.contains(key);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = AppBreakpoints.isDesktop(width);

    return LinenOverlay(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? AppSpacing.marginDesktop : AppSpacing.marginMobile,
          vertical: AppSpacing.lg,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContent),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PageHeader(),
                const SizedBox(height: AppSpacing.lg),
                isDesktop ? _desktopLayout() : _mobileLayout(),
                const SizedBox(height: AppSpacing.lg),
                const Divider(color: AppColors.outlineVariant, height: 1),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Hesap',
                  style: AppText.headlineMd.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final router = GoRouter.of(context);
                      await Get.find<AuthController>().logout();
                      if (!mounted) return;
                      router.go('/auth/login');
                    },
                    icon: const Icon(Icons.logout, color: AppColors.error),
                    label: const Text('Çıkış Yap'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Layouts ───────────────────────────────────────────────────────────────

  Widget _desktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 300, child: _leftColumn()),
        const SizedBox(width: AppSpacing.gutter),
        Expanded(child: _rightColumn()),
      ],
    );
  }

  Widget _mobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _rightColumn(),
        const SizedBox(height: AppSpacing.md),
        _leftColumn(),
      ],
    );
  }

  // ── Left: Avatar + Club Status ────────────────────────────────────────────

  Widget _leftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AvatarCard(
          name: _nameCtrl.text,
          uploading: _avatarUploading,
          onPickPhoto: _pickAndUploadAvatar,
        ),
        const SizedBox(height: AppSpacing.md),
        _ClubStatusCard(),
      ],
    );
  }

  // ── Right: Form ───────────────────────────────────────────────────────────

  Widget _rightColumn() {
    return TactileCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FormSection(
            title: 'Kişisel Bilgiler',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    // 500px'ten dar ekranlarda iki alanı alt alta diz.
                    if (constraints.maxWidth < 500) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ParchmentField(
                            label: 'Kullanıcı Adı',
                            controller: _nameCtrl,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _ParchmentField(
                            label: 'E-posta',
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            readOnly: true,
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: _ParchmentField(
                            label: 'Kullanıcı Adı',
                            controller: _nameCtrl,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _ParchmentField(
                            label: 'E-posta',
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            readOnly: true,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _ParchmentField(
                  label: 'Hakkımda (Bio)',
                  controller: _bioCtrl,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _FormSection(
            title: 'Oyun Tercihleri',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ExperienceRadios(
                  value: _experience,
                  onChange: (v) => setState(() => _experience = v),
                ),
                const SizedBox(height: AppSpacing.md),
                _GenreCheckboxes(
                  genres: _genres,
                  onChange: (key, val) => setState(() => _genres[key] = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.outlineVariant, height: 1),
          const SizedBox(height: AppSpacing.md),
          _FormActions(
            saving: _saving,
            onCancel: () => context.mounted ? Navigator.of(context).pop() : null,
            onSave: _save,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final selectedGenres = _genres.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .join(',');

    final auth = Get.find<AuthController>();
    final err = await auth.updateProfile(
      displayName: _nameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      experienceLevel: _experience,
      favoriteGenres: selectedGenres,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err),
        backgroundColor: AppColors.error,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Profil kaydedildi.'),
      ));
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => _avatarUploading = true);
    final auth = Get.find<AuthController>();
    final err = await auth.uploadAvatar(file.bytes!, file.name);
    if (!mounted) return;
    setState(() => _avatarUploading = false);

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err),
        backgroundColor: AppColors.error,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil fotoğrafı güncellendi.')),
      );
    }
  }
}

// ── Page header ──────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profil Ayarları',
          style: AppText.display.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Kulüp içindeki kimliğinizi ve oyun tercihlerinizi düzenleyin. '
          'Bu bilgiler, diğer oyuncularla eşleşmenize yardımcı olacaktır.',
          style: AppText.bodyLg.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        const SizedBox(
          width: 96,
          child: DoubleDivider(),
        ),
      ],
    );
  }
}

// ── Avatar card ──────────────────────────────────────────────────────────────

class _AvatarCard extends StatefulWidget {
  const _AvatarCard({
    required this.name,
    required this.uploading,
    required this.onPickPhoto,
  });
  final String name;
  final bool uploading;
  final VoidCallback onPickPhoto;

  @override
  State<_AvatarCard> createState() => _AvatarCardState();
}

class _AvatarCardState extends State<_AvatarCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return TactileCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MouseRegion(
            cursor: widget.uploading
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovering = true),
            onExit: (_) => setState(() => _hovering = false),
            child: GestureDetector(
              onTap: widget.uploading ? null : widget.onPickPhoto,
              child: Obx(() {
                final avatarUrl =
                    Get.find<AuthController>().currentUser.value?.avatarUrl;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceContainerHighest,
                        border: Border.all(
                          color: AppColors.outline.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: (avatarUrl == null || avatarUrl.isEmpty)
                          ? const Center(
                              child: Icon(Icons.person,
                                  size: 64, color: AppColors.onSurfaceVariant),
                            )
                          : CachedNetworkImage(
                              imageUrl: avatarUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const ColoredBox(
                                  color: AppColors.surfaceContainerHighest),
                              errorWidget: (_, __, ___) => const Center(
                                child: Icon(Icons.person,
                                    size: 64, color: AppColors.onSurfaceVariant),
                              ),
                            ),
                    ),
                    if (widget.uploading)
                      Container(
                        width: 128,
                        height: 128,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0x66000000),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    else if (_hovering)
                      Container(
                        width: 128,
                        height: 128,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0x66000000),
                        ),
                        child: const Center(
                          child: Icon(Icons.photo_camera,
                              color: Colors.white, size: 28),
                        ),
                      ),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            widget.name,
            style: AppText.headlineMd.copyWith(color: AppColors.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: widget.uploading ? null : widget.onPickPhoto,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.onSurface,
              side: BorderSide(color: AppColors.onSurface.withValues(alpha: 0.2)),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
            ),
            child: widget.uploading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Fotoğrafı Değiştir', style: AppText.labelMd),
          ),
        ],
      ),
    );
  }
}

// ── Club status card ─────────────────────────────────────────────────────────

class _ClubStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TactileCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified, size: 20, color: AppColors.secondary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Kulüp Statüsü',
                style: AppText.labelMd.copyWith(color: AppColors.onSurface),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Aktif Oyuncu',
                style: AppText.bodyMd.copyWith(color: AppColors.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '2023\'ten beri üye',
            style: AppText.caption.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ── Form section ─────────────────────────────────────────────────────────────

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            child: Text(
              title,
              style: AppText.headlineMd.copyWith(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

// ── Parchment input field ─────────────────────────────────────────────────────

class _ParchmentField extends StatefulWidget {
  const _ParchmentField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
    this.readOnly = false,
  });
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool readOnly;

  @override
  State<_ParchmentField> createState() => _ParchmentFieldState();
}

class _ParchmentFieldState extends State<_ParchmentField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppText.labelMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Focus(
          onFocusChange: (f) => setState(() => _focused = f),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              border: _focused
                  ? Border.all(color: AppColors.onSurface)
                  : const Border(
                      bottom: BorderSide(color: AppColors.outline),
                    ),
              boxShadow: _focused
                  ? const [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      )
                    ]
                  : null,
            ),
            child: TextField(
              controller: widget.controller,
              maxLines: widget.maxLines,
              keyboardType: widget.keyboardType,
              readOnly: widget.readOnly,
              style: AppText.bodyMd.copyWith(
                color: widget.readOnly
                    ? AppColors.onSurfaceVariant
                    : AppColors.onSurface,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                isDense: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Experience radios ─────────────────────────────────────────────────────────

class _ExperienceRadios extends StatelessWidget {
  const _ExperienceRadios({required this.value, required this.onChange});
  final String value;
  final ValueChanged<String> onChange;

  static const _options = [
    ('beginner', 'Çırak (Başlangıç)'),
    ('intermediate', 'Maceracı (Orta)'),
    ('expert', 'Üstat (İleri)'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Oyun Deneyimi',
          style: AppText.labelMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: _options
              .map((opt) => _Radio(
                    label: opt.$2,
                    selected: value == opt.$1,
                    onTap: () => onChange(opt.$1),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<bool>(
            value: true,
            groupValue: selected,
            onChanged: (_) => onTap(),
            activeColor: AppColors.primaryContainer,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 4),
          Text(label, style: AppText.bodyMd.copyWith(color: AppColors.onSurface)),
        ],
      ),
    );
  }
}

// ── Genre checkboxes ──────────────────────────────────────────────────────────

class _GenreCheckboxes extends StatelessWidget {
  const _GenreCheckboxes({required this.genres, required this.onChange});
  final Map<String, bool> genres;
  final void Function(String key, bool val) onChange;

  @override
  Widget build(BuildContext context) {
    final keys = genres.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Favori Oyun Türleri',
          style: AppText.labelMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.xs),
        LayoutBuilder(builder: (context, constraints) {
          final cols = constraints.maxWidth > 480 ? 3 : 2;
          final rows = (keys.length / cols).ceil();
          return Column(
            children: List.generate(rows, (row) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: List.generate(cols, (col) {
                    final idx = row * cols + col;
                    if (idx >= keys.length) return const Expanded(child: SizedBox.shrink());
                    final key = keys[idx];
                    final checked = genres[key] ?? false;
                    return Expanded(
                      child: _CheckboxTile(
                        label: key,
                        checked: checked,
                        onChanged: (v) => onChange(key, v),
                      ),
                    );
                  }),
                ),
              );
            }),
          );
        }),
      ],
    );
  }
}

class _CheckboxTile extends StatelessWidget {
  const _CheckboxTile({required this.label, required this.checked, required this.onChanged});
  final String label;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!checked),
      child: Container(
        margin: const EdgeInsets.only(right: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: checked,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: AppColors.primaryContainer,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                side: const BorderSide(color: AppColors.outline),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: AppText.bodyMd.copyWith(color: AppColors.onSurface, fontSize: 14),
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

// ── Form actions ──────────────────────────────────────────────────────────────

class _FormActions extends StatelessWidget {
  const _FormActions({required this.saving, required this.onCancel, required this.onSave});
  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: onCancel,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.onSurface,
            side: BorderSide(color: AppColors.onSurface.withValues(alpha: 0.3)),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md + AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
          ),
          child: Text('İptal', style: AppText.labelMd),
        ),
        const SizedBox(width: AppSpacing.md),
        FilledButton(
          onPressed: saving ? null : onSave,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryContainer,
            foregroundColor: AppColors.onPrimary,
            disabledBackgroundColor: AppColors.surfaceContainerHigh,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md + AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
          ),
          child: saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onPrimary,
                  ),
                )
              : Text('Kaydet', style: AppText.labelMd.copyWith(color: AppColors.onPrimary)),
        ),
      ],
    );
  }
}
