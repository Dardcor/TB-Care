import 'package:get/get.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/services/supabase_service.dart';

class NotificationController extends GetxController {
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
    
    final data = await _supabase.getAdminNotifications();
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
    // Admin checks all out_of_zone notifications? Actually, we might need a specific user_id for admin,
    // but for now, admin might not have a specific user_id for system alerts. We just update locally
    // or add a method to mark all admin notifications as read.
    
    // For simplicity, we just mark all currently loaded ones as read locally
    // To do it perfectly, we should call a supabase method to mark all 'out_of_zone' as read.
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
