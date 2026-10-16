part of '../api_service.dart';

/// Favorites endpoints — the user's bookmarked games.
mixin FavoritesApi on ApiBase {
  Future<List<Game>> listFavorites() async {
    final res = await dio.get<List<dynamic>>('/me/favorites');
    return (res.data ?? const [])
        .map((e) => Game.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addFavorite(String gameId) async {
    await dio.post<void>('/me/favorites/$gameId');
  }

  Future<void> removeFavorite(String gameId) async {
    await dio.delete<void>('/me/favorites/$gameId');
  }
}
