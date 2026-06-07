import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/config/app_colors.dart';
import '../../../app/config/app_text_styles.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../controllers/patient_notification_controller.dart';
import '../controllers/article_controller.dart';
import '../controllers/patient_dashboard_controller.dart';

class PatientNotificationScreen extends GetView<PatientNotificationController> {
  const PatientNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifikasi Pasien'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          TextButton(
            onPressed: controller.markAllAsRead,
            child: Text(
              'Tandai Dibaca',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.white),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: LoadingShimmer(itemCount: 4),
          );
        }

        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('Belum ada notifikasi', style: AppTextStyles.titleMedium),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: controller.notifications.length,
          itemBuilder: (context, index) {
            final notif = controller.notifications[index];
            final timeStr = DateFormat('dd MMM yyyy, HH:mm').format(notif.date);

            return InkWell(
              onTap: () {
                controller.markAsRead(notif.id);
                if (notif.type == 'article') {
                  try {
                    // Cari artikel berdasarkan judul dari notifikasi
                    final articleCtrl = Get.find<ArticleController>();
                    final articleTitle = notif.title.replaceAll('Artikel Baru: ', '').trim();
                    final article = articleCtrl.articles.firstWhere((a) => a.title == articleTitle);
                    
                    articleCtrl.selectArticle(article);
                    Get.toNamed(AppRoutes.articleDetail, arguments: article);
                  } catch (_) {
                    // Jika belum ter-load, arahkan pasien ke Tab Artikel di Dashboard
                    Get.until((route) => route.settings.name == AppRoutes.patientDashboard);
                    Get.find<PatientDashboardController>().changeTab(2);
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: notif.isRead ? Colors.transparent : AppColors.primary.withOpacity(0.05),
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: notif.isRead ? Colors.grey.shade100 : AppColors.primaryLight.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        notif.type == 'article' ? Icons.article_outlined : Icons.notifications,
                        color: notif.isRead ? Colors.grey : AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  notif.title,
                                  style: AppTextStyles.titleMedium.copyWith(
                                    fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (!notif.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.danger,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notif.message,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: notif.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            timeStr,
                            style: AppTextStyles.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
