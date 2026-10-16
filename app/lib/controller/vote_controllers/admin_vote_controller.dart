import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../model/game.dart';
import '../../model/vote.dart';
import '../../service/api_service.dart';

/// Drives the admin poll management screen.
class AdminVoteController extends GetxController {
  final RxList<VotePoll> polls = <VotePoll>[].obs;
  final RxBool loadingPolls = false.obs;
  final RxBool submitting = false.obs;
  final RxnString error = RxnString();

  // ── Form state ────────────────────────────────────────────────────────────
  final title = ''.obs;
  final description = ''.obs;
  final Rxn<DateTime> endsAt = Rxn<DateTime>();
  final RxList<Game> allGames = <Game>[].obs;
  final RxSet<int> selectedGameIds = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadPolls();
    loadGames();
  }

  Future<void> loadPolls() async {
    loadingPolls.value = true;
    error.value = null;
    try {
      polls.assignAll(await ApiService.instance.listPolls());
    } catch (_) {
      error.value = 'Anketler yüklenemedi.';
    } finally {
      loadingPolls.value = false;
    }
  }

  Future<void> loadGames() async {
    try {
      allGames.assignAll(await ApiService.instance.listGames());
    } catch (_) {
      // Non-fatal: game picker will be empty.
    }
  }

  void toggleGame(int id) {
    if (selectedGameIds.contains(id)) {
      selectedGameIds.remove(id);
    } else {
      selectedGameIds.add(id);
    }
  }

  bool isGameSelected(int id) => selectedGameIds.contains(id);

  /// Returns null on success, error message on failure.
  Future<String?> createPoll() async {
    if (title.value.trim().isEmpty) return 'Anket başlığı zorunlu.';
    if (endsAt.value == null) return 'Bitiş tarihi seçilmedi.';
    if (selectedGameIds.length < 2) return 'En az iki oyun seçilmeli.';

    submitting.value = true;
    error.value = null;
    try {
      final poll = await ApiService.instance.createPoll(
        title: title.value.trim(),
        description: description.value.trim(),
        endsAt: endsAt.value!,
        gameIds: selectedGameIds.toList(),
      );
      polls.insert(0, poll);
      // Reset form
      title.value = '';
      description.value = '';
      endsAt.value = null;
      selectedGameIds.clear();
      return null;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['error'] is String) {
        return data['error'] as String;
      }
      return 'Anket oluşturulamadı. Tekrar deneyin.';
    } catch (_) {
      return 'Anket oluşturulamadı. Tekrar deneyin.';
    } finally {
      submitting.value = false;
    }
  }
}
