import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/config/app_colors.dart';
import '../../../app/config/app_text_styles.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/empty_state.dart';
import '../controllers/patient_dashboard_controller.dart';
import '../widgets/quick_access_card.dart';
import '../widgets/article_card.dart';

class PatientDashboardContent extends GetView<PatientDashboardController> {
  const PatientDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
        if (controller.isLoading.value) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: LoadingShimmer(itemCount: 4),
          );
        }

        if (controller.hasError.value) {
          return EmptyState(
            icon: Icons.error_outline,
            title: 'Gagal memuat data',
            subtitle: 'Periksa koneksi internet Anda',
            buttonText: 'Coba Lagi',
            onButtonPressed: controller.refresh,
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreetingCard(),
                const SizedBox(height: 24),
                _buildQuickAccessGrid(),
                const SizedBox(height: 24),
                _buildArticlesSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      });
  }

  Widget _buildGreetingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_sunny_outlined,
                  color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Obx(() => Text(
                    'Halo, ${controller.userName.value.isNotEmpty ? controller.userName.value : 'Pasien'}!',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.white,
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tetap jaga kesehatan dan semangat!',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        QuickAccessCard(
          icon: Icons.smart_toy,
          label: 'Tuberku AI',
          iconColor: AppColors.primary,
          onTap: () => Get.toNamed(AppRoutes.aiChat),
        ),
        QuickAccessCard(
          icon: Icons.local_pharmacy,
          label: 'Cari Apotek',
          iconColor: AppColors.warning,
          onTap: () => Get.toNamed(AppRoutes.facilityMap),
        ),
      ],
    );
  }

  Widget _buildArticlesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Artikel Terbaru', style: AppTextStyles.titleLarge),
            TextButton(
              onPressed: () => controller.changeTab(2),
              child: Text(
                'Lihat Semua',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: Obx(() {
            if (controller.articles.isEmpty) {
              return const Center(
                child: Text('Belum ada artikel'),
              );
            }
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount:
                  controller.articles.length > 4 ? 4 : controller.articles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final article = controller.articles[index];
                return SizedBox(
                  width: 260,
                  child: ArticleCard(
                    source: article.source,
                    title: article.title,
                    date: article.pubDate != null
                        ? DateFormat('dd MMM yyyy').format(article.pubDate!)
                        : '',
                    readTime: article.readingTime,
                    onTap: () {
                      Get.toNamed(
                        AppRoutes.articleDetail,
                        arguments: article,
                      );
                    },
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}
