# Barcode Validator App

A Flutter application for managing batch rules and monitoring barcode scanning records with real-time push notifications.

## 📋 Overview

This application provides a comprehensive solution for barcode validation management, featuring:
- Batch rule creation and management
- Real-time scan record monitoring
- Push notifications via Firebase Cloud Messaging (FCM)
- Duplicate code detection
- Alert tracking system

## ✨ Key Features

### 1. Batch Settings
- **Create Batch Rules**: Define validation rules with start/end code ranges
- **Manage Active Batch**: Only one batch can be active at a time
- **Allow Duplicate Toggle**: Enable/disable duplicate code validation per batch
- **View Records**: Quick access to scan records for each batch
- **Edit Functionality**: Modify batch details (disabled if records exist)

### 2. Scan Records
- **Valid Codes Section**: View all successfully scanned codes with timestamps
- **Alert Records Section**: Monitor codes that triggered alerts (Out of Range, Duplicate)
- **Independent Scrolling**: Each section scrolls independently for better UX
- **Search Function**: Filter records by code
- **Pull-to-Refresh**: Refresh data with a simple pull gesture
- **Real-time Updates**: Automatic updates when new scans occur via FCM

### 3. Push Notifications
- **Instant Alerts**: Receive immediate notifications for scan events
- **Background Support**: Notifications work even when app is closed
- **Automatic Navigation**: Tap notification to jump directly to relevant records

## 🏗️ Technical Architecture

### Frontend (Flutter)
```
lib/
├── config/
│   └── api_config.dart          # API configuration
├── models/
│   └── batch.dart               # Batch data model
├── screens/
│   ├── batch_settings_screen.dart   # Batch management UI
│   └── used_codes_screen.dart       # Scan records UI
├── services/
│   ├── api_service.dart         # Backend API communication
│   └── fcm_service.dart         # Firebase Cloud Messaging
├── utils/
│   └── navigation_helper.dart   # Global navigation
├── widgets/
│   └── system_notification_banner.dart  # In-app notifications
├── firebase_msg.dart            # FCM message handlers
├── firebase_options.dart        # Firebase configuration
└── main.dart                    # App entry point
```

### Backend (C# API + SQL Server)
- **API Framework**: ASP.NET Core
- **Database**: SQL Server
- **Tables**: 
  - `VLD_BatchRules` - Batch rule definitions
  - `VLD_ScanLogs` - Scan records and validation results

### Communication Flow
```
Flutter App ←→ C# API ←→ SQL Server
     ↓
Firebase Cloud Messaging (FCM)
     ↓
Push Notifications
```

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: 3.9.2 or higher
- **Development Tools**: Android Studio / Xcode / VS Code
- **Backend API**: C# API running on `http://192.168.4.54/BarcodeValidatorApi`
- **Firebase Project**: Configured with FCM enabled

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd flutter_application
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Verify environment**
   ```bash
   flutter doctor
   ```

4. **Configure API endpoint**
   
   Edit `lib/config/api_config.dart`:
   ```dart
   static const String baseUrl = 'http://192.168.4.54/BarcodeValidatorApi';
   ```

5. **Set up Firebase** (see Firebase Setup section below)

### Running the App

**Method 1: Command Line (Recommended)**
```bash
# Run on default device
flutter run

# Run on specific device
flutter run -d <device_id>

# List available devices
flutter devices
```

**Method 2: VS Code**
- Press `F5` or click "Run > Start Debugging"
- Select target device

**Method 3: Android Studio**
- Click the "Run" button (green play icon)
- Select target device

### Hot Reload
While the app is running:
- Press `r`: Quick reload (preserve state)
- Press `R`: Full restart (reset state)
- Press `q`: Quit application

## 🔧 Configuration

### API Configuration

Location: `lib/config/api_config.dart`

```dart
class ApiConfig {
  // Development environment
  static const String baseUrl = 'http://192.168.4.54/BarcodeValidatorApi';
  
  // Production environment (update when deploying)
  // static const String baseUrl = 'https://your-domain.com/BarcodeValidatorApi';
  
  static const int timeoutSeconds = 30;
}
```

### API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/Batch/create` | POST | Create new batch rule |
| `/api/Batch/list` | GET | Get all batch rules |
| `/api/Batch/update/{ruleId}` | PUT | Update batch rule |
| `/api/Batch/update-partial/{ruleId}` | PATCH | Partial update (e.g., toggle allowDuplicate) |
| `/api/Batch/set-active` | POST | Set a batch as active |
| `/api/Batch/register` | POST | Register FCM token |
| `/api/Batch/success` | GET | Get success logs |
| `/api/Batch/alerts` | GET | Get alert logs |

**Test API connection:**
```
http://192.168.4.54/BarcodeValidatorApi/swagger
```

## 🔥 Firebase Setup

### 1. Download Configuration Files

**For Android:**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: `barcodevalidatorapp`
3. Navigate to Project Settings → Your apps → Android app
4. Download `google-services.json`
5. Place in: `android/app/google-services.json`

