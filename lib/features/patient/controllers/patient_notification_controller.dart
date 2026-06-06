import 'package:get/get.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/services/supabase_service.dart';

class PatientNotificationController extends GetxController {
  final _supabase = Get.find<SupabaseService>();

  final notifications = <NotificationModel>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    isLoading.value = true;
    
    final user = _supabase.currentUser;
    final data = await _supabase.getPatientNotifications(user?.id);
    
    notifications.assignAll(data.map((json) => NotificationModel.fromJson(json)).toList());
    
    isLoading.value = false;
  }

  Future<void> markAsRead(String id) async {
    await _supabase.markNotificationAsRead(id);
    
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final notif = notifications[index];
      notifications[index] = NotificationModel(
        id: notif.id,
        userId: notif.userId,
        title: notif.title,
        message: notif.message,
      type: notif.type,
      date: notif.date,
      isRead: true,
      );
    }
  }

  Future<void> markAllAsRead() async {
    final user = _supabase.currentUser;
    await _supabase.markAllNotificationsAsRead(user?.id);
    
    final updated = notifications.map((n) => NotificationModel(
      id: n.id,
      userId: n.userId,
      title: n.title,
      message: n.message,
      type: n.type,
      date: n.date,
      isRead: true,
    )).toList();
    notifications.assignAll(updated);
  }
}
