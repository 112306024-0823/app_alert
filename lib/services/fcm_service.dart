import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/navigation_helper.dart'; // 引入 navigatorKey
import '../main.dart'; // 引入 MyHomePage


/// FCM 服務類別
/// 負責處理 Firebase Cloud Messaging 相關功能
class FcmService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  /// 初始化 FCM 服務
  /// 取得 FCM Token 並註冊到後端
  /// 參考：https://ithelp.ithome.com.tw/articles/10352942
  static Future<void> initialize({String? vapidKey}) async {
    try {
      // 請求通知權限
      // 使用 provisional: true 可以設置臨時權限（iOS）
      final NotificationSettings notificationSettings = 
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: true, // iOS 臨時權限，讓用戶可以先收到通知再決定
      );
      
      // 檢查權限狀態
      debugPrint('通知權限狀態: ${notificationSettings.authorizationStatus}');
      
      // 根據權限狀態處理
      switch (notificationSettings.authorizationStatus) {
        case AuthorizationStatus.authorized:
        case AuthorizationStatus.provisional:
          debugPrint('通知權限已授予');
          break;
        case AuthorizationStatus.denied:
          debugPrint('通知權限被拒絕');
          return;
        case AuthorizationStatus.notDetermined:
          debugPrint('通知權限尚未決定');
          return;
      }
      
      // iOS 平台：確保 APNS token 可用
      // 參考文章：For apple platforms, ensure the APNS token is available before making any FCM plugin API calls
      if (!kIsWeb) {
        try {
          // 檢查是否為 iOS 平台
          // 注意：在 Web 平台上無法使用 Platform.isIOS
          final apnsToken = await _firebaseMessaging.getAPNSToken();
          if (apnsToken == null) {
            debugPrint('警告：iOS APNS Token 尚未可用，可能會影響 FCM 功能');
            // 可以選擇等待或重試
          } else {
            debugPrint('iOS APNS Token 已可用');
          }
        } catch (e) {
          // 非 iOS 平台或尚未初始化時會拋出異常
          debugPrint('APNS Token 檢查: $e');
        }
      }
      
      // 取得 FCM Token
      // Web 平台需要使用 VAPID Key
      String? token;
      if (kIsWeb && vapidKey != null) {
        token = await _firebaseMessaging.getToken(vapidKey: vapidKey);
      } else {
        token = await _firebaseMessaging.getToken();
      }
      
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
        // Web 平台可能需要 VAPID Key
        if (kIsWeb) {
          debugPrint('提示：Web 平台需要提供 VAPID Key 才能取得 Token');
        }
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
      // 檢查是否是錯誤通知（Duplicate、OutOfRange）
      final result = message.data['result'];
      if (result == 'Duplicate' || result == 'OutOfRange') {
        debugPrint('收到錯誤通知: $result');
        // 可以在這裡觸發 flutter_local_notifications 套件顯示本地通知
      }
    });
    
    // 當使用者點擊通知開啟 App
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('使用者點擊通知開啟 App: ${message.notification?.title}');
      debugPrint('通知資料: ${message.data}');
      
      // 處理通知點擊後的導航邏輯
      // 根據 message.data 跳轉到 Used Codes 頁面
      _handleNotificationNavigation(message);
    });
    
    // 檢查 App 是否由通知開啟（App 在背景時點擊通知）
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App 由通知開啟: ${message.notification?.title}');
        debugPrint('通知資料: ${message.data}');
        
        // 處理導航邏輯
        _handleNotificationNavigation(message);
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
  
  /// 處理通知點擊後的導航邏輯
  /// 根據 message.data 跳轉到 Used Codes 頁面
  static void _handleNotificationNavigation(RemoteMessage message) {
    final result = message.data['result'];
    
    // 如果是錯誤通知（Duplicate、OutOfRange），導航到 Used Codes 頁面
    if (result == 'Duplicate' || result == 'OutOfRange') {
      debugPrint('導航到 Used Codes 頁面（Alert Records）');
      
      // 使用全局導航鍵導航到 Used Codes 頁面（index = 1）
      final context = navigatorKey.currentContext;
      if (context != null) {
        // 找到 MyHomePage 並切換到 Used Codes 分頁
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const MyHomePage(initialIndex: 1),
          ),
          (route) => false, // 清除所有先前的路由
        );
      }
    }
  }
}

