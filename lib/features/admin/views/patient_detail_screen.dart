import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/config/app_colors.dart';
import '../../../app/config/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../controllers/patient_detail_controller.dart';

class PatientDetailScreen extends GetView<PatientDetailController> {
  const PatientDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Detail Pasien',
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: Obx(() {
        final p = controller.patient.value;
        if (p == null) {
          return const Center(child: Text('Data tidak ditemukan'));
        }

        final name = p.fullName ?? 'Pasien Tanpa Nama';
        final statusText = p.isActive ? 'Aktif' : 'Sembuh / Tidak Aktif';
        final statusColor = p.isActive ? AppColors.danger : AppColors.success;
        final statusBg = p.isActive ? AppColors.dangerLight : AppColors.successLight;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient Header Card
              AppCard(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: p.isActive ? Colors.red.shade100 : Colors.green.shade100,
                      child: Text(
                        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'P',
                        style: TextStyle(
                          color: p.isActive ? Colors.red.shade700 : Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: AppTextStyles.titleLarge),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text('ID: ${p.id.substring(0, 8).toUpperCase()}', style: AppTextStyles.bodySmall),
                              const SizedBox(width: 12),
                              if (p.activationCode != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Text(
                                    'Kode: ${p.activationCode}',
                                    style: TextStyle(
                                      color: Colors.blue.shade800,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (p.zone != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: p.zone == 'merah'
                                        ? Colors.red.shade50
                                        : (p.zone == 'kuning' ? Colors.orange.shade50 : Colors.green.shade50),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: p.zone == 'merah'
                                          ? Colors.red.shade300
                                          : (p.zone == 'kuning' ? Colors.orange.shade300 : Colors.green.shade300),
                                    ),
                                  ),
                                  child: Text(
                                    'Zona ${p.zone!.toUpperCase()}',
                                    style: TextStyle(
                                      color: p.zone == 'merah'
                                          ? Colors.red.shade700
                                          : (p.zone == 'kuning' ? Colors.orange.shade700 : Colors.green.shade700),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: p.profileId != null ? Colors.green.shade50 : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: p.profileId != null ? Colors.green.shade300 : Colors.blue.shade300,
                                  ),
                                ),
                                child: Text(
                                  p.profileId != null ? 'Akun Aktif' : 'Belum Aktivasi',
                                  style: TextStyle(
                                    color: p.profileId != null ? Colors.green.shade700 : Colors.blue.shade700,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Patient Info Sections
              _buildSection(
                title: 'Informasi Kependudukan',
                icon: Icons.badge_outlined,
                children: [
                  _buildDetailRow('NIK', p.nik ?? 'Tidak Ada NIK'),
                  _buildDetailRow('Nomor Telepon', p.phone ?? 'Tidak Ada No HP'),
                  _buildDetailRow('Alamat Domicile', p.address ?? 'Tidak Ada Alamat'),
                  _buildDetailRow('Kecamatan', p.district ?? 'Tidak Ada Kecamatan'),
                  _buildDetailRow('Kode Aktivasi', p.activationCode ?? 'Sudah Aktif / Tidak Ada Kode'),
                ],
              ),

              _buildSection(
                title: 'Data Medis / Klinis',
                icon: Icons.medical_services_outlined,
                children: [
                  _buildDetailRow(
                    'Tanggal Diagnosis',
                    p.diagnosisDate != null ? DateFormat('dd MMMM yyyy').format(p.diagnosisDate!) : 'Tidak Ada Data',
                  ),
                  _buildDetailRow('Jenis TB', p.tbType ?? 'Tidak Ada Data'),
                  _buildDetailRow('Fasilitas Rujukan', p.facilityName ?? 'Tidak Ada Data'),
                ],
              ),

              _buildSection(
                title: 'Lokasi & Pelacakan',
                icon: Icons.location_on_outlined,
                children: [
                  _buildDetailRow('Latitude Domicile', p.domicileLat?.toString() ?? 'Tidak diatur'),
                  _buildDetailRow('Longitude Domicile', p.domicileLng?.toString() ?? 'Tidak diatur'),
                  _buildDetailRow('Persetujuan GPS Pasien', p.gpsConsent ? 'Disetujui' : 'Tidak Disetujui / Belum Diatur'),
                ],
              ),
              const SizedBox(height: 24),
              
              // Edit / Update button
              AppButton(
                text: 'UPDATE DATA PASIEN',
                icon: Icons.edit_outlined,
                onPressed: () {
                  Get.toNamed('/admin/patient/update', arguments: p);
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
