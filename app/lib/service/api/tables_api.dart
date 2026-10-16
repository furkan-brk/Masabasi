part of '../api_service.dart';

/// Game table (session) endpoints.
mixin TablesApi on ApiBase {
  Future<List<GameTable>> listTables({String tab = 'open'}) async {
    final res = await dio.get<List<dynamic>>(
      '/tables',
      queryParameters: {'tab': tab},
    );
    return (res.data ?? const [])
        .map((e) => GameTable.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<GameTable> getTable(String id) async {
    final res = await dio.get<Map<String, dynamic>>('/tables/$id');
    return GameTable.fromJson(res.data ?? const {});
  }

  Future<GameTable> createTable(Map<String, dynamic> body) async {
    final res =
        await dio.post<Map<String, dynamic>>('/tables', data: body);
    return GameTable.fromJson(res.data ?? const {});
  }

  Future<GameTable> joinTable(String id) async {
    final res =
        await dio.post<Map<String, dynamic>>('/tables/$id/join');
    return GameTable.fromJson(res.data ?? const {});
  }

  Future<GameTable> leaveTable(String id) async {
    final res = await dio.delete<Map<String, dynamic>>('/tables/$id/leave');
    return GameTable.fromJson(res.data ?? const {});
  }

  Future<void> deleteTable(String id) async {
    await dio.delete<void>('/tables/$id');
  }

  Future<List<GameTable>> listAllTables() async {
    return listTables(tab: 'all');
  }
}
