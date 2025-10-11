import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/utils/performance_utils.dart';

/// 改善されたホームページ - 状態管理とエラーハンドリング対応
class ImprovedHomePage extends ConsumerStatefulWidget {
  const ImprovedHomePage({super.key});

  @override
  ConsumerState<ImprovedHomePage> createState() => _ImprovedHomePageState();
}

class _ImprovedHomePageState extends ConsumerState<ImprovedHomePage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    try {
      // 並列でデータを読み込み
      await Future.wait([
        ref.read(couponsProvider.notifier).loadCoupons(),
        ref.read(newsProvider.notifier).loadNews(),
      ]);
    } catch (e, stackTrace) {
      AppErrorHandler.handleError(e, stackTrace);
      if (mounted) {
        AppErrorHandler.showErrorSnackBar(
          context,
          'データの読み込みに失敗しました',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final points = ref.watch(pointsProvider);
    final coupons = ref.watch(couponsProvider);
    final news = ref.watch(newsProvider);

    return LoadingOverlay(
      isLoading: _isLoading,
      message: 'データを読み込み中...',
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary,
                AppColors.white,
              ],
              stops: [0.0, 0.3],
            ),
          ),
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadInitialData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ヘッダー部分
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    
                    // ポイントカード
                    _buildPointCard(context, points),
                    const SizedBox(height: 24),
                    
                    // クイックアクション
                    _buildQuickActions(context),
                    const SizedBox(height: 24),
                    
                    // 最新ニュース
                    _buildNewsSection(context, news),
                    const SizedBox(height: 24),
                    
                    // クーポン一覧
                    _buildCouponsSection(context, coupons),
                    const SizedBox(height: 24),
                    
                    // おすすめサービス
                    _buildRecommendedServices(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'おかえりなさい',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () {
              // 通知画面への遷移
              PerformanceUtils.debounce('notification_tap', () {
                // TODO: 通知画面実装
                AppErrorHandler.showSuccessSnackBar(
                  context,
                  '通知機能は準備中です',
                );
              });
            },
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPointCard(BuildContext context, int points) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondary,
            Color(0xFFFFF3C4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ポイント残高',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'GOLD',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                points.toString(),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 36,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'pt',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    PerformanceUtils.debounce('use_points', () {
                      // TODO: ポイント使用画面への遷移
                      AppErrorHandler.showSuccessSnackBar(
                        context,
                        'ポイント使用機能は準備中です',
                      );
                    });
                  },
                  icon: const Icon(Icons.redeem),
                  label: const Text('ポイントを使う'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    PerformanceUtils.debounce('earn_points', () {
                      // TODO: ポイント獲得方法画面への遷移
                      AppErrorHandler.showSuccessSnackBar(
                        context,
                        'ポイント獲得方法を確認中...',
                      );
                    });
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('貯める'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.qr_code_scanner,
        label: 'QRスキャン',
        color: AppColors.primary,
        onTap: () {
          PerformanceUtils.debounce('qr_scan', () {
            // TODO: QRスキャン画面への遷移
            AppErrorHandler.showSuccessSnackBar(
              context,
              'QRスキャン機能は準備中です',
            );
          });
        },
      ),
      _QuickAction(
        icon: Icons.local_offer,
        label: 'クーポン',
        color: AppColors.secondary,
        onTap: () {
          PerformanceUtils.debounce('coupons', () {
            // TODO: クーポン画面への遷移
            AppErrorHandler.showSuccessSnackBar(
              context,
              'クーポン画面は準備中です',
            );
          });
        },
      ),
      _QuickAction(
        icon: Icons.store,
        label: '店舗検索',
        color: AppColors.accent,
        onTap: () {
          PerformanceUtils.debounce('store_search', () {
            // TODO: 店舗検索画面への遷移
            AppErrorHandler.showSuccessSnackBar(
              context,
              '店舗検索機能は準備中です',
            );
          });
        },
      ),
      _QuickAction(
        icon: Icons.history,
        label: '利用履歴',
        color: AppColors.textSecondary,
        onTap: () {
          PerformanceUtils.debounce('history', () {
            // TODO: 利用履歴画面への遷移
            AppErrorHandler.showSuccessSnackBar(
              context,
              '利用履歴機能は準備中です',
            );
          });
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'クイックアクション',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: actions.map((action) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildQuickActionItem(context, action),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickActionItem(BuildContext context, _QuickAction action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                action.icon,
                color: action.color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsSection(BuildContext context, List<News> news) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '最新ニュース',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                PerformanceUtils.debounce('view_all_news', () {
                  // TODO: ニュース一覧画面への遷移
                  AppErrorHandler.showSuccessSnackBar(
                    context,
                    'ニュース一覧は準備中です',
                  );
                });
              },
              child: const Text('すべて見る'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (news.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('ニュースがありません'),
            ),
          )
        else
          ...news.take(3).map((newsItem) => _buildNewsItem(context, newsItem)),
      ],
    );
  }

  Widget _buildNewsItem(BuildContext context, News news) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.article,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  news.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  news.content,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '${news.publishDate.month}/${news.publishDate.day}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponsSection(BuildContext context, List<Coupon> coupons) {
    final availableCoupons = coupons.where((c) => !c.isUsed).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '利用可能なクーポン',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                PerformanceUtils.debounce('view_all_coupons', () {
                  // TODO: クーポン一覧画面への遷移
                  AppErrorHandler.showSuccessSnackBar(
                    context,
                    'クーポン一覧は準備中です',
                  );
                });
              },
              child: const Text('すべて見る'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (availableCoupons.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('利用可能なクーポンがありません'),
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: availableCoupons.length,
              itemBuilder: (context, index) {
                return _buildCouponItem(context, availableCoupons[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCouponItem(BuildContext context, Coupon coupon) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondary,
            Color(0xFFFFF3C4),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${coupon.discountRate}% OFF',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            coupon.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            '有効期限: ${coupon.expiryDate.month}/${coupon.expiryDate.day}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedServices(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'おすすめサービス',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                Color(0xFF0088CC),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: AppColors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'プレミアムコーティング',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '長期間効果が持続する最新のコーティング技術で、あなたの愛車を美しく保護します。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  PerformanceUtils.debounce('premium_coating', () {
                    // TODO: プレミアムコーティング詳細画面への遷移
                    AppErrorHandler.showSuccessSnackBar(
                      context,
                      'プレミアムコーティングの詳細は準備中です',
                    );
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('詳細を見る'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
