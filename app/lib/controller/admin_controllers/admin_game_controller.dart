import 'package:get/get.dart';

import '../../model/game.dart';
import '../../service/api_service.dart';

/// Drives the admin game management tab.
class AdminGameController extends GetxController {
  final RxList<Game> games = <Game>[].obs;
  final RxBool loading = false.obs;
  final RxBool submitting = false.obs;
  final RxnString error = RxnString();

  // ── Form state (create/edit) ─────────────────────────────────────────────
  final title = ''.obs;
  final coverUrl = ''.obs;
  final minPlayers = 2.obs;
  final maxPlayers = 4.obs;
  final durationMin = 60.obs;
  final complexity = 2.5.obs;
  final genres = ''.obs; // JSON string e.g. '["Strateji","Kart"]'
  final ownedStatus = 'Mevcut'.obs;
  final description = ''.obs;
  final rulesNotes = ''.obs;
  final Rxn<String> editingId = Rxn<String>(); // null = create mode

  @override
  void onInit() {
    super.onInit();
    loadGames();
  }

  Future<void> loadGames() async {
    loading.value = true;
    error.value = null;
    try {
      games.assignAll(await ApiService.instance.listGames());
    } catch (_) {
      error.value = 'Oyunlar yüklenemedi.';
    } finally {
      loading.value = false;
    }
  }

  void startEdit(Game g) {
    editingId.value = g.id;
    title.value = g.title;
    coverUrl.value = g.coverUrl;
    minPlayers.value = g.minPlayers;
    maxPlayers.value = g.maxPlayers;
    durationMin.value = g.durationMin;
    complexity.value = g.complexity;
    genres.value = g.genres.isEmpty ? '' : '[${g.genres.map((e) => '"$e"').join(',')}]';
    ownedStatus.value = g.availability == GameAvailability.available ? 'Mevcut' : 'Masada';
    description.value = g.description ?? '';
    rulesNotes.value = g.rulesNotes ?? '';
  }

  void clearForm() {
    editingId.value = null;
    title.value = '';
    coverUrl.value = '';
    minPlayers.value = 2;
    maxPlayers.value = 4;
    durationMin.value = 60;
    complexity.value = 2.5;
    genres.value = '';
    ownedStatus.value = 'Mevcut';
    description.value = '';
    rulesNotes.value = '';
  }

  Map<String, dynamic> get _formBody => {
        'title': title.value.trim(),
        'cover_image_url': coverUrl.value.trim(),
        'min_players': minPlayers.value,
        'max_players': maxPlayers.value,
        'duration_min': durationMin.value,
        // Backend stores complexity as an int (1-5); round before sending so
        // Gin's int binding does not reject a decimal payload.
        'complexity': complexity.value.round(),
        'genres': genres.value.trim().isEmpty ? '[]' : genres.value.trim(),
        'owned_status': ownedStatus.value,
        'description': description.value.trim(),
        'rules_notes': rulesNotes.value.trim(),
      };

  /// Returns null on success, error message on failure.
  Future<String?> saveGame() async {
    if (title.value.trim().isEmpty) return 'Oyun adı zorunlu.';
    submitting.value = true;
    try {
      if (editingId.value != null) {
        final updated = await ApiService.instance.updateGame(editingId.value!, _formBody);
        final idx = games.indexWhere((g) => g.id == editingId.value);
        if (idx != -1) games[idx] = updated;
      } else {
        final created = await ApiService.instance.createGame(_formBody);
        games.insert(0, created);
      }
      clearForm();
      return null;
    } catch (_) {
      return 'Kaydedilemedi. Tekrar deneyin.';
    } finally {
      submitting.value = false;
    }
  }

  Future<String?> deleteGame(String id) async {
    try {
      await ApiService.instance.deleteGame(id);
      games.removeWhere((g) => g.id == id);
      return null;
    } catch (_) {
      return 'Silinemedi. Tekrar deneyin.';
    }
  }
}
