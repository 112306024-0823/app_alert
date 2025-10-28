# 批次建立功能說明

## 📋 功能概述

此功能允許操作員在開始新工作前建立批次規則，用於後續的代碼驗證。

## 🚀 使用流程

### 1. 操作員操作（Flutter App）

1. **開啟 App**：在 Flutter App 中開啟「設定」頁面（Batch Settings）
2. **輸入批次資訊**：
   - **批次名稱**：例如 "2025-10-23 早班"
   - **開始編號**：例如 "10000"
   - **結束編號**：例如 "19999"
3. **點擊 "Create" 按鈕**

### 2. Flutter App → C# API

- **API 端點**：`POST /api/batch/create`
- **Request Body**：
  ```json
  {
    "name": "2025-10-23 早班",
    "start": "10000",
    "end": "19999"
  }
  ```

### 3. C# API → Database

- 執行 SQL INSERT 到 `BatchRules` 資料表
- 設定 `IsActive=1`（啟用狀態）
- 儲存批次規則供 Python 腳本驗證使用

## 📁 檔案結構

```
lib/
├── models/
│   └── batch.dart              # 批次資料模型
├── screens/
│   └── batch_settings_screen.dart  # 批次設定畫面
├── services/
│   └── api_service.dart        # API 服務（待 C# API 完成後配置）
└── main.dart                    # 主程式入口
```

## 🔧 API 服務配置

### 設定 API Base URL

編輯 `lib/services/api_service.dart`：

```dart
static const String baseUrl = 'http://your-actual-api-url.com/api';
```

### API 規格

#### 建立批次

- **端點**：`POST /api/batch/create`
- **Request Body**：
  ```json
  {
    "name": "批次名稱",
    "start": "開始編號",
    "end": "結束編號"
  }
  ```
- **Response**：
  ```json
  {
    "id": "批次ID",
    "name": "批次名稱",
    "start": "開始編號",
    "end": "結束編號",
    "isActive": true
  }
  ```

## 💻 程式碼說明

### 批次建立對話框

位置：`lib/screens/batch_settings_screen.dart`

```dart
void _showCreateBatchDialog() {
  // 顯示建立批次對話框
  // 輸入：name, start, end
  // 點擊 Create 後呼叫 _handleCreateBatch()
}
```

### API 呼叫

位置：`lib/services/api_service.dart`

```dart
static Future<Map<String, dynamic>> createBatch({
  required String name,
  required String start,
  required String end,
}) async {
  // 發送 POST 請求到 /api/batch/create
  // 返回 API 回應
}
```

### 處理建立批次

位置：`lib/screens/batch_settings_screen.dart`

```dart
Future<void> _handleCreateBatch(...) async {
  // 1. 驗證輸入
  // 2. 呼叫 API
  // 3. 更新本地狀態
  // 4. 顯示成功訊息
}
```

## ⚠️ 待 C# API 完成後

1. **更新 API Base URL**：在 `api_service.dart` 中設定實際的 API URL
2. **測試連線**：使用 `ApiService.testConnection()` 測試 API 連線
3. **測試建立批次**：在 App 中實際建立一個批次測試

## 🎯 功能特色

- ✅ 直觀的 UI 設計（符合 Figma 設計稿）
- ✅ 完整的輸入驗證
- ✅ 載入狀態指示器
- ✅ 錯誤處理和錯誤訊息顯示
- ✅ 成功後自動更新 UI
- ✅ 預留 API 整合接口

## 📝 下一步

待 C# API 完成後，可以：
1. 更新 `ApiService.baseUrl` 為實際的 API URL
2. 測試完整的建立批次流程
3. 根據 API 回應調整資料模型

