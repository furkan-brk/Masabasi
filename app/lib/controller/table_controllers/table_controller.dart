import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../model/game_table.dart';
import '../../service/api_service.dart';

/// Drives the game tables list screen.
class TableController extends GetxController {
  final RxList<GameTable> tables = <GameTable>[].obs;
  final RxBool loading = false.obs;
  final RxnString error = RxnString();

  /// 'open' (Açık Masalar) or 'mine' (Benim Masalarım).
  final RxString activeTab = 'open'.obs;

  @override
  void onInit() {
    super.onInit();
    loadTables();
  }

  Future<void> loadTables() async {
    loading.value = true;
    error.value = null;
    try {
      final result = await ApiService.instance.listTables(tab: activeTab.value);
      tables.assignAll(result);
    } catch (_) {
      error.value = 'Masalar yüklenemedi.';
    } finally {
      loading.value = false;
    }
  }

  void setTab(String tab) {
    if (activeTab.value == tab) return;
    activeTab.value = tab;
    loadTables();
  }

  /// Joins the table with [id]. Returns null on success, Türkçe error message on failure.
  Future<String?> join(String id) async {
    try {
      await ApiService.instance.joinTable(id);
      return null;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 409) {
        final msg = e.response?.data?['error'] as String? ?? '';
        if (msg.contains('already')) return 'Zaten bu masadasın.';
        return 'Masa dolu.';
      }
      if (status == 404) return 'Masa bulunamadı.';
      return 'Katılım başarısız oldu.';
    } catch (_) {
      return 'Katılım başarısız oldu.';
    }
  }

  /// Leaves the table with [id]. Returns null on success, Türkçe error message on failure.
  Future<String?> leave(String id) async {
    try {
      await ApiService.instance.leaveTable(id);
      return null;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 403) return 'Masa sahibi masadan ayrılamaz.';
      if (status == 409) return 'Bu masada değilsiniz.';
      if (status == 404) return 'Masa bulunamadı.';
      return 'Ayrılma başarısız oldu.';
    } catch (_) {
      return 'Ayrılma başarısız oldu.';
    }
  }
}
