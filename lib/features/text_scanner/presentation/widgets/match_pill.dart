import 'package:flutter/material.dart';
import '../../domain/entities/text_match.dart';

class MatchPill extends StatelessWidget {
  final TextMatch match;
  final VoidCallback? onTap;

  const MatchPill({super.key, required this.match, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _getColorForMatchType(match.matchType);
    final isClickable = match.matchType != MatchType.none;

    return GestureDetector(
      onTap: isClickable ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconForMatchType(match.matchType),
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              match.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (match.confidence != null &&
                match.matchType == MatchType.partial)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(match.confidence! * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getColorForMatchType(MatchType matchType) {
    switch (matchType) {
      case MatchType.exact:
        return const Color(0xFF374151); // Graphite Gray
      case MatchType.partial:
        return const Color(0xFFFACC15); // Safety Yellow
      case MatchType.none:
        return const Color(0xFFEF4444); // Red
    }
  }

  IconData _getIconForMatchType(MatchType matchType) {
    switch (matchType) {
      case MatchType.exact:
        return Icons.check_circle;
      case MatchType.partial:
        return Icons.search;
      case MatchType.none:
        return Icons.cancel;
    }
  }
}
