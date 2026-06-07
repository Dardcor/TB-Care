import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/config/app_colors.dart';
import '../../../core/models/facility_model.dart';

class FacilityDetailScreen extends StatelessWidget {
  /// Data fasilitas bisa dikirim via constructor (Get.to) ATAU via Get.arguments (Get.toNamed).
  final FacilityModel? facility;
  const FacilityDetailScreen({super.key, this.facility});

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

  Future<void> _openMaps(FacilityModel facility) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${facility.latitude},${facility.longitude}'
      '&destination_place_id=${Uri.encodeComponent(facility.name)}'
      '&travelmode=driving',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openMapsSearch(FacilityModel facility) async {
    final query = Uri.encodeComponent(
        '${facility.name}, ${facility.address ?? 'Surabaya'}');
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query&query_place_id=${facility.latitude},${facility.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Prioritas: constructor param → Get.arguments fallback
    final FacilityModel? data = facility ?? (Get.arguments is FacilityModel ? Get.arguments as FacilityModel : null);

    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Fasilitas')),
        body: const Center(child: Text('Fasilitas tidak ditemukan')),
      );
    }

    // Alias untuk kompatibilitas kode di bawah
    final typeColor = _colorFor(data.type);
    final typeIcon = _iconFor(data.type);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // ─── Hero App Bar ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: typeColor,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      typeColor,
                      typeColor.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -30,
                      right: -20,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -10,
                      left: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                    ),
                    // Content
                    SafeArea(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 50, 20, 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child:
                                  Icon(typeIcon, color: Colors.white, size: 28),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              data.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.22),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                data.type.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Body content ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Info card ──────────────────────────────────────────
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Distance badge
                        if (data.distanceKm != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.near_me,
                                    size: 13, color: typeColor),
                                const SizedBox(width: 5),
                                Text(
                                  '${data.formattedDistance} dari lokasi Anda',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: typeColor),
                                ),
                              ],
                            ),
                          ),
                        if (data.address != null)
                          _DetailRow(
                            icon: Icons.location_on_outlined,
                            iconColor: typeColor,
                            text: data.address!,
                          ),
                        if (data.phone != null) ...[
                          const SizedBox(height: 12),
                          _DetailRow(
                            icon: Icons.phone_outlined,
                            iconColor: typeColor,
                            text: data.phone!,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Jam Operasional ────────────────────────────────────
                  if (data.openingHours != null &&
                      data.openingHours!.isNotEmpty) ...[
                    _SectionHeader(
                      icon: Icons.access_time_outlined,
                      label: 'Jam Operasional',
                      iconColor: typeColor,
                    ),
                    const SizedBox(height: 10),
                    _SectionCard(
                      child: Column(
                        children: data.openingHours!.entries
                            .toList()
                            .asMap()
                            .entries
                            .map((e) {
                          final isLast = e.key ==
                              data.openingHours!.length - 1;
                          final entry = e.value;
                          final isClosed =
                              entry.value.toString().toLowerCase() == 'tutup';
                          final is24h = entry.value.toString() == '24 Jam';
                          return Column(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 9),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        entry.key,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w500,
                                          color: isClosed
                                              ? Colors.grey.shade400
                                              : const Color(0xFF2D2D2D),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isClosed
                                            ? Colors.grey.shade100
                                            : is24h
                                                ? Colors.green.shade50
                                                : typeColor.withOpacity(0.08),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (is24h)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 4),
                                              child: Icon(Icons.all_inclusive,
                                                  size: 12,
                                                  color: Colors.green.shade600),
                                            ),
                                          Text(
                                            entry.value.toString(),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isClosed
                                                  ? Colors.grey.shade400
                                                  : is24h
                                                      ? Colors.green.shade700
                                                      : typeColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isLast)
                                Divider(
                                    color: Colors.grey.shade100, height: 1),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 8),

                  // ── Action buttons ─────────────────────────────────────
                  Row(
                    children: [
                      // Rute Google Maps
                      Expanded(
                        flex: 3,
                        child: _ActionButton(
                          label: 'Rute ke Sini',
                          icon: Icons.directions,
                          backgroundColor: const Color(0xFF1A73E8),
                          textColor: Colors.white,
                          onPressed: () => _openMaps(data),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Buka di GMaps
                      Expanded(
                        flex: 2,
                        child: _ActionButton(
                          label: 'Cari di Maps',
                          icon: Icons.map_outlined,
                          backgroundColor: Colors.white,
                          textColor: const Color(0xFF1A73E8),
                          borderColor: const Color(0xFF1A73E8),
                          onPressed: () => _openMapsSearch(data),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  const _SectionHeader(
      {required this.icon, required this.label, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: iconColor),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E)),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  const _DetailRow(
      {required this.icon, required this.iconColor, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
                fontSize: 13.5, color: Color(0xFF444444), height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(14),
      elevation: borderColor == null ? 2 : 0,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: borderColor != null
                ? Border.all(color: borderColor!, width: 1.5)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
