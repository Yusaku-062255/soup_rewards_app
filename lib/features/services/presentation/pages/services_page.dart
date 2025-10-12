import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/models/app_models.dart';
import 'service_detail_page.dart';

class ServicesPage extends ConsumerStatefulWidget {
  const ServicesPage({super.key});

  @override
  ConsumerState<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends ConsumerState<ServicesPage> {
  List<ServiceModel> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    // TODO: WordPress APIからサービス情報を取得
    // 現在はダミーデータを使用
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _services = [
        ServiceModel(
          id: '1',
          name: 'プレミアムコーティング',
          description: '最高級のガラスコーティングで愛車を長期間保護します。撥水効果と光沢が長続きし、洗車も楽になります。',
          priceRange: '50,000円〜',
          durationMin: 180,
          gallery: ['https://soup.tokushima.jp/wp-content/uploads/service1.jpg'],
          featuredImage: 'https://soup.tokushima.jp/wp-content/uploads/service1.jpg',
          createdAt: DateTime.now(),
        ),
        ServiceModel(
          id: '2',
          name: 'ボディクリーニング',
          description: '専用機材と技術で車体の汚れを徹底除去。新車のような輝きを取り戻します。',
          priceRange: '15,000円〜',
          durationMin: 120,
          gallery: ['https://soup.tokushima.jp/wp-content/uploads/service2.jpg'],
          featuredImage: 'https://soup.tokushima.jp/wp-content/uploads/service2.jpg',
          createdAt: DateTime.now(),
        ),
        ServiceModel(
          id: '3',
          name: 'インテリアクリーニング',
          description: '車内の隅々まで丁寧にクリーニング。シートやカーペットの汚れ・臭いを除去します。',
          priceRange: '12,000円〜',
          durationMin: 90,
          gallery: ['https://soup.tokushima.jp/wp-content/uploads/service3.jpg'],
          featuredImage: 'https://soup.tokushima.jp/wp-content/uploads/service3.jpg',
          createdAt: DateTime.now(),
        ),
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'サービス・料金',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadServices,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _services.length,
                itemBuilder: (context, index) {
                  final service = _services[index];
                  return _buildServiceCard(service);
                },
              ),
            ),
    );
  }

  Widget _buildServiceCard(ServiceModel service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToServiceDetail(service),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // サービス画像
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: service.featuredImage ?? '',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.car_repair,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
            // サービス情報
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    service.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (service.priceRange != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            service.priceRange!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (service.durationMin != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '約${service.durationMin}分',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Color(0xFF6B7280),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToServiceDetail(ServiceModel service) {
    // TODO: Analytics logging
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ServiceDetailPage(service: service),
      ),
    );
  }
}
