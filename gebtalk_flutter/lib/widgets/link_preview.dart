import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Renders a link preview card for URLs found in messages
class LinkPreviewWidget extends StatelessWidget {
  final String url;
  final bool isUser;

  const LinkPreviewWidget({
    super.key,
    required this.url,
    this.isUser = false,
  });

  @override
  Widget build(BuildContext context) {
    // Parse domain from URL
    String domain = '';
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      domain = uri.host.replaceFirst('www.', '');
    } catch (_) {
      domain = url;
    }

    // Choose icon based on common domains
    IconData domainIcon = Icons.link_rounded;
    Color accentColor = Colors.blueAccent;
    if (domain.contains('youtube') || domain.contains('youtu.be')) {
      domainIcon = Icons.play_circle_filled_rounded;
      accentColor = Colors.red;
    } else if (domain.contains('github')) {
      domainIcon = Icons.code_rounded;
      accentColor = Colors.white70;
    } else if (domain.contains('twitter') || domain.contains('x.com')) {
      domainIcon = Icons.alternate_email_rounded;
      accentColor = Colors.lightBlueAccent;
    } else if (domain.contains('instagram')) {
      domainIcon = Icons.camera_alt_rounded;
      accentColor = Colors.pinkAccent;
    } else if (domain.contains('linkedin')) {
      domainIcon = Icons.business_rounded;
      accentColor = Colors.blueAccent;
    } else if (domain.contains('google')) {
      domainIcon = Icons.search_rounded;
      accentColor = Colors.greenAccent;
    } else if (domain.contains('stackoverflow')) {
      domainIcon = Icons.question_answer_rounded;
      accentColor = Colors.orangeAccent;
    }

    return GestureDetector(
      onTap: () {
        // TODO: Launch URL
      },
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isUser
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top accent bar
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  // Domain icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(domainIcon, color: accentColor, size: 20),
                  ),
                  const SizedBox(width: 10),

                  // Domain + URL
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          domain,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          url.length > 60 ? '${url.substring(0, 57)}...' : url,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // External link icon
                  Icon(
                    Icons.open_in_new_rounded,
                    color: Colors.white.withValues(alpha: 0.3),
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
