import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/models/tracing_model.dart';
import '../../../core/models/patient_model.dart';

class StopPoint {
  final double latitude;
  final double longitude;
  final String? placeName;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;

  StopPoint({
    required this.latitude,
    required this.longitude,
    this.placeName,
    required this.startTime,
    required this.endTime,
    required this.duration,
  });
}

class TracingController extends GetxController {
  final _supabase = Get.find<SupabaseService>();

  // ── Daftar pasien ber-GPS-consent ──────────────────────────────────────
  final isLoading = true.obs;
  final hasError = false.obs;
  final trackedPatients = <PatientModel>[].obs;

  // ── Detail pasien yang dipilih ─────────────────────────────────────────
  final isDetailLoading = false.obs;
  final selectedPatient = Rx<PatientModel?>(null);
  final patientTracingLogs = <TracingModel>[].obs;

  // ── Legacy: single tracing log (digunakan oleh tracing_timeline_screen) ─
  final tracingLogs = <TracingModel>[].obs;
  final Rx<TracingModel?> selectedTracing = Rx<TracingModel?>(null);

  Timer? _refreshTimer;

  @override
  void onInit() {
    super.onInit();
    _loadPatients();
    // Auto-refresh setiap 10 detik untuk update posisi terbaru
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadPatients();
      if (selectedPatient.value != null) {
        _loadPatientLogs(selectedPatient.value!.id);
      }
    });
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  // ── Load daftar pasien di fasilitas petugas ini ─────────────────────────
  Future<void> _loadPatients() async {
    if (!isLoading.value) isLoading.value = true;
    hasError.value = false;
    try {
      final officerId = _supabase.currentUser?.id;
      final patients = officerId != null
          ? await _supabase.getTrackedPatientsForOfficer(officerId)
          : await _supabase.getPatientsWithGpsConsent();
      trackedPatients.assignAll(patients);

      // Isi tracingLogs dengan log terbaru dari semua pasien (untuk timeline view)
      if (patients.isNotEmpty) {
        final allLogs = await _supabase.getTracingLogs();
        tracingLogs.assignAll(allLogs);
      }
    } catch (e) {
      debugPrint('[TracingController] _loadPatients error: $e');
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }


  // ── Load semua log untuk pasien tertentu ────────────────────────────────
  Future<void> _loadPatientLogs(String patientId) async {
    isDetailLoading.value = true;
    try {
      final logs = await _supabase.getTracingLogs(patientId: patientId);
      patientTracingLogs.assignAll(logs);
    } catch (e) {
      debugPrint('[TracingController] _loadPatientLogs error: $e');
    } finally {
      isDetailLoading.value = false;
    }
  }

  // ── Dipanggil ketika petugas memilih pasien untuk dilihat detailnya ─────
  void selectPatient(PatientModel patient) {
    selectedPatient.value = patient;
    patientTracingLogs.clear();
    _loadPatientLogs(patient.id);
  }

  // ── Legacy: masih dipakai oleh tracing_timeline_screen ──────────────────
  void selectTracing(TracingModel tracing) {
    selectedTracing.value = tracing;
    if (tracing.patientId != null) {
      loadPatientTracing(tracing.patientId!);
    }
  }

  Future<void> loadPatientTracing(String patientId) async {
    isDetailLoading.value = true;
    try {
      final result = await _supabase.getTracingLogs(patientId: patientId);
      patientTracingLogs.assignAll(result);
    } catch (e) {
      debugPrint('[TracingController] loadPatientTracing error: $e');
    } finally {
      isDetailLoading.value = false;
    }
  }

  // ── Titik terbaru untuk preview di daftar pasien ─────────────────────────
  TracingModel? latestLogFor(String patientId) {
    try {
      return tracingLogs
          .where((l) => l.patientId == patientId)
          .reduce((a, b) =>
              (a.visitedAt ?? DateTime(0)).isAfter(b.visitedAt ?? DateTime(0))
                  ? a
                  : b);
    } catch (_) {
      return null;
    }
  }

  List<PatientModel> get patientsTrackedToday {
    final now = DateTime.now();
    return trackedPatients.where((patient) {
      final log = latestLogFor(patient.id);
      if (log == null || log.visitedAt == null) return false;
      final localVisited = log.visitedAt!.toLocal();
      return localVisited.year == now.year &&
             localVisited.month == now.month &&
             localVisited.day == now.day;
    }).toList();
  }

  Future<void> refresh() async {
    await _loadPatients();
  }

  // ── Algoritma Stop Detection (Deteksi Menetap > 15 Menit) ───────────────
  List<StopPoint> getStopPoints(List<TracingModel> logs) {
    if (logs.isEmpty) return [];

    final validLogs = logs.where((l) => l.latitude != null && l.longitude != null).toList();
    if (validLogs.isEmpty) return [];
    
    // Urutkan dari yang terlama ke terbaru
    validLogs.sort((a, b) => (a.visitedAt ?? DateTime(0)).compareTo(b.visitedAt ?? DateTime(0)));

    final stops = <StopPoint>[];
    List<TracingModel> currentCluster = [validLogs.first];

    for (int i = 1; i < validLogs.length; i++) {
      final log = validLogs[i];
      final clusterCenter = currentCluster.first;
      
      final distance = Geolocator.distanceBetween(
        clusterCenter.latitude!, clusterCenter.longitude!,
        log.latitude!, log.longitude!,
      );

      // Radius toleransi GPS 50 meter
      if (distance <= 50) { 
        currentCluster.add(log);
      } else {
        _checkAndAddCluster(currentCluster, stops);
        currentCluster = [log];
      }
    }

    _checkAndAddCluster(currentCluster, stops);
    return stops;
  }

  void _checkAndAddCluster(List<TracingModel> cluster, List<StopPoint> stops) {
    if (cluster.isEmpty) return;
    final start = cluster.first.visitedAt ?? DateTime.now();
    final end = cluster.last.visitedAt ?? start;
    final duration = end.difference(start);
    
    if (duration.inMinutes >= 15) {
      stops.add(StopPoint(
        latitude: cluster.first.latitude!,
        longitude: cluster.first.longitude!,
        placeName: cluster.first.placeName,
        startTime: start,
        endTime: end,
        duration: duration,
      ));
    }
  }
}
