// ポイント詳細画面（EV統合版）
import 'package:flutter/material.dart';
import '../../../core/services/points_service.dart';
import '../../../core/services/vehicle_store.dart';
import '../../../core/services/coupon_store.dart';
import '../../../core/models/coupon_model.dart';

class PointsDetailPage extends StatefulWidget {
  const PointsDetailPage({super.key});

  @override
  State<PointsDetailPage> createState() => _PointsDetailPageState();
}

class _PointsDetailPageState extends State<PointsDetailPage> {
  bool _isLoading = false;
  bool _isExchanging = false;
  Map<String, dynamic>? _pointsStats;
  Map<String, dynamic>? _vehicleInfo;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkLoginBonus();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final pointsStats = await PointsService.getPointsStats();
      final vehicleInfo = await VehicleStore.getVehicleInfo();
      
      if (mounted) {
        setState(() {
          _pointsStats = pointsStats;
          _vehicleInfo = vehicleInfo;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('データの読み込みに失敗しました');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkLoginBonus() async {
    try {
      final result = await PointsService.checkLoginBonus();
      
      if (mounted && result['isFirstLogin']) {
        _showLoginBonusDialog(result['bonusAmount'], result['message']);
      }
    } catch (e) {
      // ログインボーナスのエラーは無視
    }
  }

  Future<void> _exchangeForFuelCoupon() async {
    if (_pointsStats == null || _pointsStats!['currentPoints'] < 5000) return;
    
    setState(() => _isExchanging = true);
    
    try {
      final coupon = CouponModel.createFuelCoupon();
      final couponAdded = await CouponStore.addCoupon(coupon);

      if (!couponAdded) {
        if (mounted) {
          _showErrorSnackBar('クーポンの発行に失敗しました。既に同じクーポンをお持ちの可能性があります。');
        }
        return;
      }

      final success = await PointsService.spendPoints(5000, '給油券と交換');

      if (!success) {
        await CouponStore.removeCoupon(coupon.id);
        if (mounted) {
          _showErrorSnackBar('交換に失敗しました');
        }
        return;
      }

      await _loadData();

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('交換処理でエラーが発生しました');
      }
    } finally {
      if (mounted) {
        setState(() => _isExchanging = false);
      }
    }
  }

  void _showLoginBonusDialog(int bonusAmount, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Color(0xFFFFB300), size: 28),
            SizedBox(width: 8),
            Text('ログインボーナス！'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '+${bonusAmount}pt',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFB300),
              ),
            ),
            const SizedBox(height: 8),
            Text(message),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB300),
              foregroundColor: Colors.white,
            ),
            child: const Text('ありがとう！'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('交換完了！'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🎉 給油券と交換しました！'),
            SizedBox(height: 8),
            Text('(-5000pt)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('クーポン画面から確認できます。', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ポイント詳細'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pointsStats == null
              ? const Center(child: Text('ポイント情報を読み込めませんでした'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ポイント残高カード
                        _buildPointsCard(),
                        const SizedBox(height: 16),
                        
                        // ランク情報カード
                        _buildRankCard(),
                        const SizedBox(height: 16),
                        
                        // EV特典情報（EV車の場合のみ表示）
                        if (_vehicleInfo?['isEv'] == true) ...[
                          _buildEvBenefitCard(),
                          const SizedBox(height: 16),
                        ],
                        
                        // 交換ボタン
                        _buildExchangeButton(),
                        const SizedBox(height: 24),
                        
                        // 履歴セクション
                        _buildHistorySection(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildPointsCard() {
    final currentPoints = _pointsStats!['currentPoints'] ?? 0;
    final totalEarned = _pointsStats!['totalEarned'] ?? 0;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '現在のポイント',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$currentPoints',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'pt',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '累計獲得: ${totalEarned}pt',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankCard() {
    final currentRank = _pointsStats!['currentRank'];
    final nextRank = _pointsStats!['nextRank'];
    final progress = _pointsStats!['progress'] ?? 0.0;
    final pointsToNext = _pointsStats!['pointsToNextRank'] ?? 0;
    
    if (currentRank == null) return const SizedBox.shrink();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  currentRank['icon'] ?? '🥉',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _parseRankColor(currentRank['color'] as String?),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    currentRank['name'] ?? 'ブロンズ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                if (_vehicleInfo?['isEv'] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB300).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'EV ${currentRank['evMultiplier']}x',
                      style: const TextStyle(
                        color: Color(0xFFFFB300),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
            if (nextRank != null && pointsToNext > 0) ...[
              const SizedBox(height: 16),
              Text(
                '次のランクまで',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFB300)),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${pointsToNext}pt',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFB300),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${nextRank['name']} まで',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFFFB300),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ] else if (nextRank == null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB300).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.emoji_events, color: Color(0xFFFFB300)),
                    SizedBox(width: 8),
                    Text(
                      '最高ランク達成！',
                      style: TextStyle(
                        color: Color(0xFFFFB300),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEvBenefitCard() {
    final currentRank = _pointsStats!['currentRank'];
    final evMultiplier = currentRank?['evMultiplier'] ?? 1.0;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFB300).withOpacity(0.1),
              const Color(0xFFFFB300).withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.electric_car,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'EV特典',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFB300),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '登録されたEV車により、ポイント獲得時に ${evMultiplier}倍 のボーナスが適用されます！',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB300).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '例: 100pt獲得 → ${(100 * evMultiplier).round()}pt に増量',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFB300),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExchangeButton() {
    final currentPoints = _pointsStats!['currentPoints'] ?? 0;
    final canExchange = currentPoints >= 5000;
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (canExchange && !_isExchanging) ? _exchangeForFuelCoupon : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canExchange ? const Color(0xFFFFB300) : Colors.grey[300],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: canExchange ? 4 : 0,
        ),
        child: _isExchanging
            ? const CircularProgressIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_gas_station),
                  const SizedBox(width: 8),
                  Text(
                    canExchange 
                        ? '給油券と交換 (5000pt)'
                        : '給油券と交換 (5000pt必要)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHistorySection() {
    final recentTransactions = _pointsStats!['recentTransactions'] as List? ?? [];
    
    if (recentTransactions.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.history, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'まだ履歴がありません',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '最近の履歴',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...recentTransactions.take(5).map((transaction) {
              final amount = transaction['amount'] ?? 0;
              final description = transaction['description'] ?? '';
              final type = transaction['type'] ?? '';
              final timestamp = DateTime.tryParse(transaction['timestamp'] ?? '') ?? DateTime.now();
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: amount > 0 ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            description,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${timestamp.month}/${timestamp.day} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${amount > 0 ? '+' : ''}${amount}pt',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: amount > 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Color _parseRankColor(String? colorString) {
    const fallbackColor = Color(0xFFCD7F32);

    if (colorString == null || colorString.isEmpty) {
      return fallbackColor;
    }

    final sanitized = colorString
        .trim()
        .replaceFirst('#', '')
        .replaceFirst(RegExp(r'^0x', caseSensitive: false), '');
    final hex = sanitized.length == 6 ? 'FF$sanitized' : sanitized;

    try {
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return fallbackColor;
    }
  }
}
