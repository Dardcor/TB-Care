import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/config/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/empty_state.dart';
import '../controllers/tracing_controller.dart';

class TracingTimelineScreen extends GetView<TracingController> {
  const TracingTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Pelacakan Mobilitas',
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          // Indikator live update
          Obx(() => Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: controller.isLoading.value
                            ? Colors.orange
                            : Colors.greenAccent,
                        boxShadow: [
                          BoxShadow(
                            color: (controller.isLoading.value
                                    ? Colors.orange
                                    : Colors.greenAccent)
                                .withOpacity(0.5),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      controller.isLoading.value ? 'Memuat...' : 'Live',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              )),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.trackedPatients.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: LoadingShimmer(itemCount: 5, height: 90),
          );
        }

        if (controller.hasError.value) {
          return EmptyState(
            icon: Icons.error_outline,
            title: 'Gagal memuat data tracing',
            subtitle: 'Periksa koneksi internet Anda',
            buttonText: 'Coba Lagi',
            onButtonPressed: controller.refresh,
          );
        }

        if (controller.trackedPatients.isEmpty) {
          return const EmptyState(
            icon: Icons.location_off_outlined,
            title: 'Belum ada pasien yang terdaftar',
            subtitle: 'Pasien yang Anda daftarkan akan tampil di sini',
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          color: AppColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.trackedPatients.length,
            itemBuilder: (context, index) {
              final patient = controller.trackedPatients[index];
              return _PatientTracingCard(
                patient: patient,
                controller: controller,
                onTap: () {
                  controller.selectPatient(patient);
                  Get.toNamed(
                    AppRoutes.tracingDetail,
                    arguments: patient,
                  );
                },
              );
            },
          ),
        );
      }),
    );
  }
}

class _PatientTracingCard extends StatelessWidget {
  final PatientModel patient;
  final TracingController controller;
  final VoidCallback onTap;

  const _PatientTracingCard({
    required this.patient,
    required this.controller,
    required this.onTap,
  });

  Color _zoneColor(String? zone) {
    switch (zone?.toLowerCase()) {
      case 'merah':
        return const Color(0xFFD32F2F);
      case 'kuning':
        return const Color(0xFFF9A825);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  @override
  Widget build(BuildContext context) {
    final latestLog = controller.latestLogFor(patient.id);
    final zoneColor = _zoneColor(patient.zone);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header strip
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.04),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.fullName ?? 'Pasien Tanpa Nama',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          patient.nik != null
                              ? 'NIK: ${patient.nik}'
                              : 'ID: ${patient.id.substring(0, 8)}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  // Zone badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: zoneColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: zoneColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      (patient.zone ?? 'Hijau').toUpperCase(),
                      style: TextStyle(
                        color: zoneColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(
                children: [
                  // GPS dot aktif
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green.shade400,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: latestLog != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                latestLog.placeName ?? 'Lokasi diperbarui',
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF333333)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (latestLog.visitedAt != null)
                                Text(
                                  'Update: ${DateFormat('dd MMM, HH:mm:ss').format(latestLog.visitedAt!.toLocal())}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500),
                                ),
                            ],
                          )
                        : Text(
                            'Menunggu data lokasi...',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade400),
                          ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right,
                      color: Colors.grey.shade400, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
