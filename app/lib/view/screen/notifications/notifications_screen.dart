import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../controller/notification_controllers/notification_controller.dart';
import '../../../model/notification_item.dart';
import '../../../utils/theme.dart';
import '../../widget/general/double_divider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => NotificationController());
    final ctrl = Get.find<NotificationController>();
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = AppBreakpoints.isDesktop(width);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.marginDesktop : AppSpacing.gutter,
        vertical: AppSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContent),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(ctrl: ctrl),
            const SizedBox(height: AppSpacing.xl),
            const DoubleDivider(),
            const SizedBox(height: AppSpacing.xl),
            Obx(() {
              if (ctrl.isLoading.value && ctrl.notifications.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(60),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }
              if (ctrl.notifications.isEmpty) {
                return _EmptyState(error: ctrl.error.value);
              }
              return _NotificationList(ctrl: ctrl);
            }),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.ctrl});

  final NotificationController ctrl;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = AppBreakpoints.isMobile(width);

    final markAllButton = OutlinedButton.icon(
      onPressed: ctrl.markAllRead,
      icon: const Icon(Icons.done_all, size: 16),
      label: const Text('Tümünü Okundu İşaretle'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.secondary,
        side: const BorderSide(color: AppColors.secondary),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bildirimler',
          style: AppText.headlineLg.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 4),
        Text(
          'Oyun masalarınız ve kulüp güncellemeleri hakkında son gelişmeler.',
          style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleBlock,
          const SizedBox(height: AppSpacing.sm),
          markAllButton,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: AppSpacing.md),
        markAllButton,
      ],
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({required this.ctrl});

  final NotificationController ctrl;

  @override
  Widget build(BuildContext context) {
    final today = ctrl.notifications.where(_isToday).toList();
    final older = ctrl.notifications.where((n) => !_isToday(n)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (today.isNotEmpty) ...[
          _sectionHeader('Bugün'),
          const SizedBox(height: AppSpacing.md),
          ...today.map((n) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _NotificationTile(item: n, ctrl: ctrl),
              )),
        ],
        if (older.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _sectionHeader('Daha Eski'),
          const SizedBox(height: AppSpacing.md),
          ...older.map((n) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _NotificationTile(item: n, ctrl: ctrl),
              )),
        ],
        const SizedBox(height: AppSpacing.xl),
        const DoubleDivider(),
        const SizedBox(height: AppSpacing.md),
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

  Widget _sectionHeader(String label) {
    return Row(
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
          label,
          style: AppText.headlineMd.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }

  bool _isToday(NotificationItem n) {
    try {
      final dt = DateTime.parse(n.createdAt).toLocal();
      final now = DateTime.now();
      return dt.year == now.year &&
          dt.month == now.month &&
          dt.day == now.day;
    } catch (_) {
      return false;
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.ctrl});

  final NotificationItem item;
  final NotificationController ctrl;

  @override
  Widget build(BuildContext context) {
    final isUnread = !item.isRead;

    return Container(
      decoration: BoxDecoration(
        color: isUnread
            ? AppColors.primaryContainer.withValues(alpha: 0.06)
            : AppColors.surfaceContainerLowest,
        border: Border(
          left: BorderSide(
            color: isUnread ? AppColors.primaryContainer : Colors.transparent,
            width: 3,
          ),
          top: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.15)),
          right: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.15)),
          bottom: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.15)),
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(AppRadius.sm),
          bottomRight: Radius.circular(AppRadius.sm),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _avatar(item.type),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: AppText.bodyMd.copyWith(
                          fontWeight: isUnread
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      _relativeTime(item.createdAt),
                      style: AppText.caption
                          .copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
                if (item.body.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.body,
                    style: AppText.bodyMd
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
                if (item.isInvite && !item.actioned) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: () => ctrl.acceptInvite(item.id),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryContainer,
                          foregroundColor: AppColors.onPrimary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Kabul Et'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      OutlinedButton(
                        onPressed: () => ctrl.rejectInvite(item.id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.onSurfaceVariant,
                          side: BorderSide(
                            color: AppColors.outlineVariant
                                .withValues(alpha: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Reddet'),
                      ),
                    ],
                  ),
                ],
                if (!item.isInvite && item.link.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  GestureDetector(
                    onTap: () {
                      if (item.link.startsWith('/')) {
                        context.go(item.link);
                      }
                    },
                    child: Text(
                      'Oylamaya Git →',
                      style: AppText.labelMd
                          .copyWith(color: AppColors.primaryContainer),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(String type) {
    IconData icon;
    Color bg;
    switch (type) {
      case 'davet':
        icon = Icons.person_add_outlined;
        bg = AppColors.secondaryContainer;
      case 'oylama':
        icon = Icons.how_to_vote_outlined;
        bg = AppColors.surfaceContainerHigh;
      case 'masa-doldu':
        icon = Icons.group_outlined;
        bg = AppColors.surfaceContainerHigh;
      default:
        icon = Icons.notifications_outlined;
        bg = AppColors.surfaceContainerHigh;
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
    );
  }

  String _relativeTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
      if (diff.inHours < 24) return '${diff.inHours} saat önce';
      if (diff.inDays == 1) return 'Dün';
      return '${diff.inDays} gün önce';
    } catch (_) {
      return '';
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_none,
                size: 56, color: AppColors.outline),
            const SizedBox(height: AppSpacing.md),
            Text(
              error != null ? 'Bildirimler yüklenemedi' : 'Bildirim yok',
              style: AppText.headlineMd.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              error ?? 'Tüm bildirimler burada görüntülenecek.',
              style:
                  AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
