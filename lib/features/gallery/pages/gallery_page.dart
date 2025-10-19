import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../core/theme/soup_theme.dart';
import '../widgets/gallery_card.dart';
import '../widgets/gallery_filter.dart';
import '../models/gallery_item.dart';

/// SOUP施工実績ギャラリーページ
/// 公式サイトの施工実績を反映
class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  List<GalleryItem> _allItems = [];
  List<GalleryItem> _filteredItems = [];
  String _selectedFilter = 'all';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGalleryData();
  }

  Future<void> _loadGalleryData() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/seed/gallery.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      
      final List<dynamic> galleryList = data['gallery'] ?? [];
      _allItems = galleryList.map((item) => GalleryItem.fromJson(item)).toList();
      _filteredItems = List.from(_allItems);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // エラーハンドリング - デモデータを使用
      _loadDemoData();
    }
  }

  void _loadDemoData() {
    _allItems = [
      GalleryItem(
        id: 'demo_001',
        title: 'トヨタ RAV4 System X セラミックコーティング',
        description: '新車のRAV4にSystem Xセラミックコーティングを施工。深い艶と光沢を実現しました。',
        vehicle: VehicleInfo(
          make: 'トヨタ',
          model: 'RAV4',
          year: 2023,
          color: 'パールホワイト',
        ),
        service: 'system_x_ceramic',
        beforeImage: 'assets/soup_coating_gallery.webp',
        afterImage: 'assets/soup_coating_gallery.webp',
        date: DateTime(2024, 3, 15),
        tags: ['新車', 'SUV', 'セラミック', 'ホワイト'],
      ),
      GalleryItem(
        id: 'demo_002',
        title: 'レクサス LS G.Guard ガラスコーティング',
        description: '高級セダンのレクサスLSにG.Guardガラスコーティングを施工。上品な仕上がりになりました。',
        vehicle: VehicleInfo(
          make: 'レクサス',
          model: 'LS',
          year: 2022,
          color: 'ブラック',
        ),
        service: 'g_guard_glass',
        beforeImage: 'assets/soup_coating_gallery.webp',
        afterImage: 'assets/soup_coating_gallery.webp',
        date: DateTime(2024, 3, 10),
        tags: ['高級車', 'セダン', 'ガラス', 'ブラック'],
      ),
    ];
    _filteredItems = List.from(_allItems);
    setState(() {});
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'all') {
        _filteredItems = List.from(_allItems);
      } else {
        _filteredItems = _allItems.where((item) {
          switch (filter) {
            case 'ceramic':
              return item.service.contains('ceramic');
            case 'glass':
              return item.service.contains('glass');
            case 'bike':
              return item.service.contains('bike');
            case 'recent':
              return item.date.isAfter(DateTime.now().subtract(const Duration(days: 30)));
            default:
              return true;
          }
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SoupTheme.backgroundGray,
      appBar: AppBar(
        title: const Text('施工実績ギャラリー'),
        backgroundColor: SoupTheme.primaryNavy,
        foregroundColor: SoupTheme.textWhite,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 統計情報ヘッダー
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(SoupTheme.spacingL),
            decoration: BoxDecoration(
              gradient: SoupTheme.navyGradient,
            ),
            child: Column(
              children: [
                Text(
                  '累計施工実績',
                  style: SoupTheme.bodyLarge.copyWith(
                    color: SoupTheme.textWhite,
                  ),
                ),
                const SizedBox(height: SoupTheme.spacingS),
                Text(
                  '4万台+',
                  style: SoupTheme.headingLarge.copyWith(
                    color: SoupTheme.primaryGold,
                    fontSize: 36,
                  ),
                ),
                const SizedBox(height: SoupTheme.spacingS),
                Text(
                  '20年以上の実績と98.5%の満足度',
                  style: SoupTheme.bodyMedium.copyWith(
                    color: SoupTheme.textWhite.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          
          // フィルター
          GalleryFilter(
            selectedFilter: _selectedFilter,
            onFilterChanged: _applyFilter,
          ),
          
          // ギャラリーグリッド
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: SoupTheme.primaryGold,
                    ),
                  )
                : _filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              SoupIcons.gallery,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: SoupTheme.spacingM),
                            Text(
                              '該当する施工実績がありません',
                              style: SoupTheme.bodyLarge.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(SoupTheme.spacingM),
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: SoupTheme.spacingM,
                            mainAxisSpacing: SoupTheme.spacingM,
                          ),
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            return GalleryCard(
                              item: _filteredItems[index],
                              onTap: () => _showGalleryDetail(_filteredItems[index]),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showGalleryDetail(GalleryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: SoupTheme.surfaceWhite,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(SoupTheme.radiusL),
              ),
            ),
            child: Column(
              children: [
                // ハンドル
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // コンテンツ
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(SoupTheme.spacingL),
                    children: [
                      // メイン画像
                      ClipRRect(
                        borderRadius: BorderRadius.circular(SoupTheme.radiusM),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.asset(
                            item.afterImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  SoupIcons.gallery,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: SoupTheme.spacingL),
                      
                      // タイトル
                      Text(
                        item.title,
                        style: SoupTheme.headingMedium,
                      ),
                      
                      const SizedBox(height: SoupTheme.spacingS),
                      
                      // 車両情報
                      Container(
                        padding: const EdgeInsets.all(SoupTheme.spacingM),
                        decoration: BoxDecoration(
                          color: SoupTheme.backgroundGray,
                          borderRadius: BorderRadius.circular(SoupTheme.radiusM),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '車両情報',
                              style: SoupTheme.headingSmall,
                            ),
                            const SizedBox(height: SoupTheme.spacingS),
                            _buildInfoRow('メーカー', item.vehicle.make),
                            _buildInfoRow('車種', item.vehicle.model),
                            _buildInfoRow('年式', '${item.vehicle.year}年'),
                            _buildInfoRow('カラー', item.vehicle.color),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: SoupTheme.spacingL),
                      
                      // 施工内容
                      Text(
                        '施工内容',
                        style: SoupTheme.headingSmall,
                      ),
                      const SizedBox(height: SoupTheme.spacingS),
                      Text(
                        item.description,
                        style: SoupTheme.bodyMedium,
                      ),
                      
                      const SizedBox(height: SoupTheme.spacingL),
                      
                      // タグ
                      if (item.tags.isNotEmpty) ...[
                        Text(
                          'タグ',
                          style: SoupTheme.headingSmall,
                        ),
                        const SizedBox(height: SoupTheme.spacingS),
                        Wrap(
                          spacing: SoupTheme.spacingS,
                          runSpacing: SoupTheme.spacingS,
                          children: item.tags.map((tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: SoupTheme.primaryGold.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: SoupTheme.primaryGold.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              tag,
                              style: SoupTheme.bodySmall.copyWith(
                                color: SoupTheme.primaryGold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )).toList(),
                        ),
                        const SizedBox(height: SoupTheme.spacingL),
                      ],
                      
                      // 施工日
                      Container(
                        padding: const EdgeInsets.all(SoupTheme.spacingM),
                        decoration: BoxDecoration(
                          color: SoupTheme.primaryNavy.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(SoupTheme.radiusM),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              SoupIcons.time,
                              color: SoupTheme.primaryNavy,
                              size: 20,
                            ),
                            const SizedBox(width: SoupTheme.spacingS),
                            Text(
                              '施工日: ${_formatDate(item.date)}',
                              style: SoupTheme.bodyMedium.copyWith(
                                color: SoupTheme.primaryNavy,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: SoupTheme.spacingXL),
                      
                      // アクションボタン
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // 予約ページへ遷移
                          },
                          style: SoupTheme.primaryButton,
                          child: const Text('同様の施工を予約する'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: SoupTheme.bodySmall.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            value,
            style: SoupTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }
}
