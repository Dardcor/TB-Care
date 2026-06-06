import 'package:get/get.dart';
import '../../../core/services/rss_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/models/article_model.dart';

class ArticleController extends GetxController {
  final _rss = Get.find<RssService>();
  final _supabase = Get.find<SupabaseService>();

  final isLoading = true.obs;
  final articles = <ArticleModel>[].obs;
  final filteredArticles = <ArticleModel>[].obs;
  final searchQuery = ''.obs;
  final selectedFilter = 'Semua'.obs;
  final hasError = false.obs;

  final filters = ['Semua', 'Kemenkes RI', 'WHO'].obs;

  // Current article for detail page
  final Rx<ArticleModel?> currentArticle = Rx<ArticleModel?>(null);

  @override
  void onInit() {
    super.onInit();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    isLoading.value = true;
    hasError.value = false;

    try {
      final rssResult = await _rss.fetchArticles();
      final supabaseResult = await _supabase.getArticles();
      
      final allArticles = [...supabaseResult, ...rssResult];
      
      // Remove duplicates by title if any (Supabase might have seeded RSS items)
      final uniqueArticles = <String, ArticleModel>{};
      for (var article in allArticles) {
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
      _applyFilters();
    } catch (_) {
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
    _applyFilters();
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  void _applyFilters() {
    var result = articles.toList();

    // Apply source filter
    if (selectedFilter.value != 'Semua') {
      result = result
          .where((a) => a.source
              .toLowerCase()
              .contains(selectedFilter.value.toLowerCase()))
          .toList();
    }

    // Apply search
    if (searchQuery.value.isNotEmpty) {
      result = result
          .where((a) =>
              a.title
                  .toLowerCase()
                  .contains(searchQuery.value.toLowerCase()) ||
              a.description
                  .toLowerCase()
                  .contains(searchQuery.value.toLowerCase()))
          .toList();
    }

    filteredArticles.assignAll(result);
  }

  Future<void> refresh() async {
    await _loadArticles();
  }

  void selectArticle(ArticleModel article) {
    currentArticle.value = article;
  }
}
