// ポイント履歴画面（履歴一覧・交換機能）
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../../../core/services/points_service.dart';
import '../../../core/services/points_store.dart';
import '../../../core/services/rank_service.dart';

class PointsHistoryPage extends StatefulWidget {
  final PointsState initialState;

  const PointsHistoryPage({
    super.key,
    required this.initialState,
  });

  @override
  State<PointsHistoryPage> createState() => _PointsHistoryPageState();
}

class _PointsHistoryPageState extends State<PointsHistoryPage> {
  late PointsState _currentState;
  bool _isLoading = false;

  // 交換メニュー定義
  static const Map<String, int> _exchangeMenu = {
    'Fuel Voucher': 5000,
  };

  @override
  void initState() {
    super.initState();
    _currentState = widget.initialState;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ポイント履歴'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            tooltip: 'データを更新',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 24),
                  _buildExchangeSection(),
                  const SizedBox(height: 24),
                  _buildHistorySection(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final rank = RankService.calculateRank(_currentState.totalEarned);
    final rankName = RankService.rankNames[rank] ?? 'Bronze';
    final progress = RankService.rankProgress(_currentState.totalEarned);
    final pointsToNext = RankService.pointsToNextRank(_currentState.totalEarned);
    final stats = PointsService.getStats(_currentState);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ポイント概要',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // 現在残高
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('現在残高', style: TextStyle(fontSize: 16)),
                Text(
                  '${_currentState.balance}pt',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFB300),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // 累計獲得
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('累計獲得', style: TextStyle(fontSize: 14)),
                Text('${_currentState.totalEarned}pt'),
              ],
            ),
            const SizedBox(height: 8),
            
            // 累計交換
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('累計交換', style: TextStyle(fontSize: 14)),
                Text('${stats['totalSpent']}pt'),
              ],
            ),
            const SizedBox(height: 16),
            
            // ランク情報
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('現在ランク: $rankName'),
                if (pointsToNext > 0)
                  Text('次まで: ${pointsToNext}pt'),
              ],
            ),
            
            // 進捗バー
            if (pointsToNext > 0) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFB300)),
              ),
            ] else
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '🎉 最高ランク達成！',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6F00),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExchangeSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '交換メニュー',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ..._exchangeMenu.entries.map((entry) => _buildExchangeItem(
              title: entry.key,
              cost: entry.value,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildExchangeItem({
    required String title,
    required int cost,
  }) {
    final canExchange = PointsService.canExchange(_currentState, cost);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: canExchange ? Colors.white : Colors.grey[50],
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_gas_station,
            color: canExchange ? const Color(0xFFFFB300) : Colors.grey,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: canExchange ? Colors.black : Colors.grey,
                  ),
                ),
                Text(
                  '${cost}pt で交換',
                  style: TextStyle(
                    fontSize: 14,
                    color: canExchange ? Colors.grey[600] : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: canExchange ? () => _showExchangeDialog(title, cost) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB300),
              foregroundColor: Colors.white,
            ),
            child: const Text('交換'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '取引履歴',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        if (_currentState.history.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text('まだ取引履歴がありません'),
              ),
            ),
          )
        else
          ..._currentState.history.map((entry) => _buildHistoryItem(entry)),
      ],
    );
  }

  Widget _buildHistoryItem(PointEntry entry) {
    final isEarned = entry.delta > 0;
    final color = isEarned ? Colors.teal : Colors.red;
    final prefix = isEarned ? '+' : '';
    final icon = isEarned ? Icons.add_circle : Icons.remove_circle;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(entry.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${entry.date.year}/${entry.date.month}/${entry.date.day} '
              '${entry.date.hour.toString().padLeft(2, '0')}:'
              '${entry.date.minute.toString().padLeft(2, '0')}',
            ),
            if (entry.note != null)
              Text(
                entry.note!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        trailing: Text(
          '$prefix${entry.delta}pt',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  void _showExchangeDialog(String title, int cost) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$title と交換'),
        content: Text(
          '${cost}pt を使用して $title と交換しますか？\n\n'
          '現在残高: ${_currentState.balance}pt\n'
          '交換後残高: ${_currentState.balance - cost}pt',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performExchange(title, cost);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB300),
              foregroundColor: Colors.white,
            ),
            child: const Text('交換する'),
          ),
        ],
      ),
    );
  }

  Future<void> _performExchange(String title, int cost) async {
    setState(() => _isLoading = true);

    try {
      final newState = PointsService.exchange(
        _currentState,
        cost: cost,
        title: '$title Exchange',
        note: 'Thank you for your exchange!',
      );

      if (newState != null) {
        await PointsStore.save(newState);
        setState(() => _currentState = newState);

        // 成功モーダル表示
        if (mounted) {
          _showSuccessModal(title, cost);
        }
      } else {
        // エラー処理（通常は発生しないはず）
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('交換に失敗しました。残高が不足している可能性があります。'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      developer.log('[SOUP] Exchange error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('交換中にエラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessModal(String title, int cost) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 8),
            Text('交換完了！'),
          ],
        ),
        content: Text(
          '$title と交換しました！\n\n'
          '使用ポイント: -${cost}pt\n'
          '現在残高: ${_currentState.balance}pt',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB300),
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);

    try {
      final refreshedState = await PointsStore.load();
      setState(() => _currentState = refreshedState);
    } catch (e) {
      developer.log('[SOUP] Refresh error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('データの更新に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
