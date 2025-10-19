import 'package:flutter/material.dart';
import '../../../core/theme/soup_theme.dart';

/// ギャラリーフィルターウィジェット
class GalleryFilter extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const GalleryFilter({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SoupTheme.spacingM),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'すべて', SoupIcons.gallery),
            const SizedBox(width: SoupTheme.spacingS),
            _buildFilterChip('ceramic', 'セラミック', SoupIcons.coating),
            const SizedBox(width: SoupTheme.spacingS),
            _buildFilterChip('glass', 'ガラス', SoupIcons.glass),
            const SizedBox(width: SoupTheme.spacingS),
            _buildFilterChip('bike', 'バイク', SoupIcons.bike),
            const SizedBox(width: SoupTheme.spacingS),
            _buildFilterChip('recent', '最新', SoupIcons.time),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = selectedFilter == value;
    
    return GestureDetector(
      onTap: () => onFilterChanged(value),
      child: AnimatedContainer(
        duration: SoupTheme.animationDuration,
        padding: const EdgeInsets.symmetric(
          horizontal: SoupTheme.spacingM,
          vertical: SoupTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? SoupTheme.primaryGold : SoupTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? SoupTheme.primaryGold 
                : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: SoupTheme.primaryGold.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected 
                  ? SoupTheme.textWhite 
                  : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: SoupTheme.bodySmall.copyWith(
                color: isSelected 
                    ? SoupTheme.textWhite 
                    : Colors.grey[700],
                fontWeight: isSelected 
                    ? FontWeight.w600 
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
