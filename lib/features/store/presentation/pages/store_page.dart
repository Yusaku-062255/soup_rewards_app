import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/models/app_models.dart';

class StorePage extends ConsumerStatefulWidget {
  const StorePage({super.key});

  @override
  ConsumerState<StorePage> createState() => _StorePageState();
}

class _StorePageState extends ConsumerState<StorePage> {
  StoreInfo? _storeInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStoreInfo();
  }

  Future<void> _loadStoreInfo() async {
    // TODO: WordPress APIから店舗情報を取得
    // 現在はダミーデータを使用
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _storeInfo = StoreInfo(
        id: '1',
        name: 'SOUP カーケアサービス',
        address: '徳島県徳島市○○町○○番地',
        phoneNumber: '0883-22-8655',
        email: 'info@soup.tokushima.jp',
        latitude: 34.0658,
        longitude: 134.5594,
        description: '徳島発のプロフェッショナルカーケアサービス。最新の技術と設備で、お客様の愛車を美しく保ちます。',
        images: [
          'https://soup.tokushima.jp/wp-content/uploads/store-exterior.jpg',
          'https://soup.tokushima.jp/wp-content/uploads/store-interior.jpg',
        ],
      );
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '店舗情報',
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
              onRefresh: _loadStoreInfo,
              child: _storeInfo == null
                  ? const Center(
                      child: Text(
                        '店舗情報が見つかりませんでした',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStoreImages(),
                          _buildStoreDetails(),
                          _buildContactSection(),
                          _buildMapSection(),
                        ],
                      ),
                    ),
            ),
    );
  }

  Widget _buildStoreImages() {
    if (_storeInfo?.images.isEmpty ?? true) {
      return Container(
        height: 200,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(
            Icons.store,
            size: 48,
            color: Colors.grey,
          ),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: _storeInfo!.images.length,
        itemBuilder: (context, index) {
          return CachedNetworkImage(
            imageUrl: _storeInfo!.images[index],
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
                Icons.store,
                size: 48,
                color: Colors.grey,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStoreDetails() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _storeInfo!.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _storeInfo!.description ?? '',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF4B5563),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'お問い合わせ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          
          // 電話番号
          _buildContactItem(
            icon: Icons.phone,
            title: '電話番号',
            content: _storeInfo!.phoneNumber,
            onTap: () => _makePhoneCall(_storeInfo!.phoneNumber),
            actionText: '電話をかける',
          ),
          const SizedBox(height: 16),
          
          // メールアドレス
          _buildContactItem(
            icon: Icons.email,
            title: 'メールアドレス',
            content: _storeInfo!.email,
            onTap: () => _sendEmail(_storeInfo!.email),
            actionText: 'メールを送る',
          ),
          const SizedBox(height: 16),
          
          // 住所
          _buildContactItem(
            icon: Icons.location_on,
            title: '住所',
            content: _storeInfo!.address,
            onTap: () => _openMap(),
            actionText: '地図で見る',
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String content,
    required VoidCallback onTap,
    required String actionText,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF3B82F6),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onTap,
                child: Text(
                  actionText,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    return Container(
      margin: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'アクセス',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: _openMap,
              borderRadius: BorderRadius.circular(12),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map,
                      size: 48,
                      color: Color(0xFF6B7280),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'タップして地図を開く',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openMap,
              icon: const Icon(Icons.directions),
              label: const Text('地図アプリで開く'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    // TODO: Analytics logging
    final uri = Uri.parse('tel:$phoneNumber');
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showErrorSnackBar('電話をかけることができませんでした');
      }
    } catch (e) {
      _showErrorSnackBar('電話をかけることができませんでした');
    }
  }

  Future<void> _sendEmail(String email) async {
    // TODO: Analytics logging
    final uri = Uri.parse('mailto:$email');
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showErrorSnackBar('メールアプリを開けませんでした');
      }
    } catch (e) {
      _showErrorSnackBar('メールアプリを開けませんでした');
    }
  }

  Future<void> _openMap() async {
    // TODO: Analytics logging
    final mapUrl = 'https://maps.apple.com/?q=SOUP+Tokushima&ll=${_storeInfo!.latitude},${_storeInfo!.longitude}';
    final uri = Uri.parse(mapUrl);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar('地図アプリを開けませんでした');
      }
    } catch (e) {
      _showErrorSnackBar('地図アプリを開けませんでした');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
