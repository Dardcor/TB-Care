import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../../app/config/app_colors.dart';
import '../../../app/config/app_text_styles.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/models/tracing_model.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../controllers/tracing_controller.dart';

class TracingDetailScreen extends GetView<TracingController> {
  const TracingDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final patient = Get.arguments as PatientModel?;

    if (patient == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Tracing')),
        body: const Center(child: Text('Data pasien tidak ditemukan')),
      );
    }

    // Trigger log loading whenever we arrive at this screen for a patient
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.selectedPatient.value?.id != patient.id) {
        controller.selectPatient(patient);
      }
    });

    final zoneColor = _zoneColor(patient.zone);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(patient.fullName ?? 'Detail Tracing'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.selectPatient(patient),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Patient info strip ─────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(patient.fullName ?? '-',
                          style: AppTextStyles.titleMedium),
                      Text(
                        patient.nik != null
                            ? 'NIK: ${patient.nik}'
                            : 'ID: ${patient.id.substring(0, 8)}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                // Zone badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: zoneColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: zoneColor.withOpacity(0.3)),
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
                const SizedBox(width: 8),
                // GPS consent indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('GPS ON',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.green,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Peta dengan polyline ─────────────────────────────────────────
          Expanded(
            flex: 5,
            child: Obx(() {
              if (controller.isDetailLoading.value &&
                  controller.patientTracingLogs.isEmpty) {
                return Container(
                  color: const Color(0xFFE8EEF4),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Memuat rute perjalanan...',
                            style: TextStyle(color: Color(0xFF666666))),
                      ],
                    ),
                  ),
                );
              }

              final logs = controller.patientTracingLogs;

              if (logs.isEmpty) {
                return Container(
                  color: const Color(0xFFE8EEF4),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_off_outlined,
                            size: 48, color: Color(0xFFB0BEC5)),
                        SizedBox(height: 12),
                        Text(
                          'Belum ada data lokasi',
                          style: TextStyle(
                              color: Color(0xFF888888), fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Lokasi akan muncul setiap 5 detik',
                          style: TextStyle(
                              color: Color(0xFFAAAAAA), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Bangun markers & polyline dari log
              final validLogs = logs
                  .where((l) => l.latitude != null && l.longitude != null)
                  .toList();

              final polylinePoints = validLogs
                  .map((l) => LatLng(l.latitude!, l.longitude!))
                  .toList();

              final markers = <Marker>{};
              for (int i = 0; i < validLogs.length; i++) {
                final log = validLogs[i];
                final isFirst = i == 0;
                final isLast = i == validLogs.length - 1;

                double hue;
                String title;
                if (isFirst) {
                  hue = BitmapDescriptor.hueGreen;
                  title = '🟢 Titik Awal';
                } else if (isLast) {
                  hue = BitmapDescriptor.hueRed;
                  title = '🔴 Lokasi Terkini';
                } else {
                  hue = BitmapDescriptor.hueOrange;
                  title = 'Titik #${i + 1}';
                }

                markers.add(Marker(
                  markerId: MarkerId('log_${log.id}_$i'),
                  position: LatLng(log.latitude!, log.longitude!),
                  icon: BitmapDescriptor.defaultMarkerWithHue(hue),
                  infoWindow: InfoWindow(
                    title: title,
                    snippet: log.visitedAt != null
                        ? DateFormat('HH:mm:ss').format(
                            log.visitedAt!.toLocal())
                        : null,
                  ),
                ));
              }

              // Kamera arahkan ke titik terbaru
              final lastLog = validLogs.last;
              final cameraTarget =
                  LatLng(lastLog.latitude!, lastLog.longitude!);

              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: cameraTarget,
                  zoom: 15,
                ),
                markers: markers,
                polylines: {
                  if (polylinePoints.length >= 2)
                    Polyline(
                      polylineId: const PolylineId('route'),
                      points: polylinePoints,
                      color: AppColors.primary,
                      width: 5,
                      geodesic: true,
                      jointType: JointType.round,
                      startCap: Cap.roundCap,
                      endCap: Cap.roundCap,
                      patterns: [],
                    ),
                },
                myLocationEnabled: false,
                zoomControlsEnabled: true,
                mapToolbarEnabled: true,
              );
            }),
          ),

          // ── Log perjalanan (timeline bawah) ─────────────────────────────
          Container(
            height: 220,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 10,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Riwayat Lokasi',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF1A1A2E))),
                      Obx(() => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${controller.patientTracingLogs.length} titik',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary),
                            ),
                          )),
                    ],
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    if (controller.isDetailLoading.value &&
                        controller.patientTracingLogs.isEmpty) {
                      return const Center(
                          child: LoadingShimmer(itemCount: 3, height: 44));
                    }
                    if (controller.patientTracingLogs.isEmpty) {
                      return Center(
                        child: Text('Menunggu data lokasi pasien...',
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 13)),
                      );
                    }
                    // Tampilkan dari terbaru ke terlama
                    final reversed = controller.patientTracingLogs.reversed.toList();
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      itemCount: reversed.length,
                      itemBuilder: (context, index) {
                        return _LogItem(
                          log: reversed[index],
                          index: reversed.length - index,
                          isLatest: index == 0,
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
}

class _LogItem extends StatelessWidget {
  final TracingModel log;
  final int index;
  final bool isLatest;
  const _LogItem(
      {required this.log, required this.index, required this.isLatest});

  @override
  Widget build(BuildContext context) {
    final dotColor = isLatest ? Colors.red : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: dotColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: dotColor.withOpacity(0.4)),
                ),
                child: Center(
                  child: isLatest
                      ? Icon(Icons.my_location, size: 13, color: dotColor)
                      : Text(
                          '$index',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: dotColor),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: isLatest
                    ? Colors.red.shade50
                    : const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isLatest
                      ? Colors.red.shade100
                      : Colors.grey.shade100,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      log.placeName ?? 'Lokasi tidak diketahui',
                      style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF333333),
                          fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (log.visitedAt != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('HH:mm:ss')
                          .format(log.visitedAt!.toLocal()),
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
