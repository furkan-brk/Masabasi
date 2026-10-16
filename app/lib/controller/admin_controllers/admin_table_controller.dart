import 'package:get/get.dart';

import '../../model/game_table.dart';
import '../../service/api_service.dart';

/// Drives the admin table management tab.
class AdminTableController extends GetxController {
  final RxList<GameTable> tables = <GameTable>[].obs;
  final RxBool loading = false.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadTables();
  }

  Future<void> loadTables() async {
    loading.value = true;
    error.value = null;
    try {
      tables.assignAll(await ApiService.instance.listAllTables());
    } catch (_) {
      error.value = 'Masalar yüklenemedi.';
    } finally {
      loading.value = false;
    }
  }

  Future<String?> deleteTable(String id) async {
    try {
      await ApiService.instance.deleteTable(id);
      tables.removeWhere((t) => t.id.toString() == id);
      return null;
    } catch (_) {
      return 'Masa silinemedi.';
    }
  }
}
