import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/config/app_colors.dart';
import '../../../app/config/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../controllers/article_form_controller.dart';

class ArticleFormScreen extends GetView<ArticleFormController> {
  const ArticleFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Input Artikel Baru'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Publikasikan artikel edukasi kesehatan TBC baru untuk dibaca oleh pasien.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            AppCard(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildField(
                    label: 'Judul Artikel *',
                    hint: 'Masukkan judul artikel kesehatan',
                    controller: controller.titleController,
                  ),
                    const Text(
                      'Kategori / Topik *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: controller.selectedTopic.value,
                              items: controller.availableTopics
                                  .map((topic) => DropdownMenuItem(
                                        value: topic,
                                        child: Text(topic),
                                      ))
                                  .toList(),
                              onChanged: controller.changeTopic,
                            ),
                          ),
                        )),
                    const SizedBox(height: 20),
                  _buildField(
                    label: 'Tautan/Link Artikel (Opsional)',
                    hint: 'Contoh: https://ayosehat.kemkes.go.id/...',
                    controller: controller.linkController,
                    keyboardType: TextInputType.url,
                  ),
                  _buildField(
                    label: 'Ringkasan / Konten Artikel',
                    hint: 'Masukkan deskripsi singkat atau isi artikel...',
                    controller: controller.descriptionController,
                    maxLines: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
        decoration: const BoxDecoration(
          color: AppColors.background,
        ),
        child: Obx(() => AppButton(
          text: 'PUBLIKASIKAN ARTIKEL',
          icon: Icons.publish_outlined,
          isLoading: controller.isLoading.value,
          onPressed: controller.saveArticle,
        )),
      ),
    );
  }

  Widget _buildField({
    required String label,
    String? hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
