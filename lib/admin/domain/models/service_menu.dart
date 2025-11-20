/// サービスメニュー定義
/// ポイント付与画面で使用するメニュー一覧
class ServiceMenu {
  final String id;
  final String name;
  final int points;

  const ServiceMenu({
    required this.id,
    required this.name,
    required this.points,
  });

  /// 利用可能なメニュー一覧
  static const List<ServiceMenu> availableMenus = [
    ServiceMenu(
      id: 'wash_light',
      name: '洗車ライト',
      points: 100,
    ),
    ServiceMenu(
      id: 'wash_premium',
      name: '洗車プレミアム',
      points: 200,
    ),
    ServiceMenu(
      id: 'coating_light',
      name: 'コーティングライト',
      points: 1000,
    ),
    ServiceMenu(
      id: 'coating_standard',
      name: 'コーティングスタンダード',
      points: 2000,
    ),
    ServiceMenu(
      id: 'coating_premium',
      name: 'コーティングプレミアム',
      points: 3000,
    ),
    ServiceMenu(
      id: 'ceramic_full',
      name: 'セラミックフル',
      points: 5000,
    ),
  ];

  /// IDからメニューを取得
  static ServiceMenu? getById(String id) {
    try {
      return availableMenus.firstWhere((menu) => menu.id == id);
    } catch (e) {
      return null;
    }
  }
}

