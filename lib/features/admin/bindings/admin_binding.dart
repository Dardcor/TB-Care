import 'package:get/get.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../controllers/heatmap_controller.dart';
import '../controllers/tracing_controller.dart';
import '../controllers/main_admin_controller.dart';
import '../controllers/add_patient_controller.dart';
import '../controllers/admin_profile_controller.dart';
import '../controllers/article_form_controller.dart';

class AdminBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainAdminController>(() => MainAdminController());
    Get.lazyPut<AdminDashboardController>(
      () => AdminDashboardController(),
    );
    Get.lazyPut<HeatmapController>(() => HeatmapController());
    Get.lazyPut<TracingController>(() => TracingController());
    Get.lazyPut<AddPatientController>(() => AddPatientController());
    Get.lazyPut<AdminProfileController>(() => AdminProfileController());
    Get.lazyPut<ArticleFormController>(() => ArticleFormController());
  }
}
