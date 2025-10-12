import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/app_models.dart';

class FaqPage extends ConsumerStatefulWidget {
  const FaqPage({super.key});

  @override
  ConsumerState<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends ConsumerState<FaqPage> {
  List<FaqItem> _faqItems = [];
  bool _isLoading = true;
  final Set<String> _expandedItems = {};

  @override
  void initState() {
    super.initState();
    _loadFaqItems();
  }

  Future<void> _loadFaqItems() async {
    // TODO: WordPress APIからFAQ情報を取得
    // 現在はダミーデータを使用
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _faqItems = [
        FaqItem(
          id: '1',
          question: '予約はどのように行えばよいですか？',
          answer: 'お電話またはWebサイトからご予約いただけます。お急ぎの場合はお電話でのご予約をおすすめします。',
          answerHtml: 'お電話またはWebサイトからご予約いただけます。お急ぎの場合はお電話でのご予約をおすすめします。',
          order: 1,
          createdAt: DateTime.now(),
        ),
        FaqItem(
          id: '2',
          question: '作業時間はどのくらいかかりますか？',
          answer: 'サービス内容により異なりますが、一般的なクリーニングで2-3時間、コーティングで3-4時間程度です。',
          answerHtml: 'サービス内容により異なりますが、一般的なクリーニングで2-3時間、コーティングで3-4時間程度です。',
          order: 2,
          createdAt: DateTime.now(),
        ),
        FaqItem(
          id: '3',
          question: '料金の支払い方法は？',
          answer: '現金、クレジットカード、電子マネーでのお支払いが可能です。',
          answerHtml: '現金、クレジットカード、電子マネーでのお支払いが可能です。',
          order: 3,
          createdAt: DateTime.now(),
        ),
        FaqItem(
          id: '4',
          question: 'キャンセルはできますか？',
          answer: '前日までにご連絡いただければキャンセル可能です。当日キャンセルの場合はキャンセル料が発生する場合があります。',
          answerHtml: '前日までにご連絡いただければキャンセル可能です。当日キャンセルの場合はキャンセル料が発生する場合があります。',
          order: 4,
          createdAt: DateTime.now(),
        ),
        FaqItem(
          id: '5',
          question: '駐車場はありますか？',
          answer: '店舗前に専用駐車場をご用意しております。満車の場合は近隣のコインパーキングをご利用ください。',
          answerHtml: '店舗前に専用駐車場をご用意しております。満車の場合は近隣のコインパーキングをご利用ください。',
          order: 5,
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
          'よくある質問',
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
              onRefresh: _loadFaqItems,
              child: _faqItems.isEmpty
                  ? const Center(
                      child: Text(
                        'FAQが見つかりませんでした',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _faqItems.length,
                      itemBuilder: (context, index) {
                        final faqItem = _faqItems[index];
                        return _buildFaqCard(faqItem);
                      },
                    ),
            ),
    );
  }

  Widget _buildFaqCard(FaqItem faqItem) {
    final isExpanded = _expandedItems.contains(faqItem.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ExpansionTile(
          title: Text(
            faqItem.question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.help_outline,
              color: Color(0xFF3B82F6),
              size: 20,
            ),
          ),
          trailing: AnimatedRotation(
            turns: isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF6B7280),
            ),
          ),
          onExpansionChanged: (expanded) {
            setState(() {
              if (expanded) {
                _expandedItems.add(faqItem.id);
              } else {
                _expandedItems.remove(faqItem.id);
              }
            });
          },
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    faqItem.answer,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4B5563),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
