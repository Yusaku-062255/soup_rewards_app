# iOS実機ビルドエラー - クイックフィックスガイド 🚀

## 🔴 エラー内容
```
Error: Browsing on the local area network for 金村優作のiPhone.
The device must be opted into Developer Mode to connect wirelessly. (code -27)
```

---

## ⚡ 5分で解決（3ステップ）

### ステップ1: 開発者モードをオン（iOS 16+のみ）

```
iPhoneで:
設定 → プライバシーとセキュリティ → 開発者モード → オン
→ 再起動 → 「オンにする」を選択
```

### ステップ2: デバイス接続と信頼

```
1. iPhoneをUSBケーブルでMacに接続
2. iPhoneのロックを解除
3. 「このコンピュータを信頼しますか？」→ 信頼
4. パスコード入力
```

### ステップ3: 認識確認とビルド

```bash
# デバイス認識確認
flutter devices

# ビルド実行
flutter run -d 00008140-000055483ABA801C
```

---

## 🎯 詳細な解決手順が必要な場合

**BUILD_ERROR_ANALYSIS.md** を参照してください。

---

## ✅ チェックリスト

ビルド前に以下を確認:

- [ ] iPhoneの開発者モードがオン（iOS 16+）
- [ ] iPhoneがロック解除されている
- [ ] USBケーブルで接続されている
- [ ] 「このコンピュータを信頼」が承認済み

---

## 🚨 それでもダメな場合

```bash
# Xcodeから直接ビルド
open ios/Runner.xcworkspace

# Xcodeで:
# 1. デバイスを選択（左上）
# 2. Product → Clean Build Folder (Shift+Cmd+K)
# 3. Product → Run (Cmd+R)
```

成功したらXcodeを閉じて `flutter run` を実行

---

## 📝 重要な注意

**コードの問題ではありません！**

- ✅ `flutter analyze` → No issues found!
- ✅ Dartコード → 問題なし
- ✅ Firebase設定 → 正常

問題は **デバイス接続と設定** だけです。

---

作成日: 2025年11月18日
