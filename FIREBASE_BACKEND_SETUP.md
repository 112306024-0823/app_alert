# Firebase 後端設定指南（C# API）

## 📋 概述

此文件說明如何在 C# 後端使用 Firebase 服務帳戶憑證發送推送通知給 Flutter 應用程式。

## 🔑 服務帳戶憑證

您提供的服務帳戶憑證資訊：
- **專案 ID**：`barcodevalidatorapp`
- **服務帳戶 Email**：`firebase-adminsdk-fbsvc@barcodevalidatorapp.iam.gserviceaccount.com`
- **憑證 ID**：`3f21957112aed16adaed6c7aa7b7a554c46f52ce`

## 🔧 後端設定步驟

### 1. 安裝 Firebase Admin SDK

在 C# 專案中安裝 NuGet 套件：

```bash
Install-Package FirebaseAdmin
```

或使用 .NET CLI：

```bash
dotnet add package FirebaseAdmin
```

### 2. 初始化 Firebase Admin SDK

#### 方法一：使用服務帳戶 JSON 檔案（推薦）

1. 將服務帳戶憑證保存為 JSON 檔案（例如：`firebase-service-account.json`）
2. 在 `Program.cs` 或 `Startup.cs` 中初始化：

```csharp
using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using System.IO;

// 在 Program.cs 或 Startup.cs 中
public void ConfigureServices(IServiceCollection services)
{
    // 初始化 Firebase Admin SDK
    var pathToServiceAccount = Path.Combine(
        Directory.GetCurrentDirectory(),
        "firebase-service-account.json"
    );
    
    if (File.Exists(pathToServiceAccount))
    {
        FirebaseApp.Create(new AppOptions()
        {
            Credential = GoogleCredential.FromFile(pathToServiceAccount)
        });
    }
    
    // 其他服務設定...
}
```

#### 方法二：使用環境變數（更安全）

將服務帳戶 JSON 內容儲存在環境變數中：

```csharp
using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;

// 從環境變數讀取
var firebaseServiceAccountJson = Environment.GetEnvironmentVariable("FIREBASE_SERVICE_ACCOUNT_JSON");
if (!string.IsNullOrEmpty(firebaseServiceAccountJson))
{
    FirebaseApp.Create(new AppOptions()
    {
        Credential = GoogleCredential.FromJson(firebaseServiceAccountJson)
    });
}
```

#### 方法三：直接使用憑證（不推薦，僅用於測試）

```csharp
using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;

var serviceAccount = new
{
    type = "service_account",
    project_id = "barcodevalidatorapp",
    private_key_id = "3f21957112aed16adaed6c7aa7b7a554c46f52ce",
    private_key = "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDaGvvr+f0bla96...\n-----END PRIVATE KEY-----\n",
    client_email = "firebase-adminsdk-fbsvc@barcodevalidatorapp.iam.gserviceaccount.com",
    // ... 其他欄位
};

FirebaseApp.Create(new AppOptions()
{
    Credential = GoogleCredential.FromJson(JsonSerializer.Serialize(serviceAccount))
});
```

### 3. 建立 FCM 服務類別

創建一個服務類別來處理推送通知：

