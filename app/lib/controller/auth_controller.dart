import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/member.dart';
import '../service/api_service.dart';
import 'favorites_controllers/favorites_controller.dart';

const _kTokenKey = 'masabasi_jwt';

/// Manages authentication state: login, register, session restore, logout.
///
/// Must be registered as a permanent singleton before runApp:
///   Get.put(AuthController(), permanent: true);
class AuthController extends GetxController {
  final Rxn<Member> currentUser = Rxn<Member>();
  final RxBool loading = false.obs;
  final RxnString error = RxnString();

  bool get isLoggedIn => currentUser.value != null;
  bool get isAdmin => currentUser.value?.isAdmin ?? false;

  // ── Session restore ───────────────────────────────────────────────────────

  /// Called once at startup. Reads persisted token, validates via /me,
  /// restores session or clears stale token.
  Future<void> tryRestoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kTokenKey);
    if (token == null || token.isEmpty) return;

    ApiService.instance.setToken(token);
    try {
      final raw = await ApiService.instance.getMe();
      currentUser.value = Member.fromJson(raw);
    } catch (_) {
      // Token expired or invalid — clear everything.
      ApiService.instance.setToken(null);
      await prefs.remove(_kTokenKey);
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<void> login(String email, String password) async {
    loading.value = true;
    error.value = null;
    try {
      final res = await ApiService.instance.login(email.trim(), password);
      await _applyAuthResponse(res);
    } on Exception catch (e) {
      error.value = _extractMessage(e);
    } finally {
      loading.value = false;
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────

  Future<void> register(String displayName, String email, String password) async {
    loading.value = true;
    error.value = null;
    try {
      final res = await ApiService.instance.register(displayName.trim(), email.trim(), password);
      await _applyAuthResponse(res);
    } on Exception catch (e) {
      error.value = _extractMessage(e);
    } finally {
      loading.value = false;
    }
  }

  // ── Update profile ───────────────────────────────────────────────────────

  /// Sends a PATCH /me with the provided fields. Returns null on success or a
  /// Türkçe error message on failure. Updates [currentUser] in place.
  Future<String?> updateProfile({
    String? displayName,
    String? bio,
    String? experienceLevel,
    String? favoriteGenres,
  }) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['display_name'] = displayName;
    if (bio != null) body['bio'] = bio;
    if (experienceLevel != null) body['experience_level'] = experienceLevel;
    if (favoriteGenres != null) body['favorite_genres'] = favoriteGenres;

    if (body.isEmpty) return null;

    try {
      final raw = await ApiService.instance.updateMe(body);
      currentUser.value = Member.fromJson(raw);
      return null;
    } on Exception catch (e) {
      return _extractMessage(e);
    }
  }

  // ── Avatar upload ──────────────────────────────────────────────────────────

  /// Uploads avatar bytes to MinIO via [POST /me/avatar].
  /// Updates [currentUser] on success. Returns null on success, Türkçe message on failure.
  Future<String?> uploadAvatar(List<int> bytes, String filename) async {
    try {
      final raw = await ApiService.instance.uploadAvatar(bytes, filename);
      currentUser.value = Member.fromJson(raw);
      return null;
    } on Exception catch (e) {
      return _extractMessage(e);
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    currentUser.value = null;
    error.value = null;
    Get.find<FavoritesController>().clear();
    ApiService.instance.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTokenKey);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _applyAuthResponse(Map<String, dynamic> res) async {
    final token = res['token'] as String?;
    if (token == null || token.isEmpty) {
      error.value = 'Geçersiz sunucu yanıtı.';
      return;
    }
    ApiService.instance.setToken(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTokenKey, token);

    final memberJson = res['member'] as Map<String, dynamic>?;
    if (memberJson != null) {
      currentUser.value = Member.fromJson(memberJson);
    }

    // Load favorites now that the token is set. A failure here must not block login.
    try {
      await Get.find<FavoritesController>().load();
    } catch (_) {}
  }

  String _extractMessage(Exception e) {
    final msg = e.toString();
    // Dio DioException wraps the response body; extract meaningful text.
    if (msg.contains('invalid credentials') || msg.contains('401')) {
      return 'E-posta veya şifre hatalı.';
    }
    if (msg.contains('email already') || msg.contains('409')) {
      return 'Bu e-posta zaten kayıtlı.';
    }
    return 'Bir hata oluştu. Lütfen tekrar deneyin.';
  }
}
