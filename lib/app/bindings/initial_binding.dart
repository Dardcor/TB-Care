import 'package:get/get.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/gemini_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/notification_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Services are already initialized in main.dart via putAsync
    // We just ensure they are available in the global scope if needed
    Get.find<SupabaseService>();
    Get.find<GeminiService>();
    Get.find<LocationService>();
    Get.find<NotificationService>();
  }
}
