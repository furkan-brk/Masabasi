part of '../api_service.dart';

mixin NotificationsApi on ApiBase {
  Future<List<NotificationItem>> getNotifications() async {
    final res = await dio.get('/notifications');
    return (res.data as List<dynamic>)
        .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAllRead() async {
    await dio.post('/notifications/read-all');
  }

  Future<void> acceptInvite(int id) async {
    await dio.post('/notifications/$id/accept');
  }

  Future<void> rejectInvite(int id) async {
    await dio.post('/notifications/$id/reject');
  }
}
