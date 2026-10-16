part of '../api_service.dart';

mixin VotesApi on ApiBase {
  Future<VotePoll?> getCurrentPoll() async {
    final res = await dio.get('/votes/current');
    if (res.statusCode == 404) return null;
    return VotePoll.fromJson(res.data as Map<String, dynamic>);
  }

  Future<VotePoll> castVote(int pollId, int optionId) async {
    final res = await dio.post(
      '/votes/$pollId/cast',
      data: {'option_id': optionId},
    );
    return VotePoll.fromJson(res.data as Map<String, dynamic>);
  }

  Future<VotePoll> getPollResults(int pollId) async {
    final res = await dio.get('/votes/$pollId/results');
    return VotePoll.fromJson(res.data as Map<String, dynamic>);
  }

  // ── Admin endpoints ────────────────────────────────────────────────────────

  /// Creates a new poll (admin-only). Sends `game_ids` as the option list.
  Future<VotePoll> createPoll({
    required String title,
    required String description,
    required DateTime endsAt,
    required List<int> gameIds,
  }) async {
    final res = await dio.post<Map<String, dynamic>>(
      '/votes',
      data: {
        'title': title,
        'description': description,
        // Seçilen tarihin yerel gün-sonu (23:59:59) UTC'ye çevrilir.
        // Böylece "bugün" seçimi geçmişte kalmaz ve anket tam gün boyunca açık kalır.
        'ends_at': DateTime(endsAt.year, endsAt.month, endsAt.day, 23, 59, 59)
            .toUtc()
            .toIso8601String(),
        'game_ids': gameIds,
      },
    );
    return VotePoll.fromJson(res.data ?? const {});
  }

  /// Lists all polls (admin-only).
  Future<List<VotePoll>> listPolls() async {
    final res = await dio.get<List<dynamic>>('/votes');
    return (res.data ?? const [])
        .map((e) => VotePoll.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