```csharp
using FirebaseAdmin.Messaging;
using System.Collections.Generic;
using System.Threading.Tasks;

public class FcmService
{
    /// <summary>
    /// 發送推送通知到單一裝置
    /// </summary>
    /// <param name="fcmToken">裝置的 FCM Token</param>
    /// <param name="title">通知標題</param>
    /// <param name="body">通知內容</param>
    /// <param name="data">額外的資料（選填）</param>
    public static async Task<string> SendNotificationAsync(
        string fcmToken,
        string title,
        string body,
        Dictionary<string, string>? data = null)
    {
        var message = new Message
        {
            Token = fcmToken,
            Notification = new Notification
            {
                Title = title,
                Body = body
            },
            Data = data ?? new Dictionary<string, string>(),
            Android = new AndroidConfig
            {
                Priority = Priority.High,
                Notification = new AndroidNotification
                {
                    Sound = "default",
                    ChannelId = "high_importance_channel"
                }
            },
            Apns = new ApnsConfig
            {
                Aps = new Aps
                {
                    Sound = "default",
                    Badge = 1
                }
            }
        };

        try
        {
            var response = await FirebaseMessaging.DefaultInstance.SendAsync(message);
            return $"成功發送通知: {response}";
        }
        catch (Exception ex)
        {
            throw new Exception($"發送通知失敗: {ex.Message}", ex);
        }
    }

    /// <summary>
    /// 發送掃描成功通知
    /// </summary>
    public static async Task SendScanSuccessNotificationAsync(
        string fcmToken,
        string code)
    {
        var data = new Dictionary<string, string>
        {
            { "type", "scan_success" },
            { "code", code },
            { "timestamp", DateTime.UtcNow.ToString("o") }
        };

        await SendNotificationAsync(
            fcmToken,
            "掃描成功",
            $"代碼 {code} 已成功掃描",
            data
        );
    }

    /// <summary>
    /// 發送掃描錯誤通知
    /// </summary>
    public static async Task SendScanErrorNotificationAsync(
        string fcmToken,
        string code,
        string errorType)
    {
        var data = new Dictionary<string, string>
        {
            { "type", "scan_error" },
            { "code", code },
            { "error_type", errorType },
            { "timestamp", DateTime.UtcNow.ToString("o") }
        };

        var title = errorType switch
        {
            "OutOfRange" => "代碼超出範圍",
            "Duplicate" => "重複掃描",
            "Invalid" => "無效代碼",
            _ => "掃描錯誤"
        };

        await SendNotificationAsync(
            fcmToken,
            title,
            $"代碼 {code}: {errorType}",
            data
        );
    }

    /// <summary>
    /// 批次發送通知到多個裝置
    /// </summary>
    public static async Task<BatchResponse> SendNotificationToMultipleDevicesAsync(
        List<string> fcmTokens,
        string title,
        string body,
        Dictionary<string, string>? data = null)
    {
        var messages = fcmTokens.Select(token => new Message
        {
            Token = token,
            Notification = new Notification
            {
                Title = title,
                Body = body
            },
            Data = data ?? new Dictionary<string, string>()
        }).ToList();

        try
        {
            var response = await FirebaseMessaging.DefaultInstance.SendAllAsync(messages);
            return response;
        }
        catch (Exception ex)
        {
            throw new Exception($"批次發送通知失敗: {ex.Message}", ex);
        }
    }
}
```

### 4. 在 API Controller 中使用

```csharp
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;

[ApiController]
[Route("api/[controller]")]
public class NotificationController : ControllerBase
{
    /// <summary>
    /// 發送測試通知
    /// </summary>
    [HttpPost("send-test")]
    public async Task<IActionResult> SendTestNotification([FromBody] SendNotificationRequest request)
    {
        try
        {
            var result = await FcmService.SendNotificationAsync(
                request.FcmToken,
                request.Title,
                request.Body,
                request.Data
            );
            
            return Ok(new { success = true, message = result });
        }
        catch (Exception ex)
        {
            return BadRequest(new { success = false, message = ex.Message });
        }
    }

    /// <summary>
    /// 發送掃描成功通知
    /// </summary>
    [HttpPost("scan-success")]
    public async Task<IActionResult> SendScanSuccessNotification(
        [FromBody] ScanNotificationRequest request)
    {
        try
        {
            // 從資料庫取得 FCM Token
            var fcmToken = await GetFcmTokenFromDatabaseAsync(request.DeviceId);
            
            if (string.IsNullOrEmpty(fcmToken))
            {
                return BadRequest(new { success = false, message = "找不到裝置的 FCM Token" });
            }

            await FcmService.SendScanSuccessNotificationAsync(fcmToken, request.Code);
            
            return Ok(new { success = true });
        }
        catch (Exception ex)
        {
            return BadRequest(new { success = false, message = ex.Message });
        }
    }

    private async Task<string?> GetFcmTokenFromDatabaseAsync(string deviceId)
    {
        // 從資料庫查詢 FCM Token 的邏輯
        // 假設您有一個 Devices 表儲存 FCM Token
        // return await _dbContext.Devices
        //     .Where(d => d.DeviceId == deviceId)
        //     .Select(d => d.FcmToken)
        //     .FirstOrDefaultAsync();
        
        return null; // 實作您的資料庫查詢邏輯
    }
}

public class SendNotificationRequest
{
    public string FcmToken { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    public Dictionary<string, string>? Data { get; set; }
}

public class ScanNotificationRequest
{
    public string DeviceId { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
}
```

