import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

/// FCM 服務類別
/// 負責處理 Firebase Cloud Messaging 相關功能
class FcmService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  /// 初始化 FCM 服務
  /// 取得 FCM Token 並註冊到後端
  static Future<void> initialize() async {
    try {
      // 請求通知權限（iOS）
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      // 取得 FCM Token
      final token = await _firebaseMessaging.getToken();
      
      if (token != null) {
        debugPrint('FCM Token: $token');
        
        // 註冊 Token 到後端
        try {
          await ApiService.registerDevice(token: token);
          debugPrint('FCM Token 已成功註冊到後端');
        } catch (e) {
          debugPrint('FCM Token 註冊失敗: $e');
          // 即使註冊失敗，也繼續運行（可能是網路問題）
        }
      } else {
        debugPrint('無法取得 FCM Token');
      }
      
      // 監聽 Token 更新（當使用者重新安裝 App 或清除資料時）
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token 已更新: $newToken');
        // 重新註冊到後端
        ApiService.registerDevice(token: newToken).catchError((error) {
          debugPrint('Token 更新註冊失敗: $error');
          return <String, dynamic>{};
        });
      });
      
      // 設定通知處理器
      _setupMessageHandlers();
      
    } catch (e) {
      debugPrint('FCM 初始化失敗: $e');
    }
  }
  
  /// 設定通知處理器
  static void _setupMessageHandlers() {
    // 當 App 在前景時收到通知
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('收到前景通知: ${message.notification?.title}');
      debugPrint('通知內容: ${message.notification?.body}');
      debugPrint('通知資料: ${message.data}');
      
      // 可以在這裡顯示自訂通知 UI
      // 例如使用 SystemNotificationBanner
    });
    
    // 當使用者點擊通知開啟 App
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('使用者點擊通知開啟 App: ${message.notification?.title}');
      debugPrint('通知資料: ${message.data}');
      
      // 可以在這裡處理通知點擊後的導航邏輯
      // 例如：根據 message.data 跳轉到特定頁面
    });
    
    // 檢查 App 是否由通知開啟（App 在背景時點擊通知）
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App 由通知開啟: ${message.notification?.title}');
        debugPrint('通知資料: ${message.data}');
        
        // 處理導航邏輯
      }
    });
  }
  
  /// 取得當前 FCM Token
  static Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint('取得 FCM Token 失敗: $e');
      return null;
    }
  }
  
  /// 取消訂閱主題
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('已取消訂閱主題: $topic');
    } catch (e) {
      debugPrint('取消訂閱失敗: $e');
    }
  }
  
  /// 訂閱主題
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('已訂閱主題: $topic');
    } catch (e) {
      debugPrint('訂閱失敗: $e');
    }
  }
}

