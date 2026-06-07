import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/config/app_colors.dart';
import '../controllers/main_admin_controller.dart';
import 'admin_dashboard_screen.dart';
import 'heatmap_screen.dart';
import 'add_patient_screen.dart';
import 'article_form_screen.dart';
import 'admin_profile_screen.dart';

class MainAdminScreen extends GetView<MainAdminController> {
  const MainAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(
        () => IndexedStack(
          index: controller.currentIndex.value,
          children: const [
            AdminDashboardScreen(),
            HeatmapScreen(),
            AddPatientScreen(),
            ArticleFormScreen(),
            AdminProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          currentIndex: controller.currentIndex.value,
          onTap: controller.changeTab,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          backgroundColor: AppColors.cardBg,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Peta',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_add_outlined),
              activeIcon: Icon(Icons.person_add),
              label: 'Pasien',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article_outlined),
              activeIcon: Icon(Icons.article),
              label: 'Artikel',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
