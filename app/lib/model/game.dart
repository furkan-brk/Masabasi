import 'dart:convert';

/// Availability state of a board game in the club library.
enum GameAvailability {
  available, // "Mevcut" — secondary seal
  onTable, // "Masada" — error seal
}

/// A board game in the club collection.
class Game {
  const Game({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.minPlayers,
    required this.maxPlayers,
    required this.durationMin,
    required this.complexity,
    required this.genres,
    this.durationLabel,
    this.description,
    this.rulesNotes,
    this.availability = GameAvailability.available,
  });

  final String id;
  final String title;
  final String coverUrl;
  final int minPlayers;
  final int maxPlayers;
  final int durationMin;

  /// 0–5 complexity ("Zorluk") score.
  final double complexity;
  final List<String> genres;

  /// Optional human label for duration ranges (e.g. "40-70dk").
  final String? durationLabel;

  /// Short description from BGG (up to 500 chars).
  final String? description;

  /// Curator / admin notes on rules, expansions, missing pieces, etc.
  final String? rulesNotes;

  final GameAvailability availability;

  String get playersLabel =>
      minPlayers == maxPlayers ? '$minPlayers Oyuncu' : '$minPlayers-$maxPlayers Oyuncu';

  String get durationText => durationLabel ?? '${durationMin}dk';

  factory Game.fromJson(Map<String, dynamic> json) {
    // Support both backend snake_case and legacy camelCase (mock data fallback).
    final rawId = json['ID'] ?? json['id'];
    final rawCover = json['cover_image_url'] ?? json['coverUrl'] ?? '';
    final rawMinP = json['min_players'] ?? json['minPlayers'];
    final rawMaxP = json['max_players'] ?? json['maxPlayers'];
    final rawDur = json['duration_min'] ?? json['durationMin'];

    // Backend genres field is a JSON-encoded array string, e.g. '["Strateji","Kart"]'.
    // Fallback: if it's already a List (mock data), use it directly.
    List<String> genres;
    final rawGenres = json['genres'];
    if (rawGenres is List) {
      genres = rawGenres.map((e) => e.toString()).toList();
    } else if (rawGenres is String && rawGenres.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawGenres);
        if (decoded is List) {
          genres = decoded.map((e) => e.toString()).toList();
        } else {
          genres = const [];
        }
      } catch (_) {
        genres = const [];
      }
    } else {
      genres = const [];
    }

    // owned_status → availability; camelCase fallback for mock.
    GameAvailability availability;
    final ownedStatus = json['owned_status'] as String?;
    final legacyAvail = json['availability'] as String?;
    if (ownedStatus != null) {
      availability =
          ownedStatus == 'Mevcut' ? GameAvailability.available : GameAvailability.onTable;
    } else {
      availability =
          legacyAvail == 'onTable' ? GameAvailability.onTable : GameAvailability.available;
    }

    return Game(
      id: rawId?.toString() ?? '',
      title: json['title'] as String? ?? '',
      coverUrl: rawCover.toString(),
      minPlayers: (rawMinP as num?)?.toInt() ?? 1,
      maxPlayers: (rawMaxP as num?)?.toInt() ?? 1,
      durationMin: (rawDur as num?)?.toInt() ?? 0,
      complexity: (json['complexity'] as num?)?.toDouble() ?? 0,
      genres: genres,
      durationLabel: json['durationLabel'] as String?,
      description: json['description'] as String?,
      rulesNotes: json['rules_notes'] as String?,
      availability: availability,
    );
  }


  /// Static mock list so the UI renders before the backend exists.
  static final List<Game> mockGames = [
    const Game(
      id: '1',
      title: 'Brass: Birmingham',
      coverUrl: 'https://placehold.co/240x300/e5e2db/570000?text=Brass',
      minPlayers: 2,
      maxPlayers: 4,
      durationMin: 120,
      complexity: 3.9,
      genres: ['Ekonomi', 'Ağ Kurma'],
      availability: GameAvailability.available,
    ),
    const Game(
      id: '2',
      title: 'Terraforming Mars',
      coverUrl: 'https://placehold.co/240x300/e5e2db/570000?text=Mars',
      minPlayers: 1,
      maxPlayers: 5,
      durationMin: 120,
      complexity: 3.2,
      genres: ['Motor Kurma', 'Bilim Kurgu'],
      availability: GameAvailability.onTable,
    ),
    const Game(
      id: '3',
      title: 'Wingspan',
      coverUrl: 'https://placehold.co/240x300/e5e2db/570000?text=Wingspan',
      minPlayers: 1,
      maxPlayers: 5,
      durationMin: 70,
      complexity: 2.4,
      genres: ['Kart Çekme', 'Doğa'],
      durationLabel: '40-70dk',
      availability: GameAvailability.available,
    ),
    const Game(
      id: '4',
      title: 'Gloomhaven',
      coverUrl: 'https://placehold.co/240x300/e5e2db/570000?text=Gloomhaven',
      minPlayers: 1,
      maxPlayers: 4,
      durationMin: 120,
      complexity: 3.9,
      genres: ['Zindan Tarama', 'Senaryo'],
      durationLabel: '60-120dk',
      availability: GameAvailability.available,
    ),
  ];
}
