import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/config/app_colors.dart';
import '../../../app/config/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../app/routes/app_routes.dart';
import '../controllers/admin_profile_controller.dart';
import '../controllers/add_patient_controller.dart';

class AdminProfileScreen extends GetView<AdminProfileController> {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'Profil Petugas',
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildIdCard(context),
            const SizedBox(height: 20),
            _buildStats(),
            const SizedBox(height: 24),
            _buildMenuSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildIdCard(BuildContext context) {
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
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(Icons.person, size: 40, color: AppColors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() => Text(
                          controller.name.value,
                          style: AppTextStyles.titleLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )),
                    const SizedBox(height: 4),
                    Obx(() => Text(
                          controller.role.value.isNotEmpty ? controller.role.value : 'Peran belum diatur',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        )),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Obx(() => Text(
                            controller.nip.value.isNotEmpty ? controller.nip.value : 'NIP belum diatur',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          )),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_note, color: Colors.white, size: 28),
                onPressed: () => _showEditProfileBottomSheet(context),
                tooltip: 'Ubah Profil',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_hospital, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Obx(() => Text(
                        controller.facility.value.isNotEmpty ? controller.facility.value : 'Faskes belum diatur',
                        style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                      )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.people_outline, color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                Obx(() => Text(
                      '${controller.supervisedPatients.value}',
                      style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
                    )),
                const SizedBox(height: 4),
                Text(
                  'Pasien Diawasi',
                  style: AppTextStyles.labelSmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.route_outlined, color: AppColors.warning),
                ),
                const SizedBox(height: 12),
                Obx(() => Text(
                      '${controller.tracingsCompleted.value}',
                      style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
                    )),
                const SizedBox(height: 4),
                Text(
                  'Tracing Selesai',
                  style: AppTextStyles.labelSmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.lock_outline,
            title: 'Ganti Kata Sandi',
            onTap: () => _showChangePasswordBottomSheet(context),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
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

  void _showChangePasswordBottomSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ganti Kata Sandi',
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const Divider(height: 20),
              
              // KATA SANDI LAMA
              Text('Kata Sandi Lama', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: controller.oldPasswordEditController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Masukkan kata sandi lama',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              
              // KATA SANDI BARU
              Text('Kata Sandi Baru', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: controller.passwordEditController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Minimal 6 karakter',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // KONFIRMASI KATA SANDI BARU
              Text('Konfirmasi Kata Sandi Baru', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: controller.confirmPasswordEditController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Ulangi kata sandi baru',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              // SAVE BUTTON
              SizedBox(
                width: double.infinity,
                child: Obx(() => ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: controller.isChangingPassword.value ? null : () => controller.changePassword(),
                  child: controller.isChangingPassword.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('GANTI KATA SANDI', style: TextStyle(fontWeight: FontWeight.bold)),
                )),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Keluar Akun', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar dari akun Anda?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditProfileBottomSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ubah Profil Petugas',
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const Divider(height: 20),
              
              // NAMA LENGKAP
              Text('Nama Lengkap', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: controller.fullNameEditController,
                decoration: InputDecoration(
                  hintText: 'Masukkan nama lengkap',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // NOMOR TELEPON
              Text('Nomor Telepon', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: controller.phoneEditController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Masukkan nomor telepon',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // NIP
              Text('NIP (Nomor Induk Pegawai)', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: controller.nipEditController,
                decoration: InputDecoration(
                  hintText: 'Masukkan NIP',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // PUSKESMAS / FASKES
              Text('Puskesmas / Wilayah Kerja', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Obx(() => DropdownButtonFormField<String>(
                value: AddPatientController.surabayaTimurFaskes.contains(controller.selectedFacility.value) 
                    ? controller.selectedFacility.value 
                    : null,
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                hint: const Text('Pilih Puskesmas'),
                items: AddPatientController.surabayaTimurFaskes
                    .map((f) => DropdownMenuItem(value: f, child: Text(f, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (val) {
                  controller.selectedFacility.value = val;
                },
              )),
              const SizedBox(height: 24),

              // SAVE BUTTON
              SizedBox(
                width: double.infinity,
                child: Obx(() => ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: controller.isUpdating.value ? null : () => controller.updateProfile(),
                  child: controller.isUpdating.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('SIMPAN PERUBAHAN', style: TextStyle(fontWeight: FontWeight.bold)),
                )),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
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
}
