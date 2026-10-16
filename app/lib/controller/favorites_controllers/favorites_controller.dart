import 'package:get/get.dart';

import '../../model/game.dart';
import '../../service/api_service.dart';

/// Manages the user's favorite games. Registered as a permanent singleton.
/// Shared state between LibraryScreen (bookmark toggle) and FavoritesScreen.
class FavoritesController extends GetxController {
  final RxList<Game> favorites = <Game>[].obs;
  final RxSet<String> favoriteIds = <String>{}.obs;
  final RxBool loading = false.obs;
  final RxnString error = RxnString();

  /// Loads favorites from the backend. Must be called after auth token is set.
  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final result = await ApiService.instance.listFavorites();
      favorites.assignAll(result);
      favoriteIds.assignAll(result.map((g) => g.id));
    } catch (_) {
      error.value = 'Favoriler yüklenemedi.';
    } finally {
      loading.value = false;
    }
  }

  /// Returns true if the game with [id] is in the user's favorites.
  bool isFavorite(String id) => favoriteIds.contains(id);

  /// Optimistically toggles a game's favorite status.
  Future<void> toggle(Game game) async {
    final id = game.id;
    final wasFav = favoriteIds.contains(id);
    if (wasFav) {
      favoriteIds.remove(id);
      favorites.removeWhere((g) => g.id == id);
    } else {
      favoriteIds.add(id);
      favorites.add(game);
    }
    try {
      if (wasFav) {
        await ApiService.instance.removeFavorite(id);
      } else {
        await ApiService.instance.addFavorite(id);
      }
    } catch (_) {
      error.value = 'Favori güncellenemedi.';
      if (wasFav) {
        favoriteIds.add(id);
        favorites.add(game);
      } else {
        favoriteIds.remove(id);
        favorites.removeWhere((g) => g.id == id);
      }
    }
  }

  /// Clears all favorites state (call on logout).
  void clear() {
    favorites.clear();
    favoriteIds.clear();
    error.value = null;
  }
}
