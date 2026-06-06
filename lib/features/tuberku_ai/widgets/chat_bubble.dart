import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/config/app_colors.dart';
import '../../../app/config/app_text_styles.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final String? source;
  final String time;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.source,
    this.time = '',
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: EdgeInsets.only(
          left: isUser ? 48 : 0,
          right: isUser ? 0 : 48,
          bottom: 8,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Text(
                  'Tuberku AI',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.cardBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: isUser
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextWithLinks(context, text, isUser),
                  if (source != null && !isUser) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        source!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (time.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                child: Text(
                  time,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textHint,
                    fontSize: 9,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextWithLinks(BuildContext context, String text, bool isUser) {
    // Regex matches [Title](URL) OR plain URL
    final RegExp urlRegex = RegExp(r'\[([^\]]+)\]\((https?:\/\/[^\s\)]+)\)|(https?:\/\/[^\s\)]+)');
    final matches = urlRegex.allMatches(text);

    if (matches.isEmpty) {
      return Text(
        text,
        style: AppTextStyles.bodyMedium.copyWith(
          color: isUser ? AppColors.white : AppColors.textPrimary,
          height: 1.5,
        ),
      );
    }

    final List<TextSpan> spans = [];
    int lastMatchEnd = 0;

    for (var match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: AppTextStyles.bodyMedium.copyWith(
            color: isUser ? AppColors.white : AppColors.textPrimary,
            height: 1.5,
          ),
        ));
      }

      String textToShow;
      String urlToLaunch;

      if (match.group(1) != null && match.group(2) != null) {
        // Matched [Title](URL)
        textToShow = match.group(1)!;
        urlToLaunch = match.group(2)!;
      } else {
        // Matched plain URL
        textToShow = match.group(0)!;
        urlToLaunch = match.group(0)!;
      }

      spans.add(TextSpan(
        text: textToShow,
        style: AppTextStyles.bodyMedium.copyWith(
          color: isUser ? AppColors.white : AppColors.primary,
          decoration: TextDecoration.underline,
          height: 1.5,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            final uri = Uri.tryParse(urlToLaunch);
            if (uri != null && await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
      ));

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: AppTextStyles.bodyMedium.copyWith(
          color: isUser ? AppColors.white : AppColors.textPrimary,
          height: 1.5,
        ),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }
}

