import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/models/tracing_model.dart';
import '../../../core/models/patient_model.dart';
import '../../../app/config/app_colors.dart';
import '../../../app/config/app_text_styles.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/empty_state.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../controllers/main_admin_controller.dart';
import '../widgets/stat_mini_card.dart';

class AdminDashboardScreen extends GetView<AdminDashboardController> {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        titleSpacing: 16,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Obx(() {
          final firstName = controller.adminName.value.split(' ').first;
          return Text(
            'Petugas $firstName - Kota ${controller.adminCity.value}',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.white,
            ),
          );
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Get.toNamed(AppRoutes.adminNotifications),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: LoadingShimmer(itemCount: 4),
          );
        }

        if (controller.hasError.value) {
          return EmptyState(
            icon: Icons.error_outline,
            title: 'Gagal memuat data',
            subtitle: 'Periksa koneksi internet Anda',
            buttonText: 'Coba Lagi',
            onButtonPressed: controller.refresh,
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsGrid(),
                const SizedBox(height: 24),
                _buildMapPreview(),
                const SizedBox(height: 24),
                _buildTracingSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStatsGrid() {
    return Obx(() => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                Expanded(
                  child: StatMiniCard(
                    title: 'Kasus Aktif',
                    value: '${controller.activePatients.value}',
                    icon: Icons.settings_outlined,
                    iconColor: AppColors.danger,
                  ),
                ),
              const SizedBox(width: 8),
                Expanded(
                  child: StatMiniCard(
                    title: 'Tracing',
                    value: '${controller.activeTracingCount.value}',
                    icon: Icons.person_search_outlined,
                    iconColor: AppColors.danger,
                    badge: controller.tracingBadge,
                    badgeColor: controller.tracingBadgeColor,
                    subtitle: 'kontak',
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: StatMiniCard(
                  title: 'Zona Merah',
                  value: '${controller.redZoneCount.value}',
                  icon: Icons.warning_amber_rounded,
                  iconColor: AppColors.danger,
                  badge: controller.redZoneBadge,
                  badgeColor: controller.redZoneBadgeColor,
                  subtitle: 'kecamatan',
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildMapPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Persebaran Kasus', style: AppTextStyles.titleLarge),
            TextButton(
              onPressed: () {
                Get.find<MainAdminController>().changeTab(1); // Go to Heatmap Tab
              },
              child: Row(
                children: [
                  Text(
                    'Fullscreen',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => Get.find<MainAdminController>().changeTab(1),
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Obx(() => GoogleMap(
                liteModeEnabled: true, // Optimasi performa agar se-ringan gambar statis
                initialCameraPosition: const CameraPosition(
                  target: LatLng(-7.250445, 112.768845), // Pusat Surabaya
                  zoom: 11,
                ),
                markers: controller.previewMarkers.toSet(),
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
                onMapCreated: (GoogleMapController mapController) {
                  mapController.setMapStyle('[{"featureType": "poi","stylers": [{"visibility": "off"}]},{"featureType": "transit","stylers": [{"visibility": "off"}]}]');
                },
                onTap: (_) => Get.find<MainAdminController>().changeTab(1),
              )),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTracingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Tracing Terbaru', style: AppTextStyles.titleLarge),
            TextButton(
              onPressed: () => Get.toNamed(AppRoutes.tracingTimeline),
              child: Text(
                'Lihat Semua',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(() {
          if (controller.recentTracing.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Belum ada riwayat tracing terbaru.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }

          return Column(
            children: controller.recentTracing.take(3).map((tracing) {
              final patient = controller.patients.firstWhereOrNull((p) => p.id == tracing.patientId);
              final patientIdStr = tracing.patientId;
              final patientName = patient?.fullName ??
                  'Pasien (ID: ${patientIdStr != null && patientIdStr.length >= 8 ? patientIdStr.substring(0, 8) : '?'})';
              return _buildTracingCard(
                patientName: patientName,
                location: tracing.placeName ?? 'Lokasi tidak diketahui',
                patient: patient,
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildTracingCard({
    required String patientName,
    required String location,
    required PatientModel? patient,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_search_outlined,
              color: AppColors.textPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              if (patient != null) {
                Get.toNamed(AppRoutes.tracingDetail, arguments: patient);
              } else {
                Get.snackbar(
                  'Info',
                  'Gagal memuat detail pasien. Silakan coba beberapa saat lagi.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.orange.shade100,
                  colorText: Colors.black,
                );
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Detail',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

