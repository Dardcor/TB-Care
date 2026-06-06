import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/models/article_model.dart';
import '../views/patient_dashboard_content.dart';
import '../views/facility_map_screen.dart';
import '../views/article_list_screen.dart';
import '../../profile/views/profile_screen.dart';
import '../controllers/article_controller.dart';
import '../controllers/facility_map_controller.dart';
import '../../profile/controllers/profile_controller.dart';

class PatientDashboardController extends GetxController {
  final _supabase = Get.find<SupabaseService>();

  final isLoading = true.obs;
  final userName = ''.obs;
  final articles = <ArticleModel>[].obs;
  final currentTabIndex = 0.obs;
  final hasError = false.obs;

  late final List<Widget> pages = [
    const PatientDashboardContent(),
    const FacilityMapScreen(),
    const ArticleListScreen(),
    const ProfileScreen(),
  ];

  @override
  void onInit() {
    super.onInit();
    // Initialize required controllers
    Get.put(ProfileController());
    Get.put(ArticleController());
    Get.put(FacilityMapController());
    
    _loadData();
  }

  Future<void> _loadData() async {
    isLoading.value = true;
    hasError.value = false;

    try {
      await Future.wait([
        _loadProfile(),
        _loadArticles(),
      ]);
    } catch (_) {
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadProfile() async {
    final user = _supabase.currentUser;
    if (user != null) {
      final profile = await _supabase.getProfile(user.id);
      if (profile != null) {
        userName.value = profile.fullName;
      }
    }
  }

  Future<void> _loadArticles() async {
    final supabaseResult = await _supabase.getArticles();
    
    final uniqueArticles = <String, ArticleModel>{};
    for (var article in supabaseResult) {
      uniqueArticles[article.title] = article;
    }
    
    final mergedList = uniqueArticles.values.toList();
    mergedList.sort((a, b) {
      if (a.pubDate == null && b.pubDate == null) return 0;
      if (a.pubDate == null) return 1;
      if (b.pubDate == null) return -1;
      return b.pubDate!.compareTo(a.pubDate!);
    });

    articles.assignAll(mergedList);
  }

  Future<void> refresh() async {
    await _loadData();
  }

  void changeTab(int index) {
    currentTabIndex.value = index;
  }
}
