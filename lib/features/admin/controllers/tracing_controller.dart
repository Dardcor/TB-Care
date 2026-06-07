import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/models/tracing_model.dart';
import '../../../core/models/patient_model.dart';

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
}
