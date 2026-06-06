import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/config/app_colors.dart';
import '../../../app/config/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../controllers/profile_controller.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final profile = controller.userProfile.value;
        final patient = controller.patientData.value;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeader(profile, patient),
              const SizedBox(height: 24),
              _buildMenuSection(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeader(profile, patient) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.white,
                child: Icon(Icons.person, size: 50, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NAMA',
                      style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (patient?.fullName ?? profile?.fullName ?? 'Nama User'),
                      style: AppTextStyles.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ((profile?.role == 'patient' ? 'pasien' : profile?.role) ?? 'User').toUpperCase(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (patient != null) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Zona', patient.zone ?? '-'),
                _buildStatItem('Diagnosis', patient.tbType ?? '-'),
                _buildStatItem('Status', patient.isActive ? 'Aktif' : 'Nonaktif'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildMenuSection() {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.person_outline,
            title: 'Edit Profil',
            onTap: () => Get.snackbar('Info', 'Fitur belum tersedia'),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildMenuItem(
            icon: Icons.notifications_active_outlined,
            title: 'Pengaturan Notifikasi',
            onTap: () => Get.snackbar('Info', 'Fitur belum tersedia'),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildMenuItem(
            icon: Icons.lock_outline,
            title: 'Keamanan Akun',
            onTap: () => Get.snackbar('Info', 'Fitur belum tersedia'),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: 'Bantuan & Dukungan',
            onTap: () => Get.snackbar('Info', 'Fitur belum tersedia'),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // GPS Tracking Switch
          Obx(() {
            final patient = controller.patientData.value;
            if (patient == null) return const SizedBox.shrink();
            return Column(
              children: [
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                  ),
                  title: const Text(
                    'Persetujuan GPS Pasien',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: const Text(
                    'Kirim lokasi otomatis setiap 5 detik',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: controller.gpsConsent.value,
                  onChanged: controller.isUpdatingConsent.value
                      ? null
                      : (val) => controller.toggleGpsConsent(val),
                  activeColor: AppColors.primary,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            );
          }),
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Keluar',
            color: AppColors.danger,
            hideArrow: true,
            onTap: _showLogoutDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = AppColors.textPrimary,
    bool hideArrow = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: hideArrow ? null : const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: () {
        if (Get.isSnackbarOpen) return;
        onTap();
      },
    );
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar Akun'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi Tuberku?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.logout();
            },
            child: const Text(
              'Keluar',
              style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
