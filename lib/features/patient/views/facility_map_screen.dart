import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/config/app_colors.dart';
import '../../../app/config/app_text_styles.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/models/facility_model.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/empty_state.dart';
import '../controllers/facility_map_controller.dart';

class FacilityMapScreen extends GetView<FacilityMapController> {
  const FacilityMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: LoadingShimmer(itemCount: 1, height: 300),
          );
        }

        if (controller.hasError.value) {
          return EmptyState(
            icon: Icons.error_outline,
            title: 'Gagal memuat peta',
            subtitle: 'Periksa koneksi internet dan izin lokasi',
            buttonText: 'Coba Lagi',
            onButtonPressed: controller.refresh,
          );
        }

        return Stack(
          children: [
            // ─── Full-screen Google Map ──────────────────────────────────
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: controller.initialCameraPosition,
                  zoom: 13,
                ),
                markers: controller.markers.toSet(),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
                zoomControlsEnabled: false,
                style: '''
[
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.medical","stylers":[{"visibility":"on"}]},
  {"featureType":"poi.healthcare","stylers":[{"visibility":"on"}]},
  {"featureType":"poi.business","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.government","stylers":[{"visibility":"off"}]}
]
''',
                onMapCreated: controller.onMapCreated,
                onTap: (_) => controller.clearSelectedFacility(),
              ),
            ),

            // ─── Filter chips ────────────────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = controller.filters[index];
                    final isSelected = controller.selectedFilter.value == filter;
                    return GestureDetector(
                      onTap: () => controller.setFilter(filter),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ─── Legend ────────────────────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 62,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _LegendItem(color: Color(0xFF0F9D58), label: 'Puskesmas'),
                    SizedBox(height: 4),
                    _LegendItem(color: Color(0xFFFF6D00), label: 'Klinik'),
                    SizedBox(height: 4),
                    _LegendItem(color: Color(0xFF1976D2), label: 'Apotek'),
                    SizedBox(height: 4),
                    _LegendItem(color: Color(0xFFD32F2F), label: 'RS'),
                  ],
                ),
              ),
            ),

            // ─── Facility count badge ───────────────────────────────────
            Positioned(
              bottom: 200,
              left: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Obx(() => Text(
                      '${controller.filteredFacilities.length} fasilitas ditemukan',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    )),
              ),
            ),

            // ─── My location FAB ────────────────────────────────────────
            Positioned(
              bottom: 200,
              right: 16,
              child: FloatingActionButton.small(
                heroTag: 'my_location',
                backgroundColor: Colors.white,
                elevation: 4,
                onPressed: () {
                  final pos = controller.userPosition.value;
                  if (pos != null && controller.mapController != null) {
                    controller.mapController!.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(pos.latitude, pos.longitude),
                        15,
                      ),
                    );
                  }
                },
                child: const Icon(Icons.my_location,
                    color: AppColors.primary, size: 20),
              ),
            ),

            // ─── Facility preview popup (shown when marker is tapped) ──
            Obx(() {
              final facility = controller.selectedFacility.value;
              if (facility == null) return const SizedBox.shrink();
              return _FacilityPreviewCard(facility: facility, controller: controller);
            }),

            // ─── Bottom facility list sheet ──────────────────────────────
            Obx(() {
              if (controller.selectedFacility.value != null) {
                return const SizedBox.shrink();
              }
              return _FacilityListSheet(controller: controller);
            }),
          ],
        );
      }),
    );
  }
}

// ─── Legend item widget ────────────────────────────────────────────────────────
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color(0xFF555555))),
      ],
    );
  }
}

// ─── Facility preview popup card ───────────────────────────────────────────────
class _FacilityPreviewCard extends StatelessWidget {
  final FacilityModel facility;
  final FacilityMapController controller;
  const _FacilityPreviewCard(
      {required this.facility, required this.controller});

  IconData _iconFor(String type) {
    final t = type.toLowerCase();
    if (t.contains('puskesmas')) return Icons.health_and_safety;
    if (t.contains('rumah sakit') || t.contains('rs')) return Icons.local_hospital;
    if (t.contains('klinik')) return Icons.medical_services;
    if (t.contains('apotek') || t.contains('apotik')) return Icons.local_pharmacy;
    return Icons.place;
  }

  Color _colorFor(String type) {
    final t = type.toLowerCase();
    if (t.contains('puskesmas')) return const Color(0xFF0F9D58);
    if (t.contains('rumah sakit') || t.contains('rs')) return const Color(0xFFD32F2F);
    if (t.contains('klinik')) return const Color(0xFFFF6D00);
    if (t.contains('apotek') || t.contains('apotik')) return const Color(0xFF1976D2);
    return AppColors.primary;
  }

