import 'package:flutter/material.dart';
import 'package:muslim/src/features/quran/data/models/ayah_model.dart';

class SearchResultCard extends StatelessWidget {
  final Ayah ayah;
  final String searchQuery;
  final VoidCallback onTap;

  const SearchResultCard({
    super.key,
    required this.ayah,
    required this.searchQuery,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Surah and Ayah info
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${ayah.numberInSurah}:${ayah.number}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Surah ${ayah.numberInSurah}', // This would be the actual surah name
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                  ),
                  const Spacer(),
                  if (ayah.isFavorite)
                    const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 16,
                    ),
                  if (ayah.isBookmarked) const SizedBox(width: 4),
                  if (ayah.isBookmarked)
                    Icon(
                      Icons.bookmark,
                      color: Theme.of(context).colorScheme.primary,
                      size: 16,
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Arabic text with highlighted search term
              RichText(
                text: _buildHighlightedText(
                  ayah.text,
                  searchQuery,
                  Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: 18,
                            height: 1.8,
                          ) ??
                      const TextStyle(),
                  Theme.of(context).colorScheme.primary,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),

              // Translation if available
              if (ayah.translation != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: RichText(
                    text: _buildHighlightedText(
                      ayah.translation!,
                      searchQuery,
                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                              ) ??
                          const TextStyle(),
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // Additional info
              Row(
                children: [
                  _buildInfoChip(context, 'Juz ${ayah.juz}'),
                  const SizedBox(width: 8),
                  _buildInfoChip(context, 'Page ${ayah.page}'),
                  if (ayah.sajda) ...[
                    const SizedBox(width: 8),
                    _buildInfoChip(context, 'Sajda', color: Colors.orange),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (color ?? Theme.of(context).colorScheme.secondary)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color ?? Theme.of(context).colorScheme.secondary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  TextSpan _buildHighlightedText(
    String text,
    String searchQuery,
    TextStyle baseStyle,
    Color highlightColor,
  ) {
    if (searchQuery.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    final List<TextSpan> spans = [];
    final String lowerText = text.toLowerCase();
    final String lowerQuery = searchQuery.toLowerCase();

    int start = 0;
    int index = lowerText.indexOf(lowerQuery);

    while (index != -1) {
      // Add text before the match
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: baseStyle,
        ));
      }

      // Add highlighted match
      spans.add(TextSpan(
        text: text.substring(index, index + searchQuery.length),
        style: baseStyle.copyWith(
          backgroundColor: highlightColor.withValues(alpha: 0.3),
          fontWeight: FontWeight.bold,
        ),
      ));

      start = index + searchQuery.length;
      index = lowerText.indexOf(lowerQuery, start);
    }

    // Add remaining text
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: baseStyle,
      ));
    }

    return TextSpan(children: spans);
  }
}
