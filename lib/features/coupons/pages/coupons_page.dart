// クーポン画面
import 'package:flutter/material.dart';
import '../../../core/models/coupon_model.dart';
import '../../../core/services/coupon_store.dart';

class CouponsPage extends StatefulWidget {
  const CouponsPage({super.key});

  @override
  State<CouponsPage> createState() => _CouponsPageState();
}

class _CouponsPageState extends State<CouponsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<CouponModel> _availableCoupons = [];
  List<CouponModel> _redeemedCoupons = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCoupons();
    _initializeDefaultCoupons();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeDefaultCoupons() async {
    await CouponStore.initializeDefaultCoupons();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    setState(() => _isLoading = true);
    
    try {
      final available = await CouponStore.getAvailableCoupons();
      final redeemed = await CouponStore.getRedeemedCoupons();
      
      if (mounted) {
        setState(() {
          _availableCoupons = available;
          _redeemedCoupons = redeemed;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('クーポン情報の読み込みに失敗しました');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleCouponRedeem(String couponId) async {
    try {
      final success = await CouponStore.toggleRedeem(couponId);
      
      if (success) {
        await _loadCoupons();
        if (mounted) {
          _showSuccessSnackBar('クーポンの状態を更新しました');
        }
      } else {
        if (mounted) {
          _showErrorSnackBar('更新に失敗しました');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('エラーが発生しました');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
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
        title: const Text('クーポン'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFB300),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.card_giftcard),
                  const SizedBox(width: 4),
                  Text('使用可能 (${_availableCoupons.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle),
                  const SizedBox(width: 4),
                  Text('使用済み (${_redeemedCoupons.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAvailableCouponsTab(),
                _buildRedeemedCouponsTab(),
              ],
            ),
    );
  }

  Widget _buildAvailableCouponsTab() {
    if (_availableCoupons.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_giftcard_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '使用可能なクーポンがありません',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'ポイントを貯めてクーポンと交換しましょう！',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCoupons,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _availableCoupons.length,
        itemBuilder: (context, index) {
          return _buildCouponCard(_availableCoupons[index], isAvailable: true);
        },
      ),
    );
  }

  Widget _buildRedeemedCouponsTab() {
    if (_redeemedCoupons.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '使用済みクーポンがありません',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCoupons,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _redeemedCoupons.length,
        itemBuilder: (context, index) {
          return _buildCouponCard(_redeemedCoupons[index], isAvailable: false);
        },
      ),
    );
  }

  Widget _buildCouponCard(CouponModel coupon, {required bool isAvailable}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: isAvailable ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isAvailable
                ? const LinearGradient(
                    colors: [Color(0xFFFFB300), Color(0xFFFFC107)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isAvailable ? null : Colors.grey[100],
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
                        color: isAvailable 
                            ? Colors.white.withOpacity(0.2)
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.local_gas_station,
                        color: isAvailable ? Colors.white : Colors.grey[600],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            coupon.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isAvailable ? Colors.white : Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            coupon.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: isAvailable ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isAvailable)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${coupon.cost}pt',
                          style: const TextStyle(
                            color: Color(0xFFFFB300),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '使用済み',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAvailable ? '発行日' : '使用日',
                            style: TextStyle(
                              fontSize: 12,
                              color: isAvailable ? Colors.white70 : Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isAvailable 
                                ? coupon.displayIssuedDate
                                : coupon.displayRedeemedDate,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isAvailable ? Colors.white : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isAvailable)
                      ElevatedButton(
                        onPressed: () => _showUseConfirmDialog(coupon),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFFFB300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '使用する',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: () => _toggleCouponRedeem(coupon.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[400],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '元に戻す',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUseConfirmDialog(CouponModel coupon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('クーポンを使用しますか？'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${coupon.title}を使用済みにします。'),
            const SizedBox(height: 8),
            Text(
              coupon.description,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            const Text(
              '※一度使用済みにすると、元に戻すことができます。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _toggleCouponRedeem(coupon.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB300),
              foregroundColor: Colors.white,
            ),
            child: const Text('使用する'),
          ),
        ],
      ),
    );
  }
}
