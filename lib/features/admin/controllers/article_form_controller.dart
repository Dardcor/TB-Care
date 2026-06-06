import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/supabase_service.dart';

class ArticleFormController extends GetxController {
  final _supabase = Get.find<SupabaseService>();

  final isLoading = false.obs;

  // Controllers
  final titleController = TextEditingController();
  final linkController = TextEditingController();
  final descriptionController = TextEditingController();
  final sourceController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    sourceController.text = 'Kemenkes RI'; // Default source
  }

  @override
  void onClose() {
    titleController.dispose();
    linkController.dispose();
    descriptionController.dispose();
    sourceController.dispose();
    super.onClose();
  }

  Future<void> saveArticle() async {
    final title = titleController.text.trim();
    final link = linkController.text.trim();
    final description = descriptionController.text.trim();
    final source = sourceController.text.trim();

    if (title.isEmpty) {
      Get.snackbar('Error', 'Judul artikel wajib diisi',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
      return;
    }

    isLoading.value = true;
    try {
      final articleData = {
        'title': title,
        if (link.isNotEmpty) 'link': link,
        if (description.isNotEmpty) 'description': description,
        'source': source.isNotEmpty ? source : 'Kemenkes RI',
        'pub_date': DateTime.now().toIso8601String(),
      };

      await _supabase.insertArticle(articleData);

      Get.snackbar('Berhasil', 'artikel baru sedang diupload',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100);

      // Clear the inputs
      titleController.clear();
      linkController.clear();
      descriptionController.clear();
      sourceController.text = 'Kemenkes RI';

      Get.back(); // Go back to the previous screen
    } catch (e) {
      Get.snackbar('Gagal Mempublikasikan', 'Terjadi kesalahan: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100);
    } finally {
      isLoading.value = false;
    }
  }
}