### 5. 整合到掃描驗證流程

在您的掃描驗證 API 中，當驗證完成後發送通知：

```csharp
[HttpPost("scan/validate")]
public async Task<IActionResult> ValidateScan([FromBody] ScanRequest request)
{
    // 驗證邏輯...
    var validationResult = await ValidateCodeAsync(request.Code);
    
    // 取得裝置的 FCM Token
    var fcmToken = await GetFcmTokenFromDatabaseAsync(request.DeviceId);
    
    if (!string.IsNullOrEmpty(fcmToken))
    {
        if (validationResult.IsValid)
        {
            // 發送成功通知
            await FcmService.SendScanSuccessNotificationAsync(fcmToken, request.Code);
        }
        else
        {
            // 發送錯誤通知
            await FcmService.SendScanErrorNotificationAsync(
                fcmToken,
                request.Code,
                validationResult.ErrorType
            );
        }
    }
    
    return Ok(validationResult);
}
```

## 🔒 安全性建議

### 1. 保護服務帳戶憑證

- ⚠️ **不要**將 `firebase-service-account.json` 提交到 Git
- ✅ 使用環境變數或 Azure Key Vault 儲存憑證
- ✅ 在 `.gitignore` 中添加：

```
firebase-service-account.json
*.json
!appsettings.json
```

### 2. 權限控制

- 確保只有授權的 API 端點可以發送通知
- 驗證 FCM Token 的有效性
- 記錄所有通知發送記錄

## 📝 資料庫設計建議

建議在資料庫中儲存 FCM Token：

```sql
CREATE TABLE Devices (
    DeviceId NVARCHAR(100) PRIMARY KEY,
    FcmToken NVARCHAR(500) NOT NULL,
    RegisteredAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    LastActiveAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    IsActive BIT NOT NULL DEFAULT 1
);

CREATE INDEX IX_Devices_FcmToken ON Devices(FcmToken);
CREATE INDEX IX_Devices_IsActive ON Devices(IsActive);
```

## 🧪 測試

### 1. 測試單一通知

使用 Postman 或 Swagger 測試：

```http
POST /api/Notification/send-test
Content-Type: application/json

{
  "fcmToken": "<從 Flutter App Log 中取得的 FCM Token>",
  "title": "測試通知",
  "body": "這是一個測試通知",
  "data": {
    "type": "test",
    "timestamp": "2025-01-20T10:00:00Z"
  }
}
```

### 2. 檢查通知狀態

Firebase Admin SDK 會返回通知 ID，您可以用它來追蹤通知狀態。

## 📚 參考資源

- [Firebase Admin .NET SDK 文件](https://firebase.google.com/docs/admin/setup)
- [Firebase Cloud Messaging 文件](https://firebase.google.com/docs/cloud-messaging)
- [FirebaseAdmin NuGet 套件](https://www.nuget.org/packages/FirebaseAdmin)

## ✅ 檢查清單

- [ ] 已安裝 `FirebaseAdmin` NuGet 套件
- [ ] 已初始化 Firebase Admin SDK
- [ ] 已創建 `FcmService` 類別
- [ ] 已在 API Controller 中整合通知功能
- [ ] 已設定資料庫儲存 FCM Token
- [ ] 已測試發送通知功能
- [ ] 已將服務帳戶憑證加入 `.gitignore`

