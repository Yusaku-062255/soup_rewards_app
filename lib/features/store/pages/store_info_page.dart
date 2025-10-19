import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/soup_theme.dart';

/// SOUP店舗情報ページ
/// 公式サイトの店舗情報を反映
class StoreInfoPage extends StatelessWidget {
  const StoreInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SoupTheme.backgroundGray,
      appBar: AppBar(
        title: const Text('店舗情報'),
        backgroundColor: SoupTheme.primaryNavy,
        foregroundColor: SoupTheme.textWhite,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ヘッダー画像
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage('assets/soup_interior_section.webp'),
                  fit: BoxFit.cover,
                ),
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    SoupTheme.primaryNavy.withOpacity(0.3),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(SoupTheme.spacingL),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      SoupTheme.primaryNavy.withOpacity(0.7),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SOUP（スープ）',
                      style: SoupTheme.headingLarge.copyWith(
                        color: SoupTheme.textWhite,
                      ),
                    ),
                    const SizedBox(height: SoupTheme.spacingS),
                    Text(
                      '徳島のカーコーティング専門店',
                      style: SoupTheme.bodyLarge.copyWith(
                        color: SoupTheme.primaryGold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: SoupTheme.spacingL),
            
            // 基本情報
            _buildInfoSection(
              title: '基本情報',
              children: [
                _buildInfoItem(
                  icon: SoupIcons.location,
                  title: '住所',
                  content: '〒771-2302\n徳島県三好市三野町加茂野宮445−1',
                  onTap: _launchMap,
                ),
                _buildInfoItem(
                  icon: SoupIcons.phone,
                  title: '電話番号',
                  content: '088-377-2016',
                  onTap: _launchPhone,
                ),
                _buildInfoItem(
                  icon: Icons.fax,
                  title: 'FAX',
                  content: '088-382-5485',
                ),
                _buildInfoItem(
                  icon: Icons.language,
                  title: 'ウェブサイト',
                  content: 'https://soup.tokushima.jp/',
                  onTap: _launchWebsite,
                ),
              ],
            ),
            
            // 営業時間
            _buildInfoSection(
              title: '営業時間',
              children: [
                _buildInfoItem(
                  icon: SoupIcons.time,
                  title: '営業時間',
                  content: '9:00 - 18:00',
                ),
                _buildInfoItem(
                  icon: Icons.event_busy,
                  title: '定休日',
                  content: '日曜日・祝日\n（施工内容により営業の場合あり）',
                ),
                _buildInfoItem(
                  icon: SoupIcons.reserve,
                  title: '予約',
                  content: '事前予約制\n（当日予約も可能な場合あり）',
                ),
              ],
            ),
            
            // サービス内容
            _buildInfoSection(
              title: 'サービス内容',
              children: [
                _buildServiceItem(
                  'System X セラミックコーティング',
                  '航空宇宙産業向けに開発された世界最高水準のコーティング',
                  SoupTheme.primaryGold,
                ),
                _buildServiceItem(
                  'G.Guard ガラスコーティング',
                  '無機質のガラス被膜で長期間の美しさを維持',
                  SoupTheme.primaryNavy,
                ),
                _buildServiceItem(
                  'System X バイクコーティング',
                  'バイク専用の高性能セラミックコーティング',
                  SoupTheme.accentOrange,
                ),
                _buildServiceItem(
                  'パーツコーティング',
                  'ホイール・ガラス・インテリアなど部位別の専用コーティング',
                  Colors.grey[600]!,
                ),
              ],
            ),
            
            // 実績・特徴
            _buildInfoSection(
              title: '実績・特徴',
              children: [
                Container(
                  padding: const EdgeInsets.all(SoupTheme.spacingL),
                  decoration: BoxDecoration(
                    gradient: SoupTheme.goldGradient,
                    borderRadius: BorderRadius.circular(SoupTheme.radiusM),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('4万台+', '施工実績'),
                          _buildStatItem('20年+', '業界経験'),
                          _buildStatItem('98.5%', '満足度'),
                        ],
                      ),
                      const SizedBox(height: SoupTheme.spacingL),
                      Text(
                        'キレイな車は幸せを呼ぶ！',
                        style: SoupTheme.headingSmall.copyWith(
                          color: SoupTheme.textWhite,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: SoupTheme.spacingS),
                      Text(
                        'SOUPでは、車を大切にするという事業を通じて、幸せなクオリティタイムを応援しています。',
                        style: SoupTheme.bodyMedium.copyWith(
                          color: SoupTheme.textWhite.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // アクションボタン
            Padding(
              padding: const EdgeInsets.all(SoupTheme.spacingL),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _launchReservation,
                      style: SoupTheme.primaryButton,
                      icon: const Icon(SoupIcons.reserve),
                      label: const Text('施工予約・お問い合わせ'),
                    ),
                  ),
                  const SizedBox(height: SoupTheme.spacingM),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _launchPhone,
                          style: SoupTheme.outlineButton,
                          icon: const Icon(SoupIcons.phone),
                          label: const Text('電話する'),
                        ),
                      ),
                      const SizedBox(width: SoupTheme.spacingM),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _launchMap,
                          style: SoupTheme.outlineButton,
                          icon: const Icon(SoupIcons.location),
                          label: const Text('地図を見る'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: SoupTheme.spacingXL),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: SoupTheme.spacingM,
        vertical: SoupTheme.spacingS,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: SoupTheme.spacingS,
              bottom: SoupTheme.spacingM,
            ),
            child: Text(
              title,
              style: SoupTheme.headingMedium,
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(SoupTheme.spacingM),
              child: Column(
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String content,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SoupTheme.spacingM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SoupTheme.radiusS),
        child: Padding(
          padding: const EdgeInsets.all(SoupTheme.spacingS),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SoupTheme.primaryGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: SoupTheme.primaryGold,
                  size: 20,
                ),
              ),
              const SizedBox(width: SoupTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: SoupTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      content,
                      style: SoupTheme.bodyMedium.copyWith(
                        color: onTap != null 
                            ? SoupTheme.primaryNavy 
                            : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceItem(String title, String description, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: SoupTheme.spacingM),
      padding: const EdgeInsets.all(SoupTheme.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(SoupTheme.radiusM),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: SoupTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: SoupTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: SoupTheme.bodySmall.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: SoupTheme.headingMedium.copyWith(
            color: SoupTheme.textWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: SoupTheme.bodySmall.copyWith(
            color: SoupTheme.textWhite.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Future<void> _launchPhone() async {
    const phoneNumber = 'tel:088-377-2016';
    if (await canLaunchUrl(Uri.parse(phoneNumber))) {
      await launchUrl(Uri.parse(phoneNumber));
    }
  }

  Future<void> _launchMap() async {
    const mapUrl = 'https://maps.google.com/?q=徳島県三好市三野町加茂野宮445-1';
    if (await canLaunchUrl(Uri.parse(mapUrl))) {
      await launchUrl(
        Uri.parse(mapUrl),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Future<void> _launchWebsite() async {
    const websiteUrl = 'https://soup.tokushima.jp/';
    if (await canLaunchUrl(Uri.parse(websiteUrl))) {
      await launchUrl(
        Uri.parse(websiteUrl),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Future<void> _launchReservation() async {
    const reservationUrl = 'https://soup.tokushima.jp/reserve';
    if (await canLaunchUrl(Uri.parse(reservationUrl))) {
      await launchUrl(
        Uri.parse(reservationUrl),
        mode: LaunchMode.externalApplication,
      );
    }
  }
}
