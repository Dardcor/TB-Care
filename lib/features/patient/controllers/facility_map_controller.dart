import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/models/facility_model.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/supabase_service.dart';

class FacilityMapController extends GetxController {
  final _supabase = Get.find<SupabaseService>();
  final _location = Get.find<LocationService>();

  final isLoading = true.obs;
  final facilities = <FacilityModel>[].obs;
  final filteredFacilities = <FacilityModel>[].obs;
  final markers = <Marker>{}.obs;
  final selectedFilter = 'Terdekat'.obs;
  final hasError = false.obs;

  final filters = ['Terdekat', 'Puskesmas', 'Klinik', 'Apotek', 'Rumah Sakit'];

  final Rx<Position?> userPosition = Rx<Position?>(null);
  final Rx<FacilityModel?> selectedFacility = Rx<FacilityModel?>(null);

  GoogleMapController? mapController;

  @override
  void onInit() {
    super.onInit();
    _loadData();
  }

  Future<void> _loadData() async {
    isLoading.value = true;
    hasError.value = false;

    try {
      userPosition.value = await _location.getCurrentPosition();
      List<FacilityModel> result = [];

      try {
        result = await _supabase.getFacilities();
      } catch (_) {
        // Supabase error – fall back to dummy data
      }

      // Jika database kosong, gunakan dummy data Surabaya Timur
      if (result.isEmpty) {
        result = _dummyFacilities();
      }

      if (userPosition.value != null) {
        _location.getNearestFacilities(result, userPosition.value!);
      }

      facilities.assignAll(result);
      _applyFilter();
    } catch (e) {
      // Jika semua gagal, tetap tampilkan dummy data
      final dummy = _dummyFacilities();
      facilities.assignAll(dummy);
      _applyFilter();
    } finally {
      isLoading.value = false;
    }
  }

