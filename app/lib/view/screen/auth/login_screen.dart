import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../controller/auth_controller.dart';
import '../../../utils/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _showRegister = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = Get.find<AuthController>();
    final email = _emailCtrl.text.trim();
    final pass = _passwordCtrl.text;

    if (_showRegister) {
      final name = _nameCtrl.text.trim();
      if (name.isEmpty || email.isEmpty || pass.length < 6) {
        Get.snackbar('Hata', 'Tüm alanları doldur (şifre en az 6 karakter).',
            backgroundColor: AppColors.errorContainer,
            colorText: AppColors.onError);
        return;
      }
      await auth.register(name, email, pass);
    } else {
      if (email.isEmpty || pass.isEmpty) {
        Get.snackbar('Hata', 'E-posta ve şifreyi gir.',
            backgroundColor: AppColors.errorContainer,
            colorText: AppColors.onError);
        return;
      }
      await auth.login(email, pass);
    }

    if (!mounted) return;
    if (auth.isLoggedIn) {
      context.go('/library');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Obx(() {
              final auth = Get.find<AuthController>();
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Masabaşı\nOyun Kulübü',
                    style: AppText.display.copyWith(color: AppColors.primary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  if (_showRegister) ...[
                    _Field(
                      label: 'Ad Soyad',
                      controller: _nameCtrl,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  _Field(
                    label: 'E-posta',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _Field(
                    label: 'Şifre',
                    controller: _passwordCtrl,
                    obscure: true,
                  ),

                  // Error message
                  if (auth.error.value != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      child: Text(
                        auth.error.value!,
                        style: AppText.bodyMd.copyWith(color: AppColors.onError),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: auth.loading.value ? null : _submit,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: auth.loading.value
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                color: AppColors.onPrimary,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _showRegister ? 'Kayıt Ol' : 'Giriş Yap',
                              style: AppText.labelMd.copyWith(color: AppColors.onPrimary),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () => setState(() {
                      _showRegister = !_showRegister;
                      Get.find<AuthController>().error.value = null;
                    }),
                    child: Text(
                      _showRegister
                          ? 'Zaten üye misin? Giriş yap'
                          : 'Hesabın yok mu? Kayıt ol',
                      style: AppText.bodyMd.copyWith(color: AppColors.primaryContainer),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.obscure = false,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: AppText.bodyMd.copyWith(color: AppColors.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppText.labelMd.copyWith(color: AppColors.onSurfaceVariant),
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
