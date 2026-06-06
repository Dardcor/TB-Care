import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/patient_model.dart';
import '../../../app/routes/app_routes.dart';

class ProfileController extends GetxController {
  final _supabase = Get.find<SupabaseService>();

  final isLoading = true.obs;
  final Rx<UserModel?> userProfile = Rx<UserModel?>(null);
  final Rx<PatientModel?> patientData = Rx<PatientModel?>(null);
  
  // GPS Consent state
  final gpsConsent = false.obs;
  final isUpdatingConsent = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    isLoading.value = true;
    try {
      final user = _supabase.client.auth.currentUser;
      if (user != null) {
        final profile = await _supabase.getProfile(user.id);
        userProfile.value = profile;
        if (profile?.role == 'patient' || profile?.role == 'pasien') {
          final patient = await _supabase.getPatientByProfileId(user.id);
          patientData.value = patient;
          if (patient != null) {
            gpsConsent.value = patient.gpsConsent;
          }
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat profil: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleGpsConsent(bool consent) async {
    final patient = patientData.value;
    if (patient == null) {
      Get.snackbar('Error', 'Data pasien tidak ditemukan');
      return;
    }

    isUpdatingConsent.value = true;
    try {
      await _supabase.updateGpsConsent(patient.id, consent: consent);
      gpsConsent.value = consent;
      
      // Update patient data in state
      patientData.value = PatientModel(
        id: patient.id,
        profileId: patient.profileId,
        fullName: patient.fullName,
        nik: patient.nik,
        phone: patient.phone,
        facilityName: patient.facilityName,
        district: patient.district,
        activationCode: patient.activationCode,
        address: patient.address,
        domicileLat: patient.domicileLat,
        domicileLng: patient.domicileLng,
        diagnosisDate: patient.diagnosisDate,
        tbType: patient.tbType,
        zone: patient.zone,
        isActive: patient.isActive,
        gpsConsent: consent,
        createdAt: patient.createdAt,
      );

      // Reset service cache to apply the changes immediately
      try {
        Get.find<LocationService>().resetTrackingCache();
        Get.find<LocationService>().startPeriodicTracking();
      } catch (e) {
        debugPrint('[ProfileController] Reset tracking service cache failed: $e');
      }

      Get.snackbar(
        'Berhasil',
        consent ? 'Izin pelacakan GPS diaktifkan.' : 'Izin pelacakan GPS dinonaktifkan.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
      );
    } catch (e) {
      debugPrint('[ProfileController] toggleGpsConsent error: $e');
      String errMsg = e.toString();
      if (errMsg.contains('42501') || errMsg.contains('permission denied') || errMsg.contains('row-level security')) {
        errMsg = 'Permission Denied (RLS Policy). Pastikan RLS Policy UPDATE untuk tabel patients sudah ditambahkan di Supabase agar Pasien dapat mengubah persetujuannya (lihat db.sql).';
      }
      Get.snackbar(
        'Gagal Memperbarui Izin',
        errMsg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        duration: const Duration(seconds: 7),
      );
    } finally {
      isUpdatingConsent.value = false;
    }
  }

  Future<void> logout() async {
    try {
      // Hentikan pelacakan berkala saat logout
      try {
        Get.find<LocationService>().stopPeriodicTracking();
      } catch (_) {}
      
      await _supabase.client.auth.signOut();
      Get.offAllNamed(AppRoutes.roleSelection);
    } catch (e) {
      Get.snackbar('Error', 'Gagal logout: ${e.toString()}');
    }
  }
}
}