**For iOS (if needed):**
1. Navigate to Project Settings → Your apps → iOS app
2. Download `GoogleService-Info.plist`
3. Place in: `ios/Runner/GoogleService-Info.plist`

### 2. Verify Configuration

The following are already configured:
- ✅ `android/app/build.gradle.kts` - Google Services plugin applied
- ✅ `android/app/src/main/AndroidManifest.xml` - Notification permissions
- ✅ FCM service implementation in `lib/services/fcm_service.dart`

### 3. Test FCM

After running the app, check logs for:
```
FCM Token: <your-token>
FCM Token 已成功註冊到後端
```

## 📱 Testing on Physical Devices

### Android Setup

1. **Enable Developer Options**
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times
   - You should see "You are now a developer!"

2. **Enable USB Debugging**
   - Go to Settings → Developer Options
   - Enable "USB Debugging"
   - Enable "USB Installation" (optional)

3. **Connect Device**
   - Connect phone to computer via USB
   - Accept "Allow USB Debugging?" prompt on phone
   - Check "Always allow from this computer"

4. **Verify Connection**
   ```bash
   flutter devices
   ```
   You should see your device listed

5. **Run App**
   ```bash
   flutter run
   ```

### Network Configuration

**Important:** Since the API is at `http://192.168.4.54`, ensure:

1. **Same Network**: Phone and computer must be on the same Wi-Fi
2. **Test Connection**: Open `http://192.168.4.54/BarcodeValidatorApi/swagger` in phone browser
3. **Network Permissions**: Already configured in `AndroidManifest.xml`
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
   ```

## 💡 Usage Guide

### Creating a Batch

1. Open the app → **Batch Settings** tab
2. Tap the **+** button (top right)
3. Fill in the form:
   - **Batch Name**: e.g., "LCA1210"
   - **Start Number**: 5-digit code (e.g., "00001")
   - **End Number**: 5-digit code (e.g., "99999")
4. Tap **Create**
5. The new batch is automatically set as active

### Managing Batches

- **Current Batch**: Displays the active batch with:
  - Batch name and range
  - Printed count
  - Allow Duplicate toggle
  - View Records button
  - Edit button (only shown if no records exist)

- **All Batch**: Lists inactive batches
  - Tap "Set Active" to switch current batch
  - Each batch shows range and printed count

### Viewing Scan Records

1. Switch to **Scan Records** tab
2. View batch information at the top
3. **Valid Codes**: Green section showing successful scans
   - Scroll independently within this section
4. **Alert Records**: Red section showing failed scans
   - Scroll independently within this section
5. Use search bar to filter by code
6. Pull down to refresh data

### Understanding Notifications

- **Scan Success**: Green notification when code is valid
- **Out of Range**: Red notification when code is outside batch range
- **Duplicate Code**: Red notification when code was previously scanned (if duplicate check enabled)
- Tap notification to view details in app

## 🛠️ Common Commands

```bash
# Clean build cache
flutter clean

# Reinstall dependencies
flutter pub get

# Analyze code
flutter analyze

# Build APK (Android)
flutter build apk

# Build iOS (macOS only)
flutter build ios

# Build for Web
flutter build web
```

## 🐛 Troubleshooting

### Device Not Found
- **Solution**: Verify emulator is running or physical device is connected with USB debugging enabled

### Build Errors
- **Solution**: Run `flutter clean` then `flutter pub get`
- Check `flutter doctor` output for missing tools

### API Connection Failed
- **Solution**: 
  - Verify phone and computer are on same Wi-Fi
  - Test API access in phone browser: `http://192.168.4.54/BarcodeValidatorApi/swagger`
  - Check API server is running

### FCM Token Not Received
- **Solution**:
  - Verify `google-services.json` is in `android/app/`
  - Run `flutter clean` and rebuild
  - Check Firebase project configuration

### Notifications Not Received
- **Solution**:
  - Grant notification permissions (Android 13+)
  - Verify FCM token is registered in backend database
  - Test notification from Firebase Console

### Database Constraint Error
When clearing data, follow the correct order:
```sql
-- 1. Clear child table first
TRUNCATE TABLE VLD_ScanLogs;

-- 2. Then clear parent table
TRUNCATE TABLE VLD_BatchRules;
```

## 📚 Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Guide](https://dart.dev/guides)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Samples](https://docs.flutter.dev/cookbook)

## 📝 Notes

- Only one batch can be active at a time
- Batches with existing records cannot be edited (to maintain data integrity)
- All displayed text is in English for consistency
- FCM notifications work in foreground, background, and terminated states
- Pull-to-refresh is available on both Valid Codes and Alert Records sections

## 🔒 Security Notes

- Never commit `google-services.json` or `GoogleService-Info.plist` to public repositories
- Use environment variables for sensitive configuration in production
- Enable HTTPS for production API endpoints
- Implement proper authentication for API access

## 📄 License

[Your License Here]

## 👥 Contributors

[Your Team Information]

---

**Version**: 1.0.0  
**Last Updated**: 2025-11-20
