import 'package:get/get.dart';

import '../../model/chat_message.dart';
import '../../service/api_service.dart';

/// Drives the AI Oyun Ustası chat screen.
class GamemasterController extends GetxController {
  static const String _welcome =
      'Hoş geldiniz! Kaç kişi olduğunuzu ve bugün ne tür bir oyun aradığınızı '
      'söyleyebilir misiniz?';

  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxString inputText = ''.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    messages.add(const ChatMessage(role: MessageRole.assistant, content: _welcome));
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || isLoading.value) return;

    messages.add(ChatMessage(role: MessageRole.user, content: trimmed));
    inputText.value = '';
    isLoading.value = true;

    try {
      final res = await ApiService.instance.gamemasterChat(messages.toList());
      final content = res['text'] as String? ?? '';
      final games = (res['suggestedGames'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(SuggestedGame.fromJson)
              .toList() ??
          const <SuggestedGame>[];
      messages.add(ChatMessage(
        role: MessageRole.assistant,
        content: content,
        suggestedGames: games,
      ));
    } catch (_) {
      messages.add(const ChatMessage(
        role: MessageRole.assistant,
        content: 'Bir hata oluştu. Lütfen tekrar deneyin.',
      ));
    } finally {
      isLoading.value = false;
    }
  }
}
