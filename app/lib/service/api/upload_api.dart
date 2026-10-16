part of '../api_service.dart';

mixin UploadApi on ApiBase {
  /// Uploads avatar bytes to [POST /me/avatar] and returns raw member JSON.
  /// The backend saves the image to MinIO and updates avatar_url.
  Future<Map<String, dynamic>> uploadAvatar(List<int> bytes, String filename) async {
    final formData = FormData.fromMap({
      'avatar': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final res = await dio.post<Map<String, dynamic>>(
      '/me/avatar',
      data: formData,
    );
    return res.data ?? const {};
  }
}
