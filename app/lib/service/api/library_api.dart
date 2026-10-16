part of '../api_service.dart';

/// Library / collection endpoints.
mixin LibraryApi on ApiBase {
  Future<List<dynamic>> listGamesRaw({String? query}) async {
    final res = await dio.get<List<dynamic>>(
      '/games',
      queryParameters: {if (query != null && query.isNotEmpty) 'q': query},
    );
    return res.data ?? const [];
  }

  /// Typed wrapper — maps raw JSON to [Game] objects.
  Future<List<Game>> listGames({String? query}) async {
    final raw = await listGamesRaw(query: query);
    return raw.map((e) => Game.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> getGameRaw(String id) async {
    final res = await dio.get<Map<String, dynamic>>('/games/$id');
    return res.data ?? const {};
  }

  Future<Game> getGame(String id) async {
    final raw = await getGameRaw(id);
    return Game.fromJson(raw);
  }

  Future<Game> createGame(Map<String, dynamic> body) async {
    final res = await dio.post<Map<String, dynamic>>('/games', data: body);
    return Game.fromJson(res.data ?? const {});
  }

  Future<Game> updateGame(String id, Map<String, dynamic> body) async {
    final res = await dio.patch<Map<String, dynamic>>('/games/$id', data: body);
    return Game.fromJson(res.data ?? const {});
  }

  Future<void> deleteGame(String id) async {
    await dio.delete<void>('/games/$id');
  }
}
