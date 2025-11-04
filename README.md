# flutter_application

A new Flutter project. Flutter Alert APP

## 如何運行 Flutter 專案

### 前置需求
- Flutter SDK 3.9.2 或以上
- Android Studio / Xcode（iOS）或 VS Code
- 已連接的實體裝置或模擬器

### 快速啟動步驟

#### 1. 檢查環境
```bash
flutter doctor
```
確認所有依賴都已正確安裝

#### 2. 安裝依賴套件
```bash
flutter pub get
```

#### 3. 查看可用裝置
```bash
flutter devices
```

#### 4. 運行應用程式

**方式一：命令列（推薦）**
```bash
# 直接運行（會自動選擇第一個可用裝置）
flutter run

# 或指定裝置
flutter run -d <device_id>
```

**方式二：VS Code**
- 按 `F5` 或點擊「Run > Start Debugging」
- 選擇目標裝置

**方式三：Android Studio**
- 點擊右上角「Run」按鈕（綠色播放圖示）
- 選擇目標裝置

### 熱重載功能

應用程式運行時，在終端可以：
- 按 `r`：快速重載（保留狀態）
- 按 `R`：完整重啟（重置狀態）
- 按 `q`：退出應用程式

### 常用指令

```bash
# 清理建置快取
flutter clean

# 重新安裝依賴
flutter pub get

# 分析程式碼
flutter analyze

# 建置 APK（Android）
flutter build apk

# 建置 iOS（需在 macOS）
flutter build ios

# 建置 Web
flutter build web
```

### 專案結構

```
lib/
├── config/          # 設定檔（API 配置等）
├── models/          # 資料模型
├── screens/         # 畫面頁面
├── services/        # API 服務
├── widgets/         # 共用組件
└── main.dart        # 應用程式進入點
```

### API 設定

編輯 `lib/config/api_config.dart` 設定後端 API Base URL：

```dart
static const String baseUrl = 'http://your-api-url.com';
```

    

### 相關資源

- [Flutter 官方文件](https://docs.flutter.dev/)
- [Dart 語言指南](https://dart.dev/guides)
- [Flutter 範例程式碼](https://docs.flutter.dev/cookbook)