  /// Dummy data fasilitas kesehatan Surabaya Timur.
  /// Anda bisa menambah/mengedit data ini atau menggantinya dengan data dari database.
  List<FacilityModel> _dummyFacilities() {
    return [
      // ── PUSKESMAS ──────────────────────────────────────────────────────
      FacilityModel(
        id: 'dummy-pkm-mulyorejo',
        name: 'Puskesmas Mulyorejo',
        type: 'Puskesmas',
        address: 'Jl. Mulyorejo No.12, Mulyorejo, Surabaya',
        latitude: -7.2694,
        longitude: 112.7885,
        phone: '(031) 5913526',
        openingHours: {
          'Senin - Kamis': '07:30 - 14:00',
          'Jumat': '07:30 - 11:00',
          'Sabtu': '07:30 - 12:00',
          'Minggu': 'Tutup',
        },
      ),
      FacilityModel(
        id: 'dummy-pkm-sukolilo',
        name: 'Puskesmas Sukolilo',
        type: 'Puskesmas',
        address: 'Jl. Medokan Semampir No.27, Sukolilo, Surabaya',
        latitude: -7.2917,
        longitude: 112.7958,
        phone: '(031) 5942855',
        openingHours: {
          'Senin - Kamis': '07:30 - 14:00',
          'Jumat': '07:30 - 11:00',
          'Sabtu': '07:30 - 12:00',
          'Minggu': 'Tutup',
        },
      ),
      FacilityModel(
        id: 'dummy-pkm-menur',
        name: 'Puskesmas Menur',
        type: 'Puskesmas',
        address: 'Jl. Menur Pumpungan No.42, Menur Pumpungan, Surabaya',
        latitude: -7.2830,
        longitude: 112.7700,
        phone: '(031) 5941014',
        openingHours: {
          'Senin - Kamis': '07:30 - 14:00',
          'Jumat': '07:30 - 11:00',
          'Sabtu': '07:30 - 12:00',
          'Minggu': 'Tutup',
        },
      ),
      FacilityModel(
        id: 'dummy-pkm-rungkut',
        name: 'Puskesmas Rungkut',
        type: 'Puskesmas',
        address: 'Jl. Rungkut Asri Timur No.1, Rungkut, Surabaya',
        latitude: -7.3223,
        longitude: 112.7758,
        phone: '(031) 8700092',
        openingHours: {
          'Senin - Kamis': '07:30 - 14:00',
          'Jumat': '07:30 - 11:00',
          'Sabtu': '07:30 - 12:00',
          'Minggu': 'Tutup',
        },
      ),
      FacilityModel(
        id: 'dummy-pkm-kalirungkut',
        name: 'Puskesmas Kalirungkut',
        type: 'Puskesmas',
        address: 'Jl. Rungkut Lor No.22, Kalirungkut, Surabaya',
        latitude: -7.3200,
        longitude: 112.7810,
        phone: '(031) 8702063',
        openingHours: {
          'Senin - Kamis': '07:30 - 14:00',
          'Jumat': '07:30 - 11:00',
          'Sabtu': '07:30 - 12:00',
          'Minggu': 'Tutup',
        },
      ),
      FacilityModel(
        id: 'dummy-pkm-gunung-anyar',
        name: 'Puskesmas Gunung Anyar',
        type: 'Puskesmas',
        address: 'Jl. Gunung Anyar Timur No.8, Gunung Anyar, Surabaya',
        latitude: -7.3323,
        longitude: 112.7885,
        phone: '(031) 8716559',
        openingHours: {
          'Senin - Kamis': '07:30 - 14:00',
          'Jumat': '07:30 - 11:00',
          'Sabtu': '07:30 - 12:00',
          'Minggu': 'Tutup',
        },
      ),
      FacilityModel(
        id: 'dummy-pkm-tambaksari',
        name: 'Puskesmas Tambaksari',
        type: 'Puskesmas',
        address: 'Jl. Tambaksari No.71, Tambaksari, Surabaya',
        latitude: -7.2514,
        longitude: 112.7661,
        phone: '(031) 3712671',
        openingHours: {
          'Senin - Kamis': '07:30 - 14:00',
          'Jumat': '07:30 - 11:00',
          'Sabtu': '07:30 - 12:00',
          'Minggu': 'Tutup',
        },
      ),

      // ── RUMAH SAKIT ────────────────────────────────────────────────────
      FacilityModel(
        id: 'dummy-rs-dr-soetomo',
        name: 'RSUD Dr. Soetomo',
        type: 'Rumah Sakit',
        address: 'Jl. Mayjen Prof. Dr. Moestopo No.6-8, Airlangga, Surabaya',
        latitude: -7.2656,
        longitude: 112.7540,
        phone: '(031) 5501078',
        openingHours: {
          'Senin - Minggu': '24 Jam',
        },
      ),
      FacilityModel(
        id: 'dummy-rs-premier-surabaya',
        name: 'RS Premier Surabaya',
        type: 'Rumah Sakit',
        address: 'Jl. Nginden Intan Barat Blok B No.1, Surabaya',
        latitude: -7.3058,
        longitude: 112.7748,
        phone: '(031) 5993211',
        openingHours: {
          'Senin - Minggu': '24 Jam',
        },
      ),
      FacilityModel(
        id: 'dummy-rs-siloam-surabaya',
        name: 'RS Siloam Surabaya',
        type: 'Rumah Sakit',
        address: 'Jl. Raya Gubeng No.70, Gubeng, Surabaya',
        latitude: -7.2680,
        longitude: 112.7600,
        phone: '(031) 5057777',
        openingHours: {
          'Senin - Minggu': '24 Jam',
        },
      ),
      FacilityModel(
        id: 'dummy-rsia-kendangsari',
        name: 'RSIA Kendangsari MERR',
        type: 'Rumah Sakit',
        address: 'Jl. Kendangsari No.70-72, Surabaya',
        latitude: -7.3050,
        longitude: 112.7700,
        phone: '(031) 8437700',
        openingHours: {
          'Senin - Minggu': '24 Jam',
        },
      ),

      // ── KLINIK ─────────────────────────────────────────────────────────
      FacilityModel(
        id: 'dummy-klinik-kimia-farma-gubeng',
        name: 'Klinik Kimia Farma Gubeng',
        type: 'Klinik',
        address: 'Jl. Raya Gubeng No.52, Gubeng, Surabaya',
        latitude: -7.2700,
        longitude: 112.7555,
        phone: '(031) 5030363',
        openingHours: {
          'Senin - Sabtu': '07:00 - 21:00',
          'Minggu': '08:00 - 14:00',
        },
      ),
      FacilityModel(
        id: 'dummy-klinik-pratama-ITS',
        name: 'Klinik Pratama ITS',
        type: 'Klinik',
        address: 'Jl. Teknik Kimia, Keputih, Sukolilo, Surabaya',
        latitude: -7.2818,
        longitude: 112.7944,
        phone: '(031) 5994251',
        openingHours: {
          'Senin - Jumat': '07:30 - 15:30',
          'Sabtu': '07:30 - 12:00',
          'Minggu': 'Tutup',
        },
      ),
      FacilityModel(
        id: 'dummy-klinik-pratama-airlangga',
        name: 'Klinik Pratama UNAIR',
        type: 'Klinik',
        address: 'Jl. Airlangga No.4-6, Airlangga, Surabaya',
        latitude: -7.2681,
        longitude: 112.7505,
        phone: '(031) 5020151',
        openingHours: {
          'Senin - Jumat': '07:00 - 20:00',
          'Sabtu': '07:00 - 14:00',
          'Minggu': 'Tutup',
        },
      ),

      // ── APOTEK ─────────────────────────────────────────────────────────
      FacilityModel(
        id: 'dummy-apotek-k24-dharmahusada',
        name: 'Apotek K-24 Dharmahusada',
        type: 'Apotek',
        address: 'Jl. Dharmahusada No.142, Mulyorejo, Surabaya',
        latitude: -7.2712,
        longitude: 112.7785,
        phone: '(031) 5913288',
        openingHours: {
          'Senin - Minggu': '24 Jam',
        },
      ),
      FacilityModel(
        id: 'dummy-apotek-kimia-farma-manyar',
        name: 'Apotek Kimia Farma Manyar',
        type: 'Apotek',
        address: 'Jl. Manyar Kertoarjo No.17, Gubeng, Surabaya',
        latitude: -7.2762,
        longitude: 112.7672,
        phone: '(031) 5011488',
        openingHours: {
          'Senin - Minggu': '08:00 - 22:00',
        },
      ),
      FacilityModel(
        id: 'dummy-apotek-guardian-galaxy',
        name: 'Apotek Guardian Galaxy Mall',
        type: 'Apotek',
        address: 'Galaxy Mall Lt.1, Jl. Dharmahusada Indah Tim. No.37',
        latitude: -7.2740,
        longitude: 112.7838,
        phone: '(031) 5944200',
        openingHours: {
          'Senin - Minggu': '10:00 - 22:00',
        },
      ),
      FacilityModel(
        id: 'dummy-apotek-rungkut',
        name: 'Apotek K-24 Rungkut Madya',
        type: 'Apotek',
        address: 'Jl. Rungkut Madya No.122, Rungkut, Surabaya',
        latitude: -7.3248,
        longitude: 112.7790,
        phone: '(031) 8712244',
        openingHours: {
          'Senin - Minggu': '24 Jam',
        },
      ),
    ];
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
    _applyFilter();
  }

