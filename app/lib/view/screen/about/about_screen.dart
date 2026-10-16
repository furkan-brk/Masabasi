import 'package:flutter/material.dart';

import '../../../utils/theme.dart';
import '../../widget/general/double_divider.dart';
import '../../widget/general/linen_overlay.dart';
import '../../widget/general/tactile_card.dart';

/// Hakkımızda — Masabaşı Oyun Kulübü tanıtım sayfası.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Başlık ──────────────────────────────────────────────────
                Text(
                  'Hakkımızda',
                  style: AppText.display.copyWith(color: AppColors.primary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                const Center(
                  child: SizedBox(
                    width: 96,
                    child: DoubleDivider(withDiamond: true),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Misyon ──────────────────────────────────────────────────
                const _Section(
                  icon: Icons.flag_outlined,
                  title: 'Misyonumuz',
                  body: 'Masabaşı Oyun Kulübü, Türkiye\'nin dört bir yanından '
                      'masa oyunu tutkunlarını bir araya getiren üye odaklı bir '
                      'topluluktur. Amacımız; strateji, kooperatif, rol yapma ve '
                      'parti oyunlarının tadını çıkarmak için sıcak, kapsayıcı bir '
                      'ortam yaratmak ve yeni başlayanlara deneyimli oyuncularla '
                      'buluşma fırsatı tanımaktır.',
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Nasıl çalışır ────────────────────────────────────────────
                const _Section(
                  icon: Icons.table_bar_outlined,
                  title: 'Nasıl Çalışır?',
                  body: 'Üyeler platform üzerinden açık masalara katılabilir veya '
                      'kendi oyun oturumlarını oluşturabilir. Her masa; tarih, konum, '
                      'kapasite ve oyun bilgisiyle listelenir. İsteğe bağlı oylama '
                      'sistemiyle topluluk hangi oyunun oynayacağına birlikte karar verir.',
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Kütüphane ────────────────────────────────────────────────
                const _Section(
                  icon: Icons.library_books_outlined,
                  title: 'Kulüp Kütüphanesi',
                  body: 'Kulüpte 200\'ü aşkın masa oyunu bulunmaktadır. Kütüphane '
                      'bölümünden oyunları filtreleyebilir, kompleksite ve oyuncu '
                      'sayısına göre arama yapabilirsiniz. Kütüphanedeki tüm oyunlar '
                      'üyelerin kullanımına açıktır.',
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── İletişim + Çalışma saatleri (yan yana desktop) ──────────
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _ContactCard()),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: _HoursCard()),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ContactCard(),
                      const SizedBox(height: AppSpacing.md),
                      _HoursCard(),
                    ],
                  ),

                const SizedBox(height: AppSpacing.xl),

                // ── Alt not ─────────────────────────────────────────────────
                Center(
                  child: Text(
                    '© 2024 Masabaşı Oyun Kulübü — Tüm hakları saklıdır.',
                    style: AppText.caption.copyWith(color: AppColors.onSurfaceVariant),
                    textAlign: TextAlign.center,
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
}

// ── Section block ──────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return TactileCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: AppText.headlineMd.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            style: AppText.bodyLg.copyWith(
              color: AppColors.onSurface,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Contact card ───────────────────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TactileCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mail_outline, size: 20, color: AppColors.secondary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'İletişim',
                style: AppText.headlineMd.copyWith(color: AppColors.onBackground),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const _InfoRow(Icons.mail_outline, 'info@masabasi.club'),
          const SizedBox(height: AppSpacing.xs),
          const _InfoRow(Icons.location_on_outlined, 'Kültür Mah. Oyun Sok. No:7, İstanbul'),
          const SizedBox(height: AppSpacing.xs),
          const _InfoRow(Icons.phone_outlined, '+90 (212) 000 00 00'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

// ── Hours card ─────────────────────────────────────────────────────────────────

class _HoursCard extends StatelessWidget {
  static const _hours = [
    ('Pazartesi – Cuma', '14:00 – 22:00'),
    ('Cumartesi', '10:00 – 23:00'),
    ('Pazar', '10:00 – 21:00'),
  ];

  @override
  Widget build(BuildContext context) {
    return TactileCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, size: 20, color: AppColors.secondary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Çalışma Saatleri',
                style: AppText.headlineMd.copyWith(color: AppColors.onBackground),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final (day, time) in _hours) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(day,
                    style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                Text(time,
                    style: AppText.bodyMd.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}
