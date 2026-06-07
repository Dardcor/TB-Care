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
  
  // Topic selection
  final selectedTopic = 'Info TBC'.obs;
  final List<String> availableTopics = [
    'Info TBC',
    'Pencegahan',
    'Pengobatan',
    'Gaya Hidup',
    'Gizi & Diet',
    'Kesehatan Mental',
    'Lainnya'
  ];

  @override
  void onClose() {
    titleController.dispose();
    linkController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  void changeTopic(String? newTopic) {
    if (newTopic != null) {
      selectedTopic.value = newTopic;
    }
  }

  Future<void> saveArticle() async {
    final title = titleController.text.trim();
    final link = linkController.text.trim();
    final description = descriptionController.text.trim();
    final topic = selectedTopic.value;

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
        'source': topic, // Repurposed as topic
        'pub_date': DateTime.now().toIso8601String(),
      };

      await _supabase.client.from('articles').insert(articleData);

      // Membuat notifikasi broadcast kepada seluruh pasien
      await _supabase.createBroadcastNotification(
        'Artikel Baru: $title',
        'Ada artikel edukasi baru untuk Anda. Yuk baca sekarang!',
        'article',
      );

      Get.back(result: true);
      Get.snackbar('Berhasil', 'Artikel kesehatan berhasil ditambahkan',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.black);
    } catch (e) {
      Get.snackbar('Gagal', 'Terjadi kesalahan: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.black);
    } finally {
      isLoading.value = false;
    }
  }
}
