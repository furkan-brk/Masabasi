import 'package:get/get.dart';

import '../../model/notification_item.dart';
import '../../service/api_service.dart';

class NotificationController extends GetxController {
  final _api = ApiService.instance;

  final notifications = <NotificationItem>[].obs;
  final isLoading = false.obs;
  final error = Rxn<String>();

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      notifications.value = await _api.getNotifications();
    } catch (e) {
      error.value = 'Bildirimler yüklenemedi';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAllRead() async {
    try {
      await _api.markAllRead();
      notifications.value = notifications
          .map((n) => NotificationItem(
                id: n.id,
                memberId: n.memberId,
                type: n.type,
                title: n.title,
                body: n.body,
                link: n.link,
                tableId: n.tableId,
                readAt: n.readAt ?? DateTime.now().toIso8601String(),
                actioned: n.actioned,
                createdAt: n.createdAt,
              ))
          .toList();
    } catch (_) {}
  }

  Future<void> acceptInvite(int id) async {
    try {
      await _api.acceptInvite(id);
      _removeNotification(id);
    } catch (_) {}
  }

  Future<void> rejectInvite(int id) async {
    try {
      await _api.rejectInvite(id);
      _removeNotification(id);
    } catch (_) {}
  }

  void _removeNotification(int id) {
    notifications.removeWhere((n) => n.id == id);
  }
}