  Future<void> _openMaps() async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${facility.latitude},${facility.longitude}&travelmode=driving',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _colorFor(facility.type);
    final firstHours = (facility.openingHours != null && facility.openingHours!.isNotEmpty) ? facility.openingHours!.entries.first : null;

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header strip with type color
              Container(
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.08),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_iconFor(facility.type),
                          color: typeColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            facility.name,
                            style: AppTextStyles.titleMedium
                                .copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              facility.type.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: typeColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: controller.clearSelectedFacility,
                      icon: const Icon(Icons.close,
                          size: 20, color: Color(0xFF999999)),
                    ),
                  ],
                ),
              ),
              // Info row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Column(
                  children: [
                    if (facility.address != null)
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        text: facility.address!,
                        iconColor: Colors.grey.shade500,
                      ),
                    if (firstHours != null) ...[
                      const SizedBox(height: 6),
                      _InfoRow(
                        icon: Icons.access_time_outlined,
                        text: '${firstHours.key}: ${firstHours.value}',
                        iconColor: Colors.grey.shade500,
                      ),
                    ],
                    if (facility.distanceKm != null) ...[
                      const SizedBox(height: 6),
                      _InfoRow(
                        icon: Icons.directions_walk_outlined,
                        text: facility.formattedDistance + ' dari lokasi Anda',
                        iconColor: Colors.grey.shade500,
                      ),
                    ],
                  ],
                ),
              ),
              // Action buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
                child: Row(
                  children: [
                    // Route to GMaps
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openMaps,
                        icon: const Icon(Icons.directions, size: 18),
                        label: const Text('Rute GMaps'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A73E8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Detail button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          controller.clearSelectedFacility();
                          Get.toNamed(
                            AppRoutes.facilityDetail,
                            arguments: facility,
                          );
                        },
                        icon: Icon(Icons.info_outline,
                            size: 18, color: typeColor),
                        label: const Text('Lihat Detail'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: typeColor,
                          side: BorderSide(color: typeColor),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;
  const _InfoRow(
      {required this.icon, required this.text, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 12.5, color: Color(0xFF444444), height: 1.4)),
        ),
      ],
    );
  }
}

// ─── Bottom draggable facility list ────────────────────────────────────────────
class _FacilityListSheet extends StatelessWidget {
  final FacilityMapController controller;
  const _FacilityListSheet({required this.controller});

  IconData _iconFor(String type) {
    final t = type.toLowerCase();
    if (t.contains('puskesmas')) return Icons.health_and_safety;
    if (t.contains('rumah sakit') || t.contains('rs')) return Icons.local_hospital;
    if (t.contains('klinik')) return Icons.medical_services;
    if (t.contains('apotek') || t.contains('apotik')) return Icons.local_pharmacy;
    return Icons.place;
  }

  Color _colorFor(String type) {
    final t = type.toLowerCase();
    if (t.contains('puskesmas')) return const Color(0xFF0F9D58);
    if (t.contains('rumah sakit') || t.contains('rs')) return const Color(0xFFD32F2F);
    if (t.contains('klinik')) return const Color(0xFFFF6D00);
    if (t.contains('apotek') || t.contains('apotik')) return const Color(0xFF1976D2);
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.28,
      minChildSize: 0.1,
      maxChildSize: 0.65,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Fasilitas Kesehatan',
                              style: AppTextStyles.titleMedium),
                          Obx(() => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${controller.filteredFacilities.length} lokasi',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )),
                        ],
                      ),
                    ),
                    Divider(color: Colors.grey.shade100, height: 1),
                  ],
                ),
              ),
              Obx(() {
                if (controller.filteredFacilities.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text('Tidak ada fasilitas ditemukan',
                            style: TextStyle(color: Color(0xFF999999))),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final facility =
                            controller.filteredFacilities[index];
                        final typeColor = _colorFor(facility.type);
                        final firstHours =
                            (facility.openingHours != null && facility.openingHours!.isNotEmpty)
                                ? facility.openingHours!.entries.first
                                : null;
                        return GestureDetector(
                          onTap: () {
                            Get.toNamed(
                              AppRoutes.facilityDetail,
                              arguments: facility,
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.grey.shade100, width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: typeColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(_iconFor(facility.type),
                                      color: typeColor, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        facility.name,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A1A2E),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      if (firstHours != null)
                                        Row(
                                          children: [
                                            Icon(Icons.access_time,
                                                size: 11,
                                                color: Colors.grey.shade500),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${firstHours.key}: ${firstHours.value}',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                      Colors.grey.shade600),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (facility.distanceKm != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: typeColor.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          facility.formattedDistance,
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: typeColor),
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Icon(Icons.chevron_right,
                                        size: 18,
                                        color: Colors.grey.shade400),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: controller.filteredFacilities.length,
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
