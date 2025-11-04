# 🔒 修復 Git 敏感資訊洩漏問題

## ⚠️ 問題說明

GitHub 偵測到您的 `android/app/google-services.json` 檔案包含了服務帳戶私鑰，這是不安全的。該檔案已被提交到 Git 歷史中，需要移除。

## 🔧 解決步驟

### 步驟 1：從 Git 歷史中移除敏感檔案

**警告**：這會重寫 Git 歷史，如果有其他人也在使用這個 repository，需要先協調。

```bash
# 方法一：使用 git filter-branch（適用於單一檔案）
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch android/app/google-services.json" \
  --prune-empty --tag-name-filter cat -- --all

# 方法二：使用 git filter-repo（更安全，需要先安裝）
# 安裝：pip install git-filter-repo
git filter-repo --path android/app/google-services.json --invert-paths
```

### 步驟 2：強制推送（⚠️ 謹慎使用）

```bash
# ⚠️ 警告：這會覆蓋遠端歷史，確保所有協作者都知道
git push origin --force --all
git push origin --force --tags
```

### 步驟 3：清理本地檔案

```bash
# 刪除本地檔案（如果還存在）
rm android/app/google-services.json

# 確認 .gitignore 已包含該檔案
# 應該已經有：/android/app/google-services.json
```

## 📝 正確的 google-services.json

### 什麼是正確的 google-services.json？

正確的 `google-services.json` 應該從 Firebase Console 下載，包含：
- `project_id`
- `project_number`
- `firebase_url`
- `client` 配置（不含 private_key）

**不應該包含**：
- `private_key` ❌
- `private_key_id` ❌
- `client_email`（服務帳戶）❌

### 如何下載正確的 google-services.json

1. 前往 [Firebase Console](https://console.firebase.google.com/)
2. 選擇專案：`barcodevalidatorapp`
3. 點擊專案設定（⚙️）→ **專案設定**
4. 在「您的應用程式」區塊，選擇 **Android 應用程式**
5. 如果還沒有，請新增：
   - **Android 套件名稱**：`com.example.flutter_application`
6. 下載 `google-services.json`
7. 將檔案放到：`android/app/google-services.json`

### 正確的 google-services.json 格式範例

```json
{
  "project_info": {
    "project_number": "123456789",
    "firebase_url": "https://barcodevalidatorapp.firebaseio.com",
    "project_id": "barcodevalidatorapp",
    "storage_bucket": "barcodevalidatorapp.appspot.com"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:123456789:android:abcdef",
        "android_client_info": {
          "package_name": "com.example.flutter_application"
        }
      },
      "oauth_client": [...],
      "api_key": [
        {
          "current_key": "AIzaSy..."
        }
      ],
      "services": {
        "appinvite_service": {
          "other_platform_oauth_client": [...]
        }
      }
    }
  ],
  "configuration_version": "1"
}
```

## 🔑 服務帳戶憑證的正確使用

**服務帳戶憑證應該用於後端（C# API）**，不是 Flutter 前端。

### 後端使用方式

1. 將服務帳戶憑證保存為：`firebase-service-account.json`（在後端專案中）
2. 在 C# 後端使用 Firebase Admin SDK 發送通知
3. **不要**將服務帳戶憑證提交到 Git

詳細說明請參考：`FIREBASE_BACKEND_SETUP.md`

## ✅ 檢查清單

- [ ] 已從 Git 歷史中移除 `google-services.json`
- [ ] 已強制推送更新後的歷史（如果適用）
- [ ] 已刪除本地包含私鑰的 `google-services.json`
- [ ] 已從 Firebase Console 下載正確的 `google-services.json`
- [ ] 確認 `.gitignore` 包含 `/android/app/google-services.json`
- [ ] 已將服務帳戶憑證移到後端專案（不在 Flutter 專案中）

## 🆘 如果無法強制推送

如果您的 repository 有保護規則，無法強制推送，可以：

1. **使用 GitHub 的允許機制**：
   - 訪問 GitHub 提供的連結來允許該 secret
   - 但這**不推薦**，因為會讓敏感資訊留在歷史中

2. **創建新的 commit 移除檔案**：
   ```bash
   git rm --cached android/app/google-services.json
   git commit -m "Remove sensitive google-services.json"
   git push
   ```
   - 這只能移除未來的檔案，歷史中仍然存在
   - 需要考慮撤銷或重新生成服務帳戶憑證

## 🔐 安全建議

1. **立即撤銷洩漏的服務帳戶憑證**：
   - 前往 [Google Cloud Console](https://console.cloud.google.com/)
   - IAM & Admin → Service Accounts
   - 找到 `firebase-adminsdk-fbsvc@barcodevalidatorapp.iam.gserviceaccount.com`
   - 刪除舊的 key，創建新的 key

2. **使用環境變數或秘密管理工具**：
   - Azure Key Vault
   - AWS Secrets Manager
   - GitHub Secrets（如果使用 CI/CD）

3. **定期審查 Git 歷史**：
   - 使用 `git-secrets` 或 `truffleHog` 掃描敏感資訊

