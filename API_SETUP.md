# API 設定說明

## 🔧 已完成的配置

所有 API 設定已根據後端規格更新完成。

### 配置檔案位置

- **設定檔**：`lib/config/api_config.dart`
- **API 服務**：`lib/services/api_service.dart`

### API Base URL

```dart
// 開發環境（您目前的電腦）
static const String baseUrl = 'http://192.168.4.54/BarcodeValidatorApi';

// 正式環境（待部署後更新）
// static const String baseUrl = 'https://your-domain.com/BarcodeValidatorApi';
```

## 📡 API 端點對應

### 1. 建立批次

- **端點**：`POST /api/Batch/create`
- **完整 URL**：`http://192.168.4.54/BarcodeValidatorApi/api/batch/create`
- **Request Body**：
  ```json
  {
    "batchName": "2025-10A",
    "startCode": "1000",
    "endCode": "1999"
  }
  ```

### 2. 成功紀錄

- **端點**：`GET /api/log/success`
- **完整 URL**：`http://192.168.4.54/BarcodeValidatorApi/api/log/success`
- **Response**：
  ```json
  {
    "count": 1,
    "logs": [
      {
        "logId": 101,
        "scannedCode": "1234",
        "status": "Success",
        "timestamp": "2025-10-23T14:30:05Z"
      }
    ]
  }
  ```

### 3. 警示紀錄

- **端點**：`GET /api/log/alerts`
- **完整 URL**：`http://192.168.4.54/BarcodeValidatorApi/api/log/alerts`
- **Response**：
  ```json
  {
    "count": 2,
    "logs": [
      {
        "logId": 103,
        "scannedCode": "999",
        "alertType": "OutOfRange",
        "timestamp": "2025-10-23T14:32:10Z"
      }
    ]
  }
  ```

### 4. 裝置註冊

- **端點**：`POST /api/device/register`
- **完整 URL**：`http://192.168.4.54/BarcodeValidatorApi/api/device/register`
- **Request Body**：
  ```json
  {
    "fcmToken": "c3po...R2D2_firebase_device_token"
  }
  ```

## 🧪 測試 API

### Swagger UI

可以直接在瀏覽器測試 API：
- **Swagger URL**：`http://192.168.4.54/BarcodeValidatorApi/swagger`

### 在 Flutter 中測試

執行以下指令測試連線：

```bash
flutter run -d chrome
```

然後在 App 中：
1. 點擊「Batch Settings」
2. 點擊右上角 `+` 按鈕
3. 輸入批次資訊並點擊「Create」

## ⚠️ 注意事項

### 1. 網路連線

確保 Flutter App 可以連接到 `http://192.168.4.54`：
- 如果在實體手機上測試，確保手機和電腦在同一網域
- 如果使用 Web（Chrome），可能需要處理 CORS 問題

### 2. 欄位名稱

已根據 API 規格更新欄位名稱：
- 建立批次：`batchName`, `startCode`, `endCode`（不再是 `name`, `start`, `end`）
- Response 格式：`logs` 陣列（不再是直接返回陣列）
- 欄位名稱：camelCase 格式（`scannedCode`, `logId`, `alertType`）

### 3. 錯誤處理

所有 API 呼叫都包含：
- ✅ 超時設定（30秒）
- ✅ 錯誤訊息回傳
- ✅ 回應狀態碼檢查

## 🚀 接下來

1. **測試本地連線**
   - 確保後端 API 正在運行
   - 訪問 `http://192.168.4.54/BarcodeValidatorApi/swagger` 確認

2. **測試 Flutter App**
   - 建立一個批次測試
   - 查看成功和錯誤紀錄

3. **部署準備**
   - 當後端部署到正式環境時
   - 只需更新 `lib/config/api_config.dart` 中的 `baseUrl`

