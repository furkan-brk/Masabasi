class VoteOption {
  final int id;
  final int pollId;
  final int gameId;
  final int displayOrder;
  final int voteCount;
  final VoteGame? game;

  const VoteOption({
    required this.id,
    required this.pollId,
    required this.gameId,
    required this.displayOrder,
    required this.voteCount,
    this.game,
  });

  factory VoteOption.fromJson(Map<String, dynamic> j) => VoteOption(
        id: j['id'] as int,
        pollId: j['poll_id'] as int,
        gameId: j['game_id'] as int,
        displayOrder: j['display_order'] as int? ?? 0,
        voteCount: j['vote_count'] as int? ?? 0,
        game: j['game'] != null
            ? VoteGame.fromJson(j['game'] as Map<String, dynamic>)
            : null,
      );
}

class VoteGame {
  final int id;
  final String title;
  final String coverImageUrl;
  final int minPlayers;
  final int maxPlayers;
  final int durationMin;
  final int complexity;

  const VoteGame({
    required this.id,
    required this.title,
    required this.coverImageUrl,
    required this.minPlayers,
    required this.maxPlayers,
    required this.durationMin,
    required this.complexity,
  });

  factory VoteGame.fromJson(Map<String, dynamic> j) => VoteGame(
        id: j['id'] as int,
        title: j['title'] as String? ?? '',
        coverImageUrl: j['cover_image_url'] as String? ?? '',
        minPlayers: j['min_players'] as int? ?? 1,
        maxPlayers: j['max_players'] as int? ?? 4,
        durationMin: j['duration_min'] as int? ?? 60,
        complexity: j['complexity'] as int? ?? 1,
      );
}

class VotePoll {
  final int id;
  final String title;
  final String description;
  final String endsAt;
  final String status;
  final List<VoteOption> options;

  const VotePoll({
    required this.id,
    required this.title,
    required this.description,
    required this.endsAt,
    required this.status,
    required this.options,
  });

  factory VotePoll.fromJson(Map<String, dynamic> j) => VotePoll(
        id: j['id'] as int,
        title: j['title'] as String? ?? '',
        description: j['description'] as String? ?? '',
        endsAt: j['ends_at'] as String? ?? '',
        status: j['status'] as String? ?? 'active',
        options: (j['options'] as List<dynamic>? ?? [])
            .map((e) => VoteOption.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  int get totalVotes => options.fold(0, (s, o) => s + o.voteCount);
}
