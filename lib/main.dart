import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app/config/app_colors.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/bindings/initial_binding.dart';
import 'core/services/supabase_service.dart';
import 'core/services/gemini_service.dart';
import 'core/services/location_service.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load env
  await dotenv.load(fileName: ".env");

  // Init local storage
  await GetStorage.init();

  // Init Firebase
  await Firebase.initializeApp();

  // Init services
  await Get.putAsync(() => SupabaseService().init());
  await Get.putAsync(() => GeminiService().init());
  await Get.putAsync(() => LocationService().init());
  await Get.putAsync(() => NotificationService().init());

  // Check existing session for auto-login
  final supabase = Get.find<SupabaseService>();
  String initialRoute = AppPages.initial;

  if (supabase.currentUser != null) {
    try {
      final profile = await supabase.getProfile(supabase.currentUser!.id);
      if (profile != null) {
        if (profile.role == 'petugas') {
          initialRoute = AppRoutes.adminDashboard;
        } else {
          initialRoute = AppRoutes.patientDashboard;
        }
      }
    } catch (e) {
      debugPrint('[Tuberku] Auto-login error: $e');
    }
  }

  runApp(TuberkuApp(initialRoute: initialRoute));
}

class TuberkuApp extends StatelessWidget {
  final String initialRoute;
  const TuberkuApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Tuberku',
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(),
      initialRoute: initialRoute,
      getPages: AppPages.routes,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.cardBg,
          error: AppColors.danger,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.cardBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
