# Firebase Cloud Messaging (FCM) 設定指南

## 📋 概述

此文件說明如何為 Flutter 專案設定 Firebase Cloud Messaging (FCM)，以接收來自後端的推送通知。

## 🔧 前置需求

1. **Firebase 專案**：已建立 Firebase 專案（`barcodevalidatorapp`）
2. **服務帳戶金鑰**：已取得 Firebase 服務帳戶 JSON 憑證
3. **Flutter 環境**：已安裝 Flutter SDK 3.9.2+

## 📱 Android 設定步驟

### 1. 下載 `google-services.json`

1. 前往 [Firebase Console](https://console.firebase.google.com/)
2. 選擇專案：`barcodevalidatorapp`
3. 點擊專案設定（⚙️）→ **專案設定**
4. 在「您的應用程式」區塊，選擇 **Android 應用程式**
5. 如果還沒有 Android 應用程式，請點擊「新增應用程式」→ 選擇 Android
6. 輸入以下資訊：
   - **Android 套件名稱**：`com.example.flutter_application`
   - **應用程式暱稱**（選填）：`flutter_application`
7. 點擊「註冊應用程式」
8. 下載 `google-services.json` 檔案
9. 將 `google-services.json` 放到以下位置：
   ```
   android/app/google-services.json
   ```

### 2. 驗證 Gradle 設定

已自動配置：
- ✅ `android/settings.gradle.kts` - 已添加 Google Services 插件
- ✅ `android/app/build.gradle.kts` - 已應用 Google Services 插件

### 3. AndroidManifest.xml

已自動配置：
- ✅ 通知權限（`POST_NOTIFICATIONS`）
- ✅ FCM 服務設定
- ✅ 通知頻道設定

## 🍎 iOS 設定步驟（如果需要在 iOS 上測試）

### 1. 下載 `GoogleService-Info.plist`

1. 前往 [Firebase Console](https://console.firebase.google.com/)
2. 選擇專案：`barcodevalidatorapp`
3. 點擊專案設定（⚙️）→ **專案設定**
4. 在「您的應用程式」區塊，選擇 **iOS 應用程式**
5. 如果還沒有 iOS 應用程式，請點擊「新增應用程式」→ 選擇 iOS
6. 輸入以下資訊：
   - **iOS Bundle ID**：`com.example.flutterApplication`（需與 Xcode 專案一致）
   - **應用程式暱稱**（選填）：`flutter_application`
7. 點擊「註冊應用程式」
8. 下載 `GoogleService-Info.plist` 檔案
9. 將 `GoogleService-Info.plist` 放到以下位置：
   ```
   ios/Runner/GoogleService-Info.plist
   ```

### 2. 啟用 Push Notifications

1. 在 Xcode 中開啟專案
2. 選擇 **Runner** 目標
3. 前往 **Signing & Capabilities** 標籤
4. 點擊 **+ Capability**
5. 添加 **Push Notifications**

### 3. 設定 APNs 憑證

1. 在 Firebase Console 中，前往專案設定 → **Cloud Messaging**
2. 上傳 APNs 認證金鑰或憑證
3. 詳細步驟請參考 [Firebase 文件](https://firebase.google.com/docs/cloud-messaging/ios/certs)

## 🚀 測試 FCM

### 1. 安裝依賴

```bash
flutter pub get
```

### 2. 運行應用程式

```bash
flutter run
```

### 3. 檢查 FCM Token

應用程式啟動後，在終端機或 Logcat 中應該會看到：
```
FCM Token: <your-fcm-token>
FCM Token 已成功註冊到後端
```

### 4. 測試推送通知

#### 方法一：使用 Firebase Console

1. 前往 Firebase Console → **Cloud Messaging**
2. 點擊「發送測試訊息」
3. 輸入 FCM Token（從應用程式 Log 中取得）
4. 輸入通知標題和內容
5. 點擊「測試」

#### 方法二：使用後端 API

後端可以使用服務帳戶金鑰發送通知：

```csharp
// C# 範例（後端）
var message = new Message
{
    Token = fcmToken, // 從資料庫取得
    Notification = new Notification
    {
        Title = "掃描成功",
        Body = "代碼 1234 已成功掃描"
    },
    Data = new Dictionary<string, string>
    {
        { "type", "scan_success" },
        { "code", "1234" }
    }
};

await FirebaseMessaging.DefaultInstance.SendAsync(message);
```

## 📝 程式碼說明

### FCM 服務類別

位置：`lib/services/fcm_service.dart`

主要功能：
- ✅ 初始化 FCM 並取得 Token
- ✅ 自動註冊 Token 到後端 API
- ✅ 監聽 Token 更新
- ✅ 處理前景通知（App 開啟時）
- ✅ 處理背景通知（App 關閉時）
- ✅ 處理通知點擊事件

### 通知處理流程

```
收到通知
    ↓
App 在前景？ → 是 → FirebaseMessaging.onMessage
    ↓ 否                          ↓
App 由通知開啟？ → 是 → FirebaseMessaging.onMessageOpenedApp
    ↓ 否                          ↓
App 在背景？ → 是 → firebaseMessagingBackgroundHandler
```

### API 整合

FCM Token 會自動註冊到後端：

```dart
// lib/services/fcm_service.dart
await ApiService.registerDevice(token: token);
```

對應的後端 API：
```
POST /api/Batch/register
Body: { "fcmToken": "..." }
```

## 🔍 疑難排解

### 問題 1：無法取得 FCM Token

**可能原因：**
- `google-services.json` 檔案位置錯誤
- Google Services 插件未正確應用
- Firebase 專案設定錯誤

**解決方法：**
1. 確認 `google-services.json` 在 `android/app/` 目錄下
2. 執行 `flutter clean` 後重新建置
3. 檢查 AndroidManifest.xml 權限設定

### 問題 2：Token 註冊失敗

**可能原因：**
- 網路連線問題
- 後端 API 未啟動
- API Base URL 設定錯誤

**解決方法：**
1. 檢查 `lib/config/api_config.dart` 中的 Base URL
2. 確認後端 API 正在運行
3. 檢查網路連線

### 問題 3：收不到通知

**可能原因：**
- 通知權限未授予（Android 13+）
- FCM Token 未正確註冊到後端
- 後端發送通知時使用錯誤的 Token

**解決方法：**
1. 確認應用程式已授予通知權限
2. 檢查後端資料庫中的 FCM Token 是否正確
3. 使用 Firebase Console 測試發送通知

## 📚 參考資源

- [Firebase Cloud Messaging 官方文件](https://firebase.google.com/docs/cloud-messaging)
- [FlutterFire 文件](https://firebase.flutter.dev/)
- [firebase_messaging 套件](https://pub.dev/packages/firebase_messaging)

## ✅ 檢查清單

- [ ] 已下載 `google-services.json` 並放到 `android/app/`
- [ ] 已執行 `flutter pub get`
- [ ] 應用程式可以正常啟動
- [ ] 在 Log 中看到 FCM Token
- [ ] FCM Token 已成功註冊到後端
- [ ] 可以使用 Firebase Console 發送測試通知
- [ ] 應用程式可以接收到通知

