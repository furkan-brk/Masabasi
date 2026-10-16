enum MessageRole { user, assistant }

/// A single turn in the Oyun Ustası conversation.
class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.content,
    this.suggestedGames = const [],
  });

  final MessageRole role;
  final String content;
  final List<SuggestedGame> suggestedGames;

  Map<String, dynamic> toJson() => {
        'role': role == MessageRole.user ? 'user' : 'assistant',
        'content': content,
      };
}

/// A game recommendation embedded in an assistant message.
class SuggestedGame {
  const SuggestedGame({
    required this.title,
    required this.reason,
    required this.minPlayers,
    required this.maxPlayers,
    required this.durationMin,
  });

  final String title;
  final String reason;
  final int minPlayers;
  final int maxPlayers;
  final int durationMin;

  factory SuggestedGame.fromJson(Map<String, dynamic> j) => SuggestedGame(
        title: j['title'] ?? '',
        reason: j['reason'] ?? '',
        minPlayers: j['minPlayers'] ?? 1,
        maxPlayers: j['maxPlayers'] ?? 4,
        durationMin: j['durationMin'] ?? 60,
      );
}