  void _applyFilter() {
    var result = facilities.toList();

    // Filter by type only — semua fasilitas selalu ditampilkan,
    // urutan jarak sudah diatur oleh getNearestFacilities saat load.
    switch (selectedFilter.value) {
      case 'Puskesmas':
        result = result
            .where((f) =>
                f.type.toLowerCase().contains('puskesmas') ||
                f.name.toLowerCase().contains('puskesmas'))
            .toList();
        break;
      case 'Klinik':
        result = result
            .where((f) =>
                f.type.toLowerCase().contains('klinik') ||
                f.name.toLowerCase().contains('klinik'))
            .toList();
        break;
      case 'Apotek':
        result = result
            .where((f) =>
                f.type.toLowerCase().contains('apotek') ||
                f.type.toLowerCase().contains('apotik') ||
                f.name.toLowerCase().contains('apotek') ||
                f.name.toLowerCase().contains('apotik'))
            .toList();
        break;
      case 'Rumah Sakit':
        result = result
            .where((f) =>
                f.type.toLowerCase().contains('rumah sakit') ||
                f.type.toLowerCase().contains('rsud') ||
                f.name.toLowerCase().contains('rumah sakit') ||
                f.name.toLowerCase().contains('rsud') ||
                f.name.toLowerCase().startsWith('rs ') ||
                f.name.toLowerCase().startsWith('rsia '))
            .toList();
        break;
      case 'Terdekat':
      default:
        // Sudah diurutkan berdasarkan jarak di _loadData
        break;
    }

    filteredFacilities.assignAll(result);
    _buildMarkers();
  }

