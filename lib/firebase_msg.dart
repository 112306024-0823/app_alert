import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../screens/used_codes_screen.dart';

// 背景訊息處理器（必須是頂層函數）
@pragma('vm:entry-point')
Future<void> handleBackgroundNotification(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('收到背景通知: ${message.notification?.title}');
  debugPrint('通知內容: ${message.notification?.body}');
}

class FirebaseMsg {
  final msgService = FirebaseMessaging.instance;

  Future<void> initFCM() async {
    try {
      // 請求通知權限（需要 await）
      final settings = await msgService.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        debugPrint('通知權限未授予');
        return;
      }

      // 取得 Token
      var token = await msgService.getToken();
      debugPrint('FCM Token: $token');

      // 註冊 Token 到後端 API
      if (token != null && token.isNotEmpty) {
        try {
          await ApiService.registerDevice(token: token);
          debugPrint('FCM Token 已成功註冊到後端');
        } catch (e) {
          debugPrint('FCM Token 註冊失敗: $e');
          // 即使註冊失敗，也繼續運行（可能是網路問題）
        }
      }

      // 監聽 Token 更新（當使用者重新安裝 App 或清除資料時）
      msgService.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token 已更新: $newToken');
        // 重新註冊到後端
        ApiService.registerDevice(token: newToken).catchError((error) {
          debugPrint('Token 更新註冊失敗: $error');
          return <String, dynamic>{};
        });
      });

      // 設定背景訊息處理器（只在非 Web 平台，Web 平台使用 Service Worker）
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(handleBackgroundNotification);
      }
      
      // 監聽前景訊息
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('收到前景通知: ${message.notification?.title}');
        debugPrint('通知內容: ${message.notification?.body}');
        debugPrint('通知資料: ${message.data}');
        
        // 當收到掃描相關通知時，觸發 UsedCodesScreen 刷新
        final result = message.data['result'];
        final type = message.data['type'];
        if (result != null || type != null) {
          // 觸發 UsedCodesScreen 自動刷新
          UsedCodesRefreshManager.triggerRefresh();
        }
ㄕ      });
    } catch (e) {
      debugPrint('FCM 初始化錯誤: $e');
      rethrow;
    }
  }
}