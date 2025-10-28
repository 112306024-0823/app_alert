# API 整合說明

## 📋 概述

此文件說明 Flutter App 如何與 C# 後端 API 整合。**API 呼叫邏輯應該寫在前端（Flutter App）**，使用 `ApiService` 類別統一管理。

## 🏗️ 架構說明

### 前後端分離架構

```
┌─────────────────┐         HTTP/JSON         ┌──────────────┐
│  Flutter App    │ ────────────────────────► │   C# API     │
│   (前端)        │                            │   (後端)     │
│                 │ ◄──────────────────────── │              │
│  ApiService     │         Response          │   Database   │
└─────────────────┘                            └──────────────┘
```

- **前端（Flutter）**：負責 UI 展示和使用者互動
- **後端（C# API）**：負責業務邏輯和資料庫操作
- **ApiService**：前端統一管理 API 呼叫的服務類別

## 📡 API 端點列表

所有 API 定義在 `lib/services/api_service.dart` 中：

### 階段一：裝置註冊

```dart
// POST /api/device/register
ApiService.registerDevice(token: "fcm_token_here")
```

**用途**：App 安裝後或更換手機時，註冊 FCM Token 到後端

**Request Body**:
```json
{
  "token": "c3po...R2D2"
}
```

### 階段二：批次設定

```dart
// POST /api/batch/create
ApiService.createBatch(
  name: "2025-10-23 早班",
  start: "10000",
  end: "19999",
)
```

**用途**：操作員建立新的批次規則

**Request Body**:
```json
{
  "name": "2025-10-23 早班",
  "start": "10000",
  "end": "19999"
}
```

### 階段四：查詢紀錄

```dart
// GET /api/log/success - 成功紀錄
ApiService.getSuccessLogs()

// GET /api/log/alerts - 錯誤紀錄
ApiService.getAlertLogs()
```

**用途**：在 Used Codes 畫面查詢掃描紀錄

## 🔧 使用方式

### 在 Flutter 畫面中呼叫 API

```dart
import '../services/api_service.dart';

// 載入資料
Future<void> _loadData() async {
  try {
    // 呼叫 API
    final successLogs = await ApiService.getSuccessLogs();
    final alertLogs = await ApiService.getAlertLogs();
    
    // 處理回應資料
    // ...
  } catch (e) {
    // 錯誤處理
    print('錯誤：$e');
  }
}
```

### 設定 API Base URL

編輯 `lib/services/api_service.dart`:

```dart
static const String baseUrl = 'http://your-actual-api-url.com/api';
```

## 📱 實際整合範例

### Used Codes Screen（階段四）

在 `lib/screens/used_codes_screen.dart` 中：

1. **載入資料**：`_loadData()` 方法會呼叫 API
2. **並行請求**：同時取得成功和錯誤紀錄
3. **資料轉換**：將 API 回應轉換為 `CodeRecord` 和 `AlertRecord`
4. **UI 更新**：顯示在畫面上

### Batch Settings Screen（階段二）

在 `lib/screens/batch_settings_screen.dart` 中：

1. **建立批次**：`_handleCreateBatch()` 方法會呼叫 API
2. **API 呼叫**：`ApiService.createBatch()`
3. **成功處理**：更新本地狀態並顯示成功訊息
4. **錯誤處理**：顯示錯誤訊息給使用者

## ⚠️ 注意事項

### API 在前端還是後端？

**答案：API 呼叫邏輯寫在前端（Flutter App）**

- ✅ **前端**：API 呼叫、資料處理、錯誤處理
- ✅ **後端**：業務邏輯、資料庫操作、API 回應

### 完整的資料流程

1. **使用者操作** → Flutter UI
2. **觸發 API 呼叫** → `ApiService.xxx()`
3. **發送 HTTP 請求** → C# API
4. **處理業務邏輯** → C# Backend
5. **資料庫操作** → SQL Server
6. **回傳 JSON** → C# API → Flutter App
7. **更新 UI** → Flutter UI

## 🚀 下一步

待 C# API 完成後：

1. **設定 Base URL**：更新 `ApiService.baseUrl`
2. **測試連線**：使用 `ApiService.testConnection()`
3. **測試各 API**：確保所有端點正常運作
4. **錯誤處理**：根據實際 API 回應調整錯誤處理邏輯

