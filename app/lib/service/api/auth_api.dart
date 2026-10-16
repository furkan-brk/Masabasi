part of '../api_service.dart';

/// Authentication endpoints.
mixin AuthApi on ApiBase {
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return res.data ?? const {};
  }

  Future<Map<String, dynamic>> register(
    String displayName,
    String email,
    String password,
  ) async {
    final res = await dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {'display_name': displayName, 'email': email, 'password': password},
    );
    return res.data ?? const {};
  }

  Future<Map<String, dynamic>> getMe() async {
    final res = await dio.get<Map<String, dynamic>>('/me');
    return res.data ?? const {};
  }

  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> body) async {
    final res = await dio.patch<Map<String, dynamic>>('/me', data: body);
    return res.data ?? const {};
  }
}
