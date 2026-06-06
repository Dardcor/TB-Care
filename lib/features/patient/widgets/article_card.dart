import 'package:flutter/material.dart';
import '../../../app/config/app_colors.dart';
import '../../../app/config/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';

class ArticleCard extends StatelessWidget {
  final String source;
  final String title;
  final String preview;
  final String date;
  final String readTime;
  final VoidCallback? onTap;

  const ArticleCard({
    super.key,
    required this.source,
    required this.title,
    this.preview = '',
    this.date = '',
    this.readTime = '',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Source badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              source,
              style: const TextStyle(
                color: AppColors.success,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Title
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (preview.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              preview,
              style: AppTextStyles.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (date.isNotEmpty || readTime.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (date.isNotEmpty)
                  Text(
                    date,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                if (date.isNotEmpty && readTime.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '•',
                      style: TextStyle(color: AppColors.textHint, fontSize: 10),
                    ),
                  ),
                if (readTime.isNotEmpty)
                  Text(
                    readTime,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    ),
    );
  }
}
