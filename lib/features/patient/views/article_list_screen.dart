import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/config/app_colors.dart';
import '../../../app/config/app_text_styles.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/empty_state.dart';
import '../controllers/article_controller.dart';
import '../widgets/article_card.dart';

class ArticleListScreen extends GetView<ArticleController> {
  const ArticleListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: controller.setSearchQuery,
              decoration: InputDecoration(
                hintText: 'Cari artikel...',
                hintStyle: TextStyle(color: AppColors.textHint),
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          // Filter chips
          SizedBox(
            height: 40,
            child: Obx(() {
              // Mendaftarkan dependency di luar itemBuilder agar Obx bereaksi
              final currentFilter = controller.selectedFilter.value;
              return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = controller.filters[index];
                    final isSelected = currentFilter == filter;
                    return FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (_) => controller.setFilter(filter),
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.cardBg,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      side: BorderSide(
                        color:
                            isSelected ? AppColors.primary : AppColors.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  },
                );
            }),
          ),
          const SizedBox(height: 12),
          // Article list
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: LoadingShimmer(itemCount: 5, height: 120),
                );
              }

              if (controller.hasError.value) {
                return EmptyState(
                  icon: Icons.error_outline,
                  title: 'Gagal memuat artikel',
                  subtitle: 'Periksa koneksi internet Anda',
                  buttonText: 'Coba Lagi',
                  onButtonPressed: controller.refresh,
                );
              }

              if (controller.filteredArticles.isEmpty) {
                return const EmptyState(
                  icon: Icons.article_outlined,
                  title: 'Tidak ada artikel',
                  subtitle: 'Coba ubah filter atau kata kunci pencarian',
                );
              }

              return RefreshIndicator(
                onRefresh: controller.refresh,
                color: AppColors.primary,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.filteredArticles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final article = controller.filteredArticles[index];
                    return ArticleCard(
                      source: article.source,
                      title: article.title,
                      preview: article.description,
                      date: article.pubDate != null
                          ? DateFormat('dd MMM yyyy')
                              .format(article.pubDate!)
                          : '',
                      readTime: article.readingTime,
                      onTap: () {
                        controller.selectArticle(article);
                        Get.toNamed(
                          AppRoutes.articleDetail,
                          arguments: article,
                        );
                      },
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
