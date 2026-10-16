import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../model/game.dart';
import '../../service/api_service.dart';

/// Drives the library/collection screen.
class LibraryController extends GetxController {
  final RxList<Game> games = <Game>[].obs;
  final RxBool loading = false.obs;
  final RxnString error = RxnString();
  final RxString query = ''.obs;
  final RxSet<String> activeFilters = <String>{}.obs;

  // Advanced filter panel state.
  final RxnInt playerCount = RxnInt();
  final Rx<RangeValues> complexityRange = const RangeValues(0, 5).obs;
  final RxnInt maxDuration = RxnInt();
  final RxSet<String> selectedGenres = <String>{}.obs;
  final RxBool onlyAvailable = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadGames();
  }

  Future<void> loadGames() async {
    loading.value = true;
    error.value = null;
    try {
      final result = await ApiService.instance.listGames();
      games.assignAll(result);
    } catch (_) {
      error.value = 'Koleksiyon yüklenemedi.';
    } finally {
      loading.value = false;
    }
  }

  List<Game> get filteredGames {
    var list = games.toList();

    // Text search — title or genre.
    final q = query.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((g) {
        return g.title.toLowerCase().contains(q) ||
            g.genres.any((genre) => genre.toLowerCase().contains(q));
      }).toList();
    }

    // Quick-filter chips — AND logic.
    for (final chip in activeFilters) {
      list = list.where((g) => _matchesChip(g, chip)).toList();
    }

    // Advanced panel filters — AND logic.
    if (playerCount.value != null) {
      list = list
          .where((g) => g.minPlayers <= playerCount.value! && g.maxPlayers >= playerCount.value!)
          .toList();
    }
    final cr = complexityRange.value;
    if (cr.start > 0 || cr.end < 5) {
      list = list.where((g) => g.complexity >= cr.start && g.complexity <= cr.end).toList();
    }
    if (maxDuration.value != null) {
      list = list.where((g) => g.durationMin > 0 && g.durationMin <= maxDuration.value!).toList();
    }
    if (selectedGenres.isNotEmpty) {
      list = list.where((g) => selectedGenres.any((genre) => g.genres.contains(genre))).toList();
    }
    if (onlyAvailable.value) {
      list = list.where((g) => g.availability == GameAvailability.available).toList();
    }

    return list;
  }

  bool _matchesChip(Game g, String chip) {
    switch (chip) {
      case 'Ağır Strateji':
        return g.complexity >= 3.5;
      case '2 Kişilik':
        return g.minPlayers <= 2 && g.maxPlayers >= 2;
      case 'Parti Oyunları':
        return g.maxPlayers >= 5;
      case 'Solo':
        return g.minPlayers == 1;
      case 'Hızlı (<45dk)':
        return g.durationMin > 0 && g.durationMin <= 45;
      case 'Uzun Oyun (90dk+)':
        return g.durationMin >= 90;
      case 'Yeni Başlayan':
        return g.complexity > 0 && g.complexity < 2;
      default:
        return true;
    }
  }

  void setQuery(String value) => query.value = value;

  void toggleFilter(String chip) {
    if (activeFilters.contains(chip)) {
      activeFilters.remove(chip);
    } else {
      activeFilters.add(chip);
    }
  }

  bool isFilterActive(String chip) => activeFilters.contains(chip);

  void clearFilters() {
    activeFilters.clear();
    playerCount.value = null;
    complexityRange.value = const RangeValues(0, 5);
    maxDuration.value = null;
    selectedGenres.clear();
    onlyAvailable.value = false;
  }

  int get activeFilterCount {
    int count = 0;
    if (playerCount.value != null) count++;
    final cr = complexityRange.value;
    if (cr.start > 0 || cr.end < 5) count++;
    if (maxDuration.value != null) count++;
    if (selectedGenres.isNotEmpty) count++;
    if (onlyAvailable.value) count++;
    return count;
  }

  List<String> get allGenres {
    final genres = <String>{};
    for (final g in games) {
      genres.addAll(g.genres);
    }
    return genres.toList()..sort();
  }
}
