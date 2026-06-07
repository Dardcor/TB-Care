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

  // Edit Profil & Security Controllers
  final fullNameEditController = TextEditingController();
  final emailEditController = TextEditingController();
  final phoneEditController = TextEditingController();
  final oldPasswordEditController = TextEditingController();
  final passwordEditController = TextEditingController();
  final confirmPasswordEditController = TextEditingController();

  final isChangingPassword = false.obs;
  final isUpdatingProfile = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  @override
  void onClose() {
    fullNameEditController.dispose();
    emailEditController.dispose();
    phoneEditController.dispose();
    oldPasswordEditController.dispose();
    passwordEditController.dispose();
    confirmPasswordEditController.dispose();
    super.onClose();
  }

  Future<void> loadProfile() async {
    isLoading.value = true;
    try {
      final user = _supabase.client.auth.currentUser;
      if (user != null) {
        final profile = await _supabase.getProfile(user.id);
        userProfile.value = profile;
        if (profile != null) {
          fullNameEditController.text = profile.fullName;
          emailEditController.text = profile.email;
          phoneEditController.text = profile.phone;
        }
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

  Future<void> updateProfile() async {
    final newEmail = emailEditController.text.trim();
    final newPhone = phoneEditController.text.trim();

    if (newEmail.isEmpty) {
      Get.snackbar('Gagal', 'Email tidak boleh kosong',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.black);
      return;
    }

    if (!GetUtils.isEmail(newEmail)) {
      Get.snackbar('Gagal', 'Format email tidak valid',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.black);
      return;
    }

    if (newPhone.isEmpty) {
      Get.snackbar('Gagal', 'Nomor telepon tidak boleh kosong',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.black);
      return;
    }

    isUpdatingProfile.value = true;
    try {
      final userId = _supabase.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Sesi tidak valid');

      final currentEmail = _supabase.client.auth.currentUser?.email;
      bool emailChanged = newEmail.toLowerCase() != currentEmail?.toLowerCase();

      if (emailChanged) {
        // Update auth email dan email di tabel profiles
        await _supabase.updateEmail(newEmail);
      }

      // Update phone di tabel profiles
      await _supabase.client
          .from('profiles')
          .update({
            'phone': newPhone,
          })
          .eq('id', userId);

      if (emailChanged) {
        Get.back(); // Tutup bottom sheet
        await logout(); // Logout dan redirect ke role selection / login
        
        Get.snackbar(
          'Email Diubah',
          'Email berhasil diperbarui. Silakan verifikasi email baru Anda terlebih dahulu (jika diperlukan) lalu masuk kembali menggunakan email baru.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.black,
          duration: const Duration(seconds: 8),
        );
      } else {
        await loadProfile();
        Get.back(); // Tutup bottom sheet
        Get.snackbar(
          'Berhasil',
          'Profil berhasil diperbarui.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.black,
        );
      }
    } catch (e) {
      Get.snackbar('Gagal', e.toString().replaceAll('Exception:', '').trim(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.black);
    } finally {
      isUpdatingProfile.value = false;
    }
  }

  Future<void> changePassword() async {
    final oldPassword = oldPasswordEditController.text.trim();
    final newPassword = passwordEditController.text.trim();
    final confirmPassword = confirmPasswordEditController.text.trim();

    if (oldPassword.isEmpty) {
      Get.snackbar('Gagal', 'Kata sandi lama tidak boleh kosong',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.black);
      return;
    }

    if (newPassword.isEmpty) {
      Get.snackbar('Gagal', 'Kata sandi baru tidak boleh kosong',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.black);
      return;
    }

    if (newPassword.length < 6) {
      Get.snackbar('Gagal', 'Kata sandi minimal 6 karakter',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.black);
      return;
    }

    if (newPassword != confirmPassword) {
      Get.snackbar('Gagal', 'Konfirmasi kata sandi tidak cocok',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.black);
      return;
    }

    isChangingPassword.value = true;
    try {
      final user = _supabase.client.auth.currentUser;
      final emailVal = user?.email;
      if (emailVal == null) {
        throw Exception('Sesi pengguna tidak valid. Silakan masuk kembali.');
      }

      // Verifikasi kata sandi lama dengan melakukan sign-in ulang
      try {
        await _supabase.signIn(email: emailVal, password: oldPassword);
      } catch (e) {
        throw Exception('Kata sandi lama yang Anda masukkan salah.');
      }

      // Update password baru
      await _supabase.updatePassword(newPassword);

      // Reset form
      oldPasswordEditController.clear();
      passwordEditController.clear();
      confirmPasswordEditController.clear();
      
      Get.back(); // Tutup bottom sheet ganti password
      await logout();

      Get.snackbar('Berhasil', 'Kata sandi berhasil diubah. Silakan masuk kembali.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.black,
          duration: const Duration(seconds: 5));
    } catch (e) {
      Get.snackbar('Gagal', e.toString().replaceAll('Exception:', '').trim(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.black);
    } finally {
      isChangingPassword.value = false;
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
