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
        title: Text(
          patient.fullName ?? 'Detail Tracing',
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.white),
        ),
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
                          'Lokasi akan diperbarui setiap 5 menit',
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
                  .toList()
                ..sort((a, b) => (a.visitedAt ?? DateTime(0)).compareTo(b.visitedAt ?? DateTime(0)));

              final polylinePoints = validLogs
                  .map((l) => LatLng(l.latitude!, l.longitude!))
                  .toList();

              final markers = <Marker>{};

              if (validLogs.isNotEmpty) {
                // 1. Titik Awal
                final first = validLogs.first;
                markers.add(Marker(
                  markerId: const MarkerId('start_point'),
                  position: LatLng(first.latitude!, first.longitude!),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                  infoWindow: InfoWindow(
                    title: '🟢 Titik Awal (24 Jam Terakhir)',
                    snippet: first.visitedAt != null ? DateFormat('dd MMM, HH:mm').format(first.visitedAt!.toLocal()) : '',
                  ),
                  zIndex: 2,
                ));

                // 2. Lokasi Terkini
                final last = validLogs.last;
                markers.add(Marker(
                  markerId: const MarkerId('current_point'),
                  position: LatLng(last.latitude!, last.longitude!),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  infoWindow: InfoWindow(
                    title: '🔴 Lokasi Terkini',
                    snippet: last.visitedAt != null ? DateFormat('dd MMM, HH:mm').format(last.visitedAt!.toLocal()) : '',
                  ),
                  zIndex: 3,
                ));
              }

              // 3. Titik Singgah (Stop Points)
              final stopPoints = controller.getStopPoints(validLogs);
              for (int i = 0; i < stopPoints.length; i++) {
                final stop = stopPoints[i];
                markers.add(Marker(
                  markerId: MarkerId('stop_point_$i'),
                  position: LatLng(stop.latitude, stop.longitude),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                  infoWindow: InfoWindow(
                    title: '📍 Menetap ${stop.duration.inMinutes} Menit',
                    snippet: '${DateFormat('HH:mm').format(stop.startTime.toLocal())} - ${DateFormat('HH:mm').format(stop.endTime.toLocal())}',
                  ),
                  zIndex: 1,
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
                    
                    final validLogs = controller.patientTracingLogs
                        .where((l) => l.latitude != null && l.longitude != null)
                        .toList()
                      ..sort((a, b) => (a.visitedAt ?? DateTime(0)).compareTo(b.visitedAt ?? DateTime(0)));

                    if (validLogs.isEmpty) return const SizedBox();

                    // Bangun list event penting (Start, Stop Points, Current)
                    final importantEvents = <Map<String, dynamic>>[];

                    // 1. Titik Terkini (Dimasukkan pertama agar muncul paling atas di UI)
                    final lastLog = validLogs.last;
                    importantEvents.add({
                      'title': '📍 Lokasi Terkini',
                      'time': lastLog.visitedAt,
                      'place': lastLog.placeName ?? 'Memproses alamat...',
                      'color': AppColors.danger,
                    });

                    // 2. Titik Singgah (Dibalik urutannya agar yang terbaru di atas)
                    final stopPoints = controller.getStopPoints(validLogs).reversed.toList();
                    for (final stop in stopPoints) {
                      importantEvents.add({
                        'title': '🛑 Menetap ${stop.duration.inMinutes} Menit',
                        'time': stop.endTime, 
                        'place': stop.placeName ?? 'Memproses alamat...',
                        'color': Colors.orange.shade700,
                      });
                    }

                    // 3. Titik Awal
                    final firstLog = validLogs.first;
                    if (firstLog.id != lastLog.id) {
                      importantEvents.add({
                        'title': '🟢 Titik Awal (24 Jam)',
                        'time': firstLog.visitedAt,
                        'place': firstLog.placeName ?? 'Memproses alamat...',
                        'color': AppColors.primary,
                      });
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      itemCount: importantEvents.length,
                      itemBuilder: (context, index) {
                        final event = importantEvents[index];
                        final isLatest = index == 0;
                        final timeStr = event['time'] != null 
                            ? DateFormat('HH:mm').format((event['time'] as DateTime).toLocal())
                            : '--:--';

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Timeline indicator
                            Column(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: event['color'],
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isLatest ? (event['color'] as Color).withOpacity(0.3) : Colors.transparent,
                                      width: isLatest ? 4 : 0,
                                    ),
                                  ),
                                ),
                                if (index != importantEvents.length - 1)
                                  Container(
                                    width: 2,
                                    height: 40,
                                    color: Colors.grey.shade200,
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            // Log content
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          event['title'],
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isLatest ? FontWeight.w700 : FontWeight.w600,
                                            color: isLatest ? const Color(0xFF1A1A2E) : Colors.grey.shade700,
                                          ),
                                        ),
                                        Text(
                                          timeStr,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isLatest ? AppColors.primary : Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      event['place'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