  void _buildMarkers() {
    final newMarkers = <Marker>{};

    for (final facility in filteredFacilities) {
      final typeLower = facility.type.toLowerCase();
      final nameLower = facility.name.toLowerCase();

      final isApotek = typeLower.contains('apotek') || typeLower.contains('apotik') || nameLower.contains('apotek') || nameLower.contains('apotik');
      final isPuskesmas = typeLower.contains('puskesmas') || nameLower.contains('puskesmas');
      final isKlinik = typeLower.contains('klinik') || nameLower.contains('klinik');
      final isRumahSakit = typeLower.contains('rumah sakit') || typeLower.contains('rs') || typeLower.contains('rsud') || nameLower.contains('rumah sakit') || nameLower.contains('rs') || nameLower.contains('rsud');

      double hue;
      if (isApotek) {
        hue = BitmapDescriptor.hueAzure;
      } else if (isPuskesmas) {
        hue = BitmapDescriptor.hueGreen;
      } else if (isKlinik) {
        hue = BitmapDescriptor.hueOrange;
      } else if (isRumahSakit) {
        hue = BitmapDescriptor.hueRed;
      } else {
        hue = BitmapDescriptor.hueViolet;
      }

      newMarkers.add(
        Marker(
          markerId: MarkerId(facility.id),
          position: LatLng(facility.latitude, facility.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(
            title: facility.name,
            snippet: facility.formattedDistance,
          ),
          onTap: () => openFacilityDetail(facility),
        ),
      );
    }

    markers.assignAll(newMarkers);
  }

  void selectFacility(FacilityModel facility) {
    selectedFacility.value = facility;
  }

  void clearSelectedFacility() {
    selectedFacility.value = null;
  }

  void openFacilityDetail(FacilityModel facility) {
    Get.toNamed(
      AppRoutes.facilityDetail,
      arguments: facility,
    );
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _fitMarkers();
  }

  void _fitMarkers() {
    if (markers.isEmpty || mapController == null) return;

    List<LatLng> points = markers.map((m) => m.position).toList();
    if (userPosition.value != null) {
      points.add(LatLng(userPosition.value!.latitude, userPosition.value!.longitude));
    }

    if (points.isEmpty) return;

    LatLngBounds bounds = _boundsFromLatLngList(points);
    mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? minLat, maxLat, minLng, maxLng;
    for (final latLng in list) {
      if (minLat == null || latLng.latitude < minLat) minLat = latLng.latitude;
      if (maxLat == null || latLng.latitude > maxLat) maxLat = latLng.latitude;
      if (minLng == null || latLng.longitude < minLng) minLng = latLng.longitude;
      if (maxLng == null || latLng.longitude > maxLng) maxLng = latLng.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  LatLng get initialCameraPosition {
    if (userPosition.value != null) {
      return LatLng(userPosition.value!.latitude, userPosition.value!.longitude);
    }
    
    if (filteredFacilities.isNotEmpty) {
      return LatLng(filteredFacilities.first.latitude, filteredFacilities.first.longitude);
    }
    
    return const LatLng(-7.250445, 112.768845);
  }

  @override
  Future<void> refresh() async {
    await _loadData();
  }
}
