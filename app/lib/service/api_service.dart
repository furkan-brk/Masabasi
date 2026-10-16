import 'package:dio/dio.dart';

import '../model/chat_message.dart';
import '../model/game.dart';
import '../model/game_table.dart';
import '../model/notification_item.dart';
import '../model/vote.dart';
import '../utils/constants.dart';

part 'api/library_api.dart';
part 'api/auth_api.dart';
part 'api/tables_api.dart';
part 'api/votes_api.dart';
part 'api/notifications_api.dart';
part 'api/gamemaster_api.dart';
part 'api/favorites_api.dart';
part 'api/upload_api.dart';

/// Base HTTP client. Domain surfaces are mixed in via part files.
class ApiService extends ApiBase
    with LibraryApi, AuthApi, TablesApi, VotesApi, NotificationsApi, GamemasterApi, FavoritesApi, UploadApi {
  ApiService._() : super._();

  static final ApiService instance = ApiService._();
}

/// Holds the shared Dio instance + auth token.
abstract class ApiBase {
  ApiBase._()
      : dio = Dio(
          BaseOptions(
            baseUrl: AppConstants.apiBaseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
          ),
        );

  final Dio dio;
  String? _token;

  void setToken(String? token) {
    _token = token;
    if (token == null) {
      dio.options.headers.remove('Authorization');
    } else {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  String? get token => _token;
}
