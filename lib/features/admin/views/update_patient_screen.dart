import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../app/config/app_colors.dart';
import '../../../app/config/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../controllers/patient_detail_controller.dart';
import '../controllers/add_patient_controller.dart';

class UpdatePatientScreen extends GetView<PatientDetailController> {
  const UpdatePatientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // If the controller is somehow not initialized with the arguments, initialize it.
    // This handles the case where users navigate directly to update screen.
    final patientArg = Get.arguments;
    if (patientArg != null && controller.patient.value == null) {
      controller.setPatient(patientArg);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Update Data Pasien',
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Perbarui informasi pasien di bawah ini. Pastikan data yang dimasukkan valid.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // IDENTITAS PASIEN
            _buildSection(
              title: 'IDENTITAS PASIEN',
              icon: Icons.badge_outlined,
              children: [
                _buildField(
                  label: 'Nama Lengkap',
                  hint: 'Masukkan nama lengkap',
                  controller: controller.nameController,
                ),
                _buildField(
                  label: 'Nomor Induk Kependudukan (NIK)',
                  hint: '16 digit NIK',
                  controller: controller.nikController,
                  keyboardType: TextInputType.number,
                ),
                _buildField(
                  label: 'Nomor Telepon / WhatsApp',
                  hint: 'Masukkan nomor telepon',
                  controller: controller.phoneController,
                  keyboardType: TextInputType.phone,
                ),
                _buildField(
                  label: 'Alamat Rumah / Domicile',
                  hint: 'Masukkan alamat tinggal',
                  controller: controller.addressController,
                ),
                const SizedBox(height: 8),
                Text('Kecamatan / Wilayah Pasien', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Obx(() => DropdownButtonFormField<String>(
                  value: controller.selectedDistrict.value,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  hint: const Text('Pilih Kecamatan'),
                  items: AddPatientController.surabayaTimurDistricts
                      .map((d) => DropdownMenuItem(value: d, child: Text('Kecamatan $d')))
                      .toList(),
                  onChanged: (val) => controller.selectedDistrict.value = val,
                )),
              ],
            ),

            // STATUS MONITORING & STATUS AKTIF (CRITICAL REQ)
            _buildSection(
              title: 'STATUS & PEMANTAUAN',
              icon: Icons.health_and_safety_outlined,
              children: [
                // STATUS AKTIF (Dropdown)
                Text('Status Pasien', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Obx(() => DropdownButtonFormField<bool>(
                  value: controller.isActive.value,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Aktif')),
                    DropdownMenuItem(value: false, child: Text('Sembuh / Tidak Aktif')),
                  ],
                  onChanged: (val) {
                    if (val != null) controller.isActive.value = val;
                  },
                )),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),

                // ZONA KASUS
                Text('Zona Risiko Kasus', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Obx(() => DropdownButtonFormField<String>(
                  value: controller.selectedZone.value,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'hijau', child: Text('Zona Hijau (Risiko Rendah)')),
                    DropdownMenuItem(value: 'kuning', child: Text('Zona Kuning (Pemantauan)')),
                    DropdownMenuItem(value: 'merah', child: Text('Zona Merah (Risiko Tinggi)')),
                  ],
                  onChanged: (val) {
                    if (val != null) controller.selectedZone.value = val;
                  },
                )),
              ],
            ),

            // CLINICAL DATA
            _buildSection(
              title: 'DATA MEDIS',
              icon: Icons.medical_services_outlined,
              children: [
                _buildField(
                  label: 'Tanggal Diagnosis',
                  hint: 'mm/dd/yyyy',
                  controller: controller.dateController,
                  suffixIcon: const Icon(Icons.calendar_today, size: 20, color: AppColors.textPrimary),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      controller.dateController.text = '${date.month}/${date.day}/${date.year}';
                    }
                  },
                ),
                const SizedBox(height: 16),

                Text('Puskesmas Rujukan Utama', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Obx(() => DropdownButtonFormField<String>(
                  value: controller.selectedPuskesmas.value,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  hint: const Text('Pilih Fasilitas Kesehatan', overflow: TextOverflow.ellipsis),
                  items: AddPatientController.surabayaTimurFaskes
                      .map((f) => DropdownMenuItem(value: f, child: Text(f, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) => controller.selectedPuskesmas.value = val,
                )),
                const SizedBox(height: 16),

                Text('Tipe TB', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Obx(() => DropdownButtonFormField<String>(
                  value: controller.selectedTbType.value,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  hint: const Text('Pilih Tipe TB', overflow: TextOverflow.ellipsis),
                  items: const [
                    DropdownMenuItem(value: 'BTA+', child: Text('BTA+ (Bakteri Tahan Asam Positif)', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'BTA-', child: Text('BTA- (Bakteri Tahan Asam Negatif)', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'TBC Anak', child: Text('TBC Anak', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'Ekstra Paru', child: Text('TBC Ekstra Paru', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'MDR', child: Text('TBC Resisten Obat (MDR-TB)', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (val) => controller.selectedTbType.value = val,
                )),
              ],
            ),

            // Domicile Coordinates for Map
            _buildSection(
              title: 'KOORDINAT DOMISILI',
              icon: Icons.map_outlined,
              children: [
                Text(
                  'Ketuk pada peta di bawah ini untuk menentukan titik koordinat domisili pasien secara otomatis:',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Obx(() {
                    final latStr = controller.latController.text;
                    final lngStr = controller.lngController.text;
                    final initialLat = double.tryParse(latStr) ?? -7.2816;
                    final initialLng = double.tryParse(lngStr) ?? 112.7562;
                    return GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(initialLat, initialLng),
                        zoom: 12,
                      ),
                      markers: controller.markers.value,
                      onTap: (position) {
                        controller.updatePosition(position);
                      },
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: true,
                    );
                  }),
                ),
                const SizedBox(height: 16),
                _buildField(
                  label: 'Latitude',
                  hint: 'Ketuk pada peta atau ketik manual',
                  controller: controller.latController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                _buildField(
                  label: 'Longitude',
                  hint: 'Ketuk pada peta atau ketik manual',
                  controller: controller.lngController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Obx(() => AppButton(
              text: 'SIMPAN PERUBAHAN',
              icon: Icons.save_outlined,
              isLoading: controller.isLoading.value,
              onPressed: controller.updatePatientData,
            )),
            const SizedBox(height: 32),
          ],
        ),
      ),
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
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    String? hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool readOnly = false,
    bool filled = false,
    Color? fillColor,
    Widget? suffixIcon,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onTap: onTap,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
              filled: filled || readOnly,
              fillColor: fillColor ?? (readOnly ? Colors.grey.shade100 : Colors.white),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
