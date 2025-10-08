/// SOUP Rewards アプリ定数
class AppConstants {
  AppConstants._();

  // アプリ情報
  static const String appName = 'SOUP Rewards';
  static const String appVersion = '1.0.0';
  static const String companyName = '株式会社SOUP';
  static const String companyUrl = 'https://soup.tokushima.jp/';

  // ブランドメッセージ
  static const String brandMessage = 'キレイな車は幸せを呼ぶ！';
  static const String brandDescription = '徳島発のカーケアブランド「SOUP」の公式アプリ';

  // API設定
  static const String baseUrl = 'https://api.soup.tokushima.jp/';
  static const String apiVersion = 'v1';
  static const Duration apiTimeout = Duration(seconds: 30);

  // ローカルストレージキー
  static const String userTokenKey = 'user_token';
  static const String userIdKey = 'user_id';
  static const String pointsKey = 'user_points';
  static const String settingsKey = 'app_settings';

  // ポイントシステム
  static const int pointsPerYen = 1; // 1円 = 1ポイント
  static const int minimumRedemption = 100; // 最小交換ポイント
  static const int maximumRedemption = 10000; // 最大交換ポイント

  // QRコード設定
  static const String qrCodePrefix = 'SOUP_';
  static const Duration qrScanTimeout = Duration(seconds: 10);

  // 通知設定
  static const String notificationChannelId = 'soup_rewards_channel';
  static const String notificationChannelName = 'SOUP Rewards通知';
  static const String notificationChannelDescription = 'クーポンやポイント情報をお知らせします';

  // 画像設定
  static const double maxImageSize = 5.0; // MB
  static const int imageQuality = 85; // 0-100
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1080;

  // アニメーション設定
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // レイアウト設定
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 8.0;

  // サポート情報
  static const String supportEmail = 'support@soup.tokushima.jp';
  static const String supportPhone = '088-123-4567';
  static const String privacyPolicyUrl = 'https://soup.tokushima.jp/privacy';
  static const String termsOfServiceUrl = 'https://soup.tokushima.jp/terms';

  // ソーシャルメディア
  static const String instagramUrl = 'https://instagram.com/soup_tokushima';
  static const String twitterUrl = 'https://twitter.com/soup_tokushima';
  static const String facebookUrl = 'https://facebook.com/soup.tokushima';

  // 店舗情報
  static const String mainStoreAddress = '徳島県徳島市○○町1-2-3';
  static const String mainStorePhone = '088-123-4567';
  static const String businessHours = '9:00-18:00（定休日：日曜日）';

  // エラーメッセージ
  static const String networkErrorMessage = 'ネットワークエラーが発生しました。インターネット接続を確認してください。';
  static const String serverErrorMessage = 'サーバーエラーが発生しました。しばらく時間をおいて再度お試しください。';
  static const String unknownErrorMessage = '予期しないエラーが発生しました。';
  static const String validationErrorMessage = '入力内容に誤りがあります。';

  // 成功メッセージ
  static const String pointsEarnedMessage = 'ポイントを獲得しました！';
  static const String pointsRedeemedMessage = 'ポイントを交換しました！';
  static const String profileUpdatedMessage = 'プロフィールを更新しました！';
  static const String couponAppliedMessage = 'クーポンを適用しました！';
}
