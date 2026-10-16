import 'game.dart';
import 'member.dart';

/// A single occupied seat at a game table.
class TableSeat {
  const TableSeat({
    required this.id,
    required this.tableId,
    required this.memberId,
    required this.memberName,
    this.memberAvatarUrl,
    this.role,
  });

  final String id;
  final String tableId;
  final String memberId;
  final String memberName;
  final String? memberAvatarUrl;

  /// Optional in-game role label (e.g. "Seeker (Daisy Walker)").
  final String? role;

  factory TableSeat.fromJson(Map<String, dynamic> json) {
    // Backend: { ID, table_id, member_id, member: { display_name, avatar_url } }
    // camelCase fallbacks keep mock data compiling.
    final rawId = json['ID'] ?? json['id'];
    final rawTableId = json['table_id'] ?? json['tableId'];
    final rawMemberId = json['member_id'] ?? json['memberId'];

    // Nested member object from backend preload.
    final memberObj = json['member'] as Map<String, dynamic>?;
    final rawName = memberObj?['display_name'] ??
        memberObj?['name'] ??
        json['memberName'] ??
        '';
    final rawAvatar = memberObj?['avatar_url'] ??
        memberObj?['avatarUrl'] ??
        json['memberAvatarUrl'];

    return TableSeat(
      id: rawId?.toString() ?? '',
      tableId: rawTableId?.toString() ?? '',
      memberId: rawMemberId?.toString() ?? '',
      memberName: rawName.toString(),
      memberAvatarUrl: rawAvatar?.toString(),
      role: json['role'] as String?,
    );
  }
}

/// Status of a game table session.
enum TableStatus {
  bekliyor, // open for registration
  dolu, // full
  bitti, // finished
}

TableStatus _statusFromString(String? s) {
  switch (s) {
    case 'dolu':
      return TableStatus.dolu;
    case 'bitti':
      return TableStatus.bitti;
    default:
      return TableStatus.bekliyor;
  }
}

/// A scheduled game session ("masa").
class GameTable {
  const GameTable({
    required this.id,
    required this.gameId,
    required this.hostId,
    required this.scheduledAt,
    required this.location,
    required this.tableNo,
    required this.capacity,
    required this.notes,
    required this.status,
    required this.revisionId,
    this.houseRules = const [],
    this.estimatedHours,
    this.game,
    this.host,
    this.hostBio,
    this.seats = const [],
  });

  final String id;
  final String gameId;
  final String hostId;
  final DateTime scheduledAt;
  final String location;
  final String tableNo;
  final int capacity;
  final String notes;
  final TableStatus status;
  final int revisionId;

  final List<String> houseRules;
  final int? estimatedHours;

  final Game? game;
  final Member? host;
  final String? hostBio;
  final List<TableSeat> seats;

  int get seatCount => seats.length;
  bool get isFull => seatCount >= capacity;
  int get freeSeats => (capacity - seatCount).clamp(0, capacity);

  /// "Ana Salon, Masa 4"
  String get locationLabel => '$location, $tableNo';

