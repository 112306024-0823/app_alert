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
static const String baseUrl = 'http://192.168.4.54/BarcodeValidatorApi';
```

### 在實體手機上測試

#### Android 手機設定

1. **啟用開發者選項**
   - 進入「設定」→「關於手機」
   - 連續點擊「版本號碼」7 次，直到出現「您已成為開發人員」

2. **啟用 USB 偵錯**
   - 進入「設定」→「開發人員選項」
   - 開啟「USB 偵錯」
   - 開啟「USB 安裝」（選項）

3. **連接手機**
   - 使用 USB 線連接手機和電腦
   - 手機上會出現「允許 USB 偵錯？」提示，選擇「允許」
   - 勾選「一律允許這部電腦」

4. **確認連接**
   ```bash
   flutter devices
   ```
   應該會看到你的手機裝置（例如：`sdk gphone64 arm64`）

5. **執行應用程式**
   ```bash
   flutter run
   ```
   或指定裝置：
   ```bash
   flutter run -d <device_id>
   ```

#### iOS 手機設定（需 macOS）

1. **連接 iPhone**
   - 使用 USB 線連接 iPhone 和 Mac
   - 在 iPhone 上點擊「信任這部電腦」

2. **確認連接**
   ```bash
   flutter devices
   ```

3. **執行應用程式**
   ```bash
   flutter run
   ```

#### 網路設定（重要）

由於 API Base URL 是 `http://192.168.4.54`，需要確保：

1. **手機和電腦在同一區域網路**
   - 手機和電腦必須連接到同一個 Wi-Fi
   - 確保手機可以訪問 `192.168.4.54`

2. **測試網路連線**
   - 在手機瀏覽器開啟 `http://192.168.4.54/BarcodeValidatorApi/swagger`
   - 如果能看到 Swagger 頁面，表示網路正常

3. **Android 權限設定**
   確認 `android/app/src/main/AndroidManifest.xml` 有網路權限（通常在 `<manifest>` 標籤內）：
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
   ```

4. **如果無法連線**
   - 檢查防火牆設定
   - 確認 API 伺服器允許來自手機 IP 的連線
   - 可以嘗試使用電腦的 IP 地址（而不是 192.168.4.54）

### 疑難排解

- **找不到裝置**：確認模擬器已啟動或實體裝置已連接並開啟 USB 偵錯
- **依賴安裝失敗**：執行 `flutter clean` 後重新 `flutter pub get`
- **建置錯誤**：檢查 `flutter doctor` 輸出，確認所有工具都已安裝
- **網路連線失敗**：確認手機和電腦在同一 Wi-Fi，手機可以訪問 API 伺服器
- **Android 連線失敗**：檢查 `AndroidManifest.xml` 是否有網路權限
- **API 請求失敗**：確認手機可以訪問 `192.168.4.54`，在手機瀏覽器測試 Swagger 網址

### 相關資源

- [Flutter 官方文件](https://docs.flutter.dev/)
- [Dart 語言指南](https://dart.dev/guides)
- [Flutter 範例程式碼](https://docs.flutter.dev/cookbook)
