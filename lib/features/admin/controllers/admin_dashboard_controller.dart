import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/models/patient_model.dart';
import '../../../core/models/tracing_model.dart';
import '../../../app/config/app_colors.dart';

class AdminDashboardController extends GetxController {
  final _supabase = Get.find<SupabaseService>();

  final isLoading = true.obs;
  final hasError = false.obs;

  // Stats
  final activePatients = 0.obs;
  final redZoneCount = 0.obs;
  final yellowZoneCount = 0.obs;
  final greenZoneCount = 0.obs;
  final activeTracingCount = 0.obs;

  // Getters for dynamic badges
  String? get tracingBadge => activeTracingCount.value > 5 ? 'CRITICAL' : null;
  Color? get tracingBadgeColor => activeTracingCount.value > 5 ? AppColors.danger : null;

  String? get redZoneBadge => redZoneCount.value > 0 ? 'CRITICAL' : null;
  Color? get redZoneBadgeColor => redZoneCount.value > 0 ? AppColors.danger : null;

  // Admin Info
  final adminName = 'Petugas'.obs;
  final adminCity = 'Surabaya'.obs;

  // Data
  final patients = <PatientModel>[].obs;
  final recentTracing = <TracingModel>[].obs;
  final previewMarkers = <Marker>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _loadData();
  }

  Future<void> _loadData() async {
    isLoading.value = true;
    hasError.value = false;

    try {
      final user = _supabase.currentUser;
      String? officerId;

      if (user != null) {
        officerId = user.id;
        final profile = await _supabase.getProfile(user.id);
        if (profile != null && profile.fullName.isNotEmpty) {
          adminName.value = profile.fullName;
        }
      }

      // Load patients scoped to this officer's facility
      final List<PatientModel> officerPatients = officerId != null
          ? await _supabase.getActivePatientsForOfficer(officerId)
          : await _supabase.getActivePatients();

      patients.assignAll(officerPatients);
      activePatients.value = officerPatients.length;
      _buildPreviewMarkers();

      // Zone counts from officer's patients only
      final redDistricts = officerPatients
          .where((p) => p.zone == 'merah' && p.district != null && p.district!.trim().isNotEmpty)
          .map((p) => p.district!.trim().toLowerCase())
          .toSet();
      redZoneCount.value = redDistricts.length;
      yellowZoneCount.value = officerPatients.where((p) => p.zone == 'kuning').length;
      greenZoneCount.value = officerPatients.where((p) => p.zone == 'hijau').length;

      // Load recent tracing logs only for this officer's patients
      final patientIds = officerPatients.map((p) => p.id).toList();
      final tracingList = await _supabase.getRecentTracingLogsForPatients(patientIds);

      // Deduplicate: one entry per patient, keeping the most recent first
      final uniqueTracings = <TracingModel>[];
      final seenPatients = <String>{};
      for (final t in tracingList) {
        if (t.patientId != null && !seenPatients.contains(t.patientId)) {
          seenPatients.add(t.patientId!);
          uniqueTracings.add(t);
        }
      }
      recentTracing.assignAll(uniqueTracings);
      activeTracingCount.value = uniqueTracings.length;
    } catch (e) {
      debugPrint('[AdminDashboardController] loadData error: $e');
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  void _buildPreviewMarkers() {
    final markers = <Marker>{};
    for (final p in patients) {
      if (p.domicileLat != null && p.domicileLng != null && p.isActive) {
        double hue = BitmapDescriptor.hueRed;
        if (p.zone == 'kuning') hue = BitmapDescriptor.hueYellow;
        if (p.zone == 'hijau') hue = BitmapDescriptor.hueGreen;
        markers.add(Marker(
          markerId: MarkerId('prev_${p.id}'),
          position: LatLng(p.domicileLat!, p.domicileLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        ));
      }
    }
    previewMarkers.assignAll(markers);
  }

  Future<void> refresh() async {
    await _loadData();
  }
}