  factory GameTable.fromJson(Map<String, dynamic> json) {
    // Backend returns snake_case with gorm.Model (ID field).
    // camelCase fallbacks keep mock data compiling.
    final rawId = json['ID'] ?? json['id'];
    final rawGameId = json['game_id'] ?? json['gameId'];
    final rawHostId = json['host_id'] ?? json['hostId'];
    final rawScheduled = json['scheduled_at'] ?? json['scheduledAt'];
    final rawTableNo = json['table_no'] ?? json['tableNo'];
    final rawRevision = json['revision_id'] ?? json['revisionId'];

    return GameTable(
      id: rawId?.toString() ?? '',
      gameId: rawGameId?.toString() ?? '',
      hostId: rawHostId?.toString() ?? '',
      scheduledAt: DateTime.tryParse(rawScheduled?.toString() ?? '') ?? DateTime.now(),
      location: json['location'] as String? ?? '',
      tableNo: rawTableNo?.toString() ?? '',
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String? ?? '',
      status: _statusFromString(json['status'] as String?),
      revisionId: (rawRevision as num?)?.toInt() ?? 0,
      houseRules: ((json['house_rules'] ?? json['houseRules']) as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      estimatedHours: (json['estimatedHours'] as num?)?.toInt(),
      game: json['game'] is Map<String, dynamic>
          ? Game.fromJson(json['game'] as Map<String, dynamic>)
          : null,
      host: json['host'] is Map<String, dynamic>
          ? Member.fromJson(json['host'] as Map<String, dynamic>)
          : null,
      hostBio: json['hostBio'] as String?,
      seats: (json['seats'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(TableSeat.fromJson)
              .toList() ??
          const [],
    );
  }

  /// Static mock list so the UI renders before the backend exists.
  /// Mirrors the Stitch reference (table list + premium detail).
  static final List<GameTable> mockTables = [
    GameTable(
      id: '1',
      gameId: '1',
      hostId: '1',
      scheduledAt: DateTime.now().add(const Duration(days: 1, hours: 3)),
      location: 'Ana Salon',
      tableNo: 'Masa 4',
      capacity: 4,
      notes:
          'Dunwich Mirası senaryosunun ikinci bölümüne geçiyoruz. İlk seansta '
          'yaşadığımız kayıplardan sonra, Miskatonic Üniversitesi\'nin tozlu '
          'koridorlarında aradığımız ipuçları bizi daha da karanlık sırlara '
          'götürecek. Dedektiflerinizin destelerini gözden geçirmeyi ve akıl '
          'sağlığınızı korumayı unutmayın. Bu oturumda hikaye ağırlıklı bir '
          'ilerleme hedefliyoruz, bu nedenle rol yapma (RP) ögelerine ekstra '
          'özen göstereceğiz.',
      status: TableStatus.bekliyor,
      revisionId: 1,
      estimatedHours: 3,
      houseRules: const [
        'Başlangıç mulligan\'ında zayıflık kartı gelirse, deste karıştırılıp '
            'bir hak daha verilir.',
        'Sıra dışı eylemler (fast actions) öncesinde gruba kısa bir RP '
            'açıklaması yapılmalıdır.',
        'Masada yiyecek bulundurmak serbesttir ancak kartların olduğu alandan '
            'uzak tutulmalıdır. İçecekler sadece kapaklı bardaklarda.',
        'Geç kalanlar için maksimum bekleme süresi 15 dakikadır.',
      ],
      game: const Game(
        id: '1',
        title: 'Arkham Horror: LCG',
        coverUrl: 'https://placehold.co/640x360/e5e2db/570000?text=Arkham',
        minPlayers: 1,
        maxPlayers: 4,
        durationMin: 180,
        complexity: 4,
        genres: ['Kooperatif'],
        durationLabel: '2-3 Saat',
      ),
      host: const Member(id: '1', name: 'Ömer Perivinkle'),
      hostBio:
          'Arkham LCG uzmanı, kural ustası ve Lovecraftian hikaye anlatıcısı. '
          'Hata affetmez.',
      seats: const [
        TableSeat(
          id: '1',
          tableId: '1',
          memberId: '2',
          memberName: 'Elif S.',
          role: 'Seeker (Daisy Walker)',
        ),
        TableSeat(
          id: '2',
          tableId: '1',
          memberId: '3',
          memberName: 'Can T.',
          role: 'Guardian (Roland Banks)',
        ),
        TableSeat(
          id: '3',
          tableId: '1',
          memberId: '4',
          memberName: 'Deniz K.',
          role: 'Rogue (Skids O\'Toole)',
        ),
      ],
    ),
    GameTable(
      id: '2',
      gameId: '2',
      hostId: '5',
      scheduledAt: DateTime.now().add(const Duration(days: 2, hours: 6)),
      location: 'Ana Salon',
      tableNo: 'Masa 2',
      capacity: 5,
      notes: '',
      status: TableStatus.dolu,
      revisionId: 1,
      estimatedHours: 2,
      game: const Game(
        id: '2',
        title: 'Ticket to Ride: Europe',
        coverUrl: 'https://placehold.co/640x360/e5e2db/570000?text=Ticket',
        minPlayers: 2,
        maxPlayers: 5,
        durationMin: 75,
        complexity: 2,
        genres: ['Strateji'],
        durationLabel: '60-90dk',
      ),
      host: const Member(id: '5', name: 'Ayşe Yılmaz'),
      hostBio: 'Rota optimizasyonu ve blöf konusunda acımasız bir rakip.',
      seats: List.generate(
        5,
        (i) => TableSeat(
          id: '${10 + i}',
          tableId: '2',
          memberId: '${10 + i}',
          memberName: 'Üye ${i + 1}',
        ),
      ),
    ),
    GameTable(
      id: '3',
      gameId: '3',
      hostId: '6',
      scheduledAt: DateTime.now().add(const Duration(hours: 5)),
      location: 'Küçük Salon',
      tableNo: 'Masa 1',
      capacity: 4,
      notes: '',
      status: TableStatus.bekliyor,
      revisionId: 1,
      estimatedHours: 2,
      game: const Game(
        id: '3',
        title: 'Catan: Seafarers',
        coverUrl: 'https://placehold.co/640x360/e5e2db/570000?text=Catan',
        minPlayers: 3,
        maxPlayers: 4,
        durationMin: 90,
        complexity: 3,
        genres: ['Strateji'],
        durationLabel: '90dk',
      ),
      host: const Member(id: '6', name: 'Can Bartu'),
      hostBio: 'Ticaret ve keşif tutkunu, yeni başlayanlara sabırlı bir usta.',
      seats: const [
        TableSeat(
          id: '20',
          tableId: '3',
          memberId: '6',
          memberName: 'Can Bartu',
        ),
      ],
    ),
  ];
}
