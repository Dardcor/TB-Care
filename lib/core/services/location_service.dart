import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import '../models/facility_model.dart';
import '../models/tracing_model.dart';
import '../models/patient_model.dart';
import 'supabase_service.dart';

class LocationService extends GetxService {
  StreamSubscription<Position>? _positionStream;
  PatientModel? _cachedPatient;
  DateTime? _lastUploadTime;
  Position? _lastUploadedPosition;

  Future<LocationService> init() async {
    startPeriodicTracking();
    return this;
  }

  @override
  void onClose() {
    stopPeriodicTracking();
    super.onClose();
  }

  Future<void> startPeriodicTracking() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return;

    _positionStream?.cancel();

    // Konfigurasi Foreground Service agar jalan 24 jam di background
    late LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update jika bergerak 10 meter
        forceLocationManager: true,
        // intervalDuration: const Duration(minutes: 5), // Not all versions support this, we handle via manual throttle
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: 'Tuberku memantau lokasi karantina Anda di latar belakang.',
          notificationTitle: 'Pelacakan Aktif',
          enableWakeLock: true,
        ),
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
    }

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position? position) async {
      if (position == null) return;
      
      // Throttle upload to every 5 minutes (300 seconds)
      final now = DateTime.now();
      if (_lastUploadTime != null) {
        final diff = now.difference(_lastUploadTime!);
        if (diff.inMinutes < 5) {
          return; // Skip if less than 5 minutes have passed
        }
      }

      await _trackAndUploadLocation(position);
    });
  }

  void stopPeriodicTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _cachedPatient = null;
  }

  void resetTrackingCache() {
    _cachedPatient = null;
  }

  Future<void> _trackAndUploadLocation(Position position) async {
    try {
      final supabase = Get.find<SupabaseService>();
      final currentUser = supabase.currentUser;
      if (currentUser == null) {
        _cachedPatient = null;
        return;
      }

      if (_cachedPatient == null) {
        final profile = await supabase.getProfile(currentUser.id);
        if (profile == null) return;

        final role = (profile.role ?? '').toLowerCase().trim();
        final isPatient = role == 'patient' || role == 'pasien';
        if (!isPatient) return;

        final patient = await supabase.getPatientByProfileId(currentUser.id);
        if (patient == null) return;
        
        if (!patient.gpsConsent) return;
        _cachedPatient = patient;
      }

      // ── Filter Jarak 100 Meter ──
      // Jika pasien bergerak kurang dari 100 meter dari lokasi upload terakhir, 
      // batalkan pengiriman agar tidak nyepam database.
      if (_lastUploadedPosition != null) {
        final distance = Geolocator.distanceBetween(
          _lastUploadedPosition!.latitude,
          _lastUploadedPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        if (distance < 100) {
          debugPrint('[LocationService] Bergeser hanya ${distance.toStringAsFixed(1)}m (<100m). Upload dibatalkan.');
          return;
        }
      }

      // ── Terjemahan Koordinat ke Alamat Jalan ──
      String placeName = 'Lat ${position.latitude.toStringAsFixed(5)}, Lng ${position.longitude.toStringAsFixed(5)}';
      try {
        final placemarks = await geo.placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          // Menyusun format jalan: "Jl. Rungkut, Surabaya"
          placeName = '${place.street ?? place.name}, ${place.subLocality ?? place.locality}';
          // Bersihkan koma berlebih jika datanya tidak lengkap
          placeName = placeName.replaceAll(RegExp(r'^,\s*'), '').replaceAll(RegExp(r',\s*$'), '');
        }
      } catch (_) {
        // Jika gagal menerjemahkan alamat (misal koneksi putus), tetap gunakan Lat/Lng
      }

      final log = TracingModel(
        id: '',
        patientId: _cachedPatient!.id,
        tracingRef: 'TRC-${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
        latitude: position.latitude,
        longitude: position.longitude,
        placeName: placeName,
        visitedAt: DateTime.now().toUtc(),
        createdAt: DateTime.now().toUtc(),
      );

      await supabase.insertTracingLog(log);
      
      // Update cache tracking terakhir
      _lastUploadTime = DateTime.now();
      _lastUploadedPosition = position;
      
      debugPrint('[LocationService] ✅ Uploaded lokasi valid: $placeName');

      // Hapus log lebih dari 24 jam
      await supabase.deleteOldTracingLogs(_cachedPatient!.id);
    } catch (e) {
      debugPrint('[LocationService] _trackAndUploadLocation error: $e');
    }
  }

  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    // Untuk background tracking, kita minta Always izin
    if (permission == LocationPermission.whileInUse) {
      // Tidak masalah untuk foreground service, 
      // OS Android modern menganggap foreground service setara "while in use".
    }

    return true;
  }

  Future<Position?> getCurrentPosition() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (_) {
      return null;
    }
  }

  List<FacilityModel> getNearestFacilities(
    List<FacilityModel> facilities,
    Position position,
  ) {
    for (final facility in facilities) {
      final distanceMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        facility.latitude,
        facility.longitude,
      );
      facility.distanceKm = distanceMeters / 1000;
    }
    facilities.sort((a, b) {
      final aDist = a.distanceKm ?? double.infinity;
      final bDist = b.distanceKm ?? double.infinity;
      return aDist.compareTo(bDist);
    });
    return facilities;
  }

  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
}
