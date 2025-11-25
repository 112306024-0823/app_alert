# Barcode Validator App

條碼驗證管理應用程式，支援批次規則管理、即時掃描記錄監控及推送通知。

## 主要功能

### 批次設定 (Batch Settings)
- 建立和管理批次規則（定義代碼範圍）
- 設定當前啟用的批次（同時只能有一個）
- 允許重複掃描開關（可針對每個批次設定）
- 檢視每個批次的掃描記錄
- 編輯批次資訊（若批次已有記錄則無法編輯）

### 掃描記錄 (Scan Records)
- **有效代碼區塊**：顯示所有成功掃描的代碼
- **警示記錄區塊**：顯示觸發警報的代碼（超出範圍、重複掃描等）
- 兩個區塊各自獨立滑動
- 代碼搜尋功能
- 下拉更新資料
- FCM 即時自動更新

### 推送通知
- 掃描事件的即時通知
- 背景運作支援（App 關閉時也能收到通知）
- 點擊通知直接跳轉到相關記錄

## 注意事項

- 只能有一個批次處於啟用狀態
- 已有掃描記錄的批次無法編輯（維護資料完整性）
- 所有顯示文字皆為英文
- FCM 通知在前景、背景、關閉狀態下皆可運作
- 有效代碼和警示記錄兩個區塊各自獨立滑動

## 技術架構

```
Flutter App ←→ C# API ←→ SQL Server
     ↓
Firebase Cloud Messaging (FCM)
```

**資料表：**
- `VLD_BatchRules` - 批次規則定義
- `VLD_ScanLogs` - 掃描記錄與驗證結果

## 快速開始

### 環境需求
- Flutter SDK 3.9.2 或以上
- Android Studio / VS Code
- C# API 後端運行於 `http://192.168.4.54/BarcodeValidatorApi`
- Firebase 專案已設定 FCM

### 安裝步驟

1. **安裝依賴套件**
   ```bash
   flutter pub get
   ```

2. **檢查環境**
   ```bash
   flutter doctor
   ```

3. **設定 API 端點**
   
   編輯 `lib/config/api_config.dart`：
   ```dart
   static const String baseUrl = 'http://192.168.4.54/BarcodeValidatorApi';
   ```

4. **配置 Firebase**
   - 下載 `google-services.json`（Android）
   - 放置於 `android/app/google-services.json`

### 運行應用程式

```bash
# 直接運行
flutter run

# 查看可用裝置
flutter devices

# 指定裝置運行
flutter run -d <device_id>
```

### Hot Reload
- 按 `r`：快速重載
- 按 `R`：完整重啟
- 按 `q`：退出

## API 端點

| 端點 | 方法 | 說明 |
|------|------|------|
| `/api/Batch/create` | POST | 建立批次規則 |
| `/api/Batch/list` | GET | 取得批次清單 |
| `/api/Batch/update/{ruleId}` | PUT | 更新批次規則 |
| `/api/Batch/update-partial/{ruleId}` | PATCH | 部分更新（如切換重複檢查） |
| `/api/Batch/set-active` | POST | 設定啟用批次 |
| `/api/Batch/register` | POST | 註冊 FCM Token |
| `/api/Batch/success` | GET | 取得成功記錄 |
| `/api/Batch/alerts` | GET | 取得警示記錄 |

**測試 API：** `http://192.168.4.54/BarcodeValidatorApi/swagger`

## Firebase 設定

1. 前往 [Firebase Console](https://console.firebase.google.com/)
2. 選擇專案：`barcodevalidatorapp`
3. 下載 `google-services.json`（Android）或 `GoogleService-Info.plist`（iOS）
4. 放置於對應位置
5. 運行 App 後檢查 Log 是否有 FCM Token


### 網路設定
- 手機和電腦必須在同一 Wi-Fi 網路
- 測試連線：在手機瀏覽器開啟 `http://192.168.4.54/BarcodeValidatorApi/swagger`

## 常用指令

```bash
flutter clean          # 清理建置快取
flutter pub get        # 重新安裝依賴
flutter analyze        # 分析程式碼
flutter build apk      # 建置 Android APK
```

## 使用說明

### 建立批次
1. 開啟 App → **Batch Settings** 分頁
2. 點擊右上角 **+** 按鈕
3. 輸入批次名稱、起始編號（5 碼）、結束編號（5 碼）
4. 點擊 **Create**
5. 新批次會自動設為啟用狀態

### 查看記錄
1. 切換到 **Scan Records** 分頁
2. 上方顯示當前批次資訊
3. **有效代碼區塊**（綠色）：成功掃描的記錄
4. **警示記錄區塊**（紅色）：失敗或警告的記錄
5. 使用搜尋框過濾代碼
6. 下拉即可更新資料

## 專案結構

```
lib/
├── config/              # API 設定
├── models/              # 資料模型
├── screens/             # 畫面頁面
│   ├── batch_settings_screen.dart
│   └── used_codes_screen.dart
├── services/            # API 與 FCM 服務
├── utils/               # 工具函式
├── widgets/             # 共用元件
└── main.dart            # 應用程式進入點
```



## 相關資源

- [Flutter 官方文件](https://docs.flutter.dev/)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Dart 語言指南](https://dart.dev/guides)

---

**更新：** 2025-11-20
