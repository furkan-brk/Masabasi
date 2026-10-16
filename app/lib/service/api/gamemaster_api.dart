part of '../api_service.dart';

/// AI Oyun Ustası chat endpoint.
mixin GamemasterApi on ApiBase {
  Future<Map<String, dynamic>> gamemasterChat(List<ChatMessage> history) async {
    final res = await dio.post('/gamemaster/chat', data: {
      'history': history.map((m) => m.toJson()).toList(),
    });
    return res.data as Map<String, dynamic>;
  }
}
