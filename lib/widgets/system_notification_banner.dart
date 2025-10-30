import 'package:flutter/material.dart';

/// 系統通知橫幅組件
/// 用於顯示掃描結果的通知訊息（成功或錯誤）
class SystemNotificationBanner extends StatelessWidget {
  /// 通知類型
  final NotificationType type;
  
  /// 通知標題（通常為 "App"）
  final String title;
  
  /// 通知訊息內容
  final String message;
  
  /// 顯示/隱藏
  final bool isVisible;
  
  /// 關閉回調
  final VoidCallback? onDismiss;

  const SystemNotificationBanner({
    super.key,
    required this.type,
    this.title = 'App',
    required this.message,
    this.isVisible = true,
    this.onDismiss,
  });

  /// 根據類型取得圖標顏色
  Color get _iconColor {
    switch (type) {
      case NotificationType.success:
        return const Color(0xFF00C950);
      case NotificationType.error:
        return const Color(0xFFFB2C36);
      case NotificationType.warning:
        return const Color(0xFFFFA500);
    }
  }

  /// 根據類型取得圖標
  IconData get _icon {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.warning:
        return Icons.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 圖標容器
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _iconColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _icon,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          // 文字內容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4A5565),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF101828),
                  ),
                ),
              ],
            ),
          ),
          // 關閉按鈕（可選）
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: const Color(0xFF9CA3AF),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

/// 通知類型
enum NotificationType {
  /// 成功通知（綠色）
  success,
  
  /// 錯誤通知（紅色）
  error,
  
  /// 警告通知（橙色）
  warning,
}



