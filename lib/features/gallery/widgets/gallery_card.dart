import 'package:flutter/material.dart';
import '../../../core/theme/soup_theme.dart';
import '../models/gallery_item.dart';

/// ギャラリーカードウィジェット
class GalleryCard extends StatelessWidget {
  final GalleryItem item;
  final VoidCallback onTap;

  const GalleryCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: SoupTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 画像
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(SoupTheme.radiusM),
                ),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      child: Image.asset(
                        item.afterImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              SoupIcons.gallery,
                              size: 32,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // サービスタイプバッジ
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getServiceColor(item.service),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getServiceLabel(item.service),
                          style: SoupTheme.bodySmall.copyWith(
                            color: SoupTheme.textWhite,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 情報部分
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(SoupTheme.spacingS),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 車両名
                    Text(
                      item.vehicle.displayName,
                      style: SoupTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 2),
                    
                    // 年式・カラー
                    Text(
                      '${item.vehicle.year}年 ${item.vehicle.color}',
                      style: SoupTheme.bodySmall.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const Spacer(),
                    
                    // 施工日
                    Row(
                      children: [
                        Icon(
                          SoupIcons.time,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(item.date),
                          style: SoupTheme.bodySmall.copyWith(
                            color: Colors.grey[500],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getServiceColor(String service) {
    if (service.contains('ceramic')) {
      return SoupTheme.primaryGold;
    } else if (service.contains('glass')) {
      return SoupTheme.primaryNavy;
    } else if (service.contains('bike')) {
      return SoupTheme.accentOrange;
    } else {
      return Colors.grey[600]!;
    }
  }

  String _getServiceLabel(String service) {
    if (service.contains('ceramic')) {
      return 'セラミック';
    } else if (service.contains('glass')) {
      return 'ガラス';
    } else if (service.contains('bike')) {
      return 'バイク';
    } else {
      return 'その他';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}
