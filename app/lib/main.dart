import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'controller/auth_controller.dart';
import 'controller/favorites_controllers/favorites_controller.dart';
import 'utils/router.dart';
import 'utils/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');

  // Register auth controller as a permanent singleton before routing begins.
  final auth = Get.put(AuthController(), permanent: true);
  Get.put(FavoritesController(), permanent: true);
  // Restore persisted session (validates token via /me; no-ops if not logged in).
  await auth.tryRestoreSession();
  // Token is now set if the session restored — load favorites for logged-in users.
  if (auth.isLoggedIn) await Get.find<FavoritesController>().load();

  runApp(const MasabasiApp());
}

class MasabasiApp extends StatelessWidget {
  const MasabasiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Masabaşı Oyun Kulübü',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: appRouter,
    );
  }
}
