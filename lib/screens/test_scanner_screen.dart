import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/system_notification_banner.dart';
import '../models/batch.dart';

/// 測試掃描器畫面
/// 用於測試掃描功能，可以手動輸入代碼並掃描
class TestScannerScreen extends StatefulWidget {
  const TestScannerScreen({super.key});

  @override
  State<TestScannerScreen> createState() => _TestScannerScreenState();
}

class _TestScannerScreenState extends State<TestScannerScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isScanning = false;
  
  // 通知狀態
  bool _showNotification = false;
  NotificationType? _notificationType;
  String _notificationMessage = '';
  
  // 當前批次（用於驗證）
  Batch? _currentBatch;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// 處理掃描按鈕點擊
  Future<void> _handleScan() async {
    final code = _codeController.text.trim();
    
    if (code.isEmpty) {
      _showNotificationMessage(
        NotificationType.warning,
        '請輸入代碼',
      );
      return;
    }

    setState(() {
      _isScanning = true;
      _showNotification = false;
    });

    try {
      // 呼叫掃描 API
      final response = await ApiService.scanCode(code: code);
      
      // 處理 API 回應
      final status = response['status']?.toString() ?? 'Unknown';
      final message = response['message']?.toString() ?? '';
      
      // 根據狀態顯示通知
      if (status == 'Success' || status == 'Valid') {
        _showNotificationMessage(
          NotificationType.success,
          message.isNotEmpty 
              ? message 
              : 'Print Success (Code $code)',
        );
      } else if (status == 'OutOfRange' || status == 'Error') {
        // 檢查是否有批次資訊
        final batchName = response['batchName']?.toString() ?? '';
        final batchRange = response['batchRange']?.toString() ?? '';
        
        String alertMessage;
        if (batchRange.isNotEmpty) {
          alertMessage = 'Out of Range ($code not in batch $batchRange)';
        } else if (batchName.isNotEmpty) {
          alertMessage = 'Out of Range ($code not in batch $batchName)';
        } else {
          alertMessage = message.isNotEmpty 
              ? message 
              : 'Out of Range ($code not in valid range)';
        }
        
        _showNotificationMessage(
          NotificationType.error,
          alertMessage,
        );
      } else {
        _showNotificationMessage(
          NotificationType.warning,
          message.isNotEmpty ? message : 'Unknown status: $status',
        );
      }
    } catch (e) {
      // API 錯誤處理
      String errorMessage = '掃描失敗：$e';
      
      // 如果是網路錯誤或 API 不存在，使用本地驗證（如果有批次）
      if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('404')) {
        // 嘗試本地驗證
        if (_currentBatch != null) {
          final codeNum = int.tryParse(code);
          if (codeNum != null) {
            if (_currentBatch!.isCodeInRange(codeNum)) {
              _showNotificationMessage(
                NotificationType.success,
                'Print Success (Code $code)',
              );
            } else {
              _showNotificationMessage(
                NotificationType.error,
                'Out of Range ($code not in batch ${_currentBatch!.startNumber}–${_currentBatch!.endNumber})',
              );
            }
          } else {
            _showNotificationMessage(
              NotificationType.warning,
              '代碼格式錯誤',
            );
          }
        } else {
          _showNotificationMessage(
            NotificationType.warning,
            'API 無法連線，請確認網路設定',
          );
        }
      } else {
        _showNotificationMessage(
          NotificationType.error,
          errorMessage,
        );
      }
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  /// 顯示通知訊息
  void _showNotificationMessage(NotificationType type, String message) {
    setState(() {
      _notificationType = type;
      _notificationMessage = message;
      _showNotification = true;
    });

    // 3 秒後自動隱藏通知（成功通知）
    if (type == NotificationType.success) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showNotification = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 標題
              const Text(
                'Test Scanner',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  height: 42/28,
                ),
              ),
              const SizedBox(height: 24),
              
              // 測試掃描器輸入框和按鈕
              Row(
                children: [
                  // 代碼輸入框
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFFD1D5DC),
                          width: 1.25,
                        ),
                      ),
                      child: TextField(
                        controller: _codeController,
                        decoration: InputDecoration(
                          hintText: 'Code',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFF0A0A0A).withOpacity(0.5),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                        style: const TextStyle(fontSize: 14),
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleScan(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 掃描按鈕
                  Container(
                    width: 55,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C950),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isScanning ? null : _handleScan,
                        borderRadius: BorderRadius.circular(4),
                        child: Center(
                          child: _isScanning
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Scan',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // 通知橫幅（顯示在頂部）
              if (_showNotification && _notificationType != null)
                SystemNotificationBanner(
                  type: _notificationType!,
                  title: 'App',
                  message: _notificationMessage,
                  isVisible: _showNotification,
                  onDismiss: () {
                    setState(() {
                      _showNotification = false;
                    });
                  },
                ),
              
              const Spacer(),
              
              // 使用說明
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '使用說明',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF101828),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• 輸入代碼後點擊 Scan 按鈕進行掃描\n'
                      '• 系統會驗證代碼是否在當前批次範圍內\n'
                      '• 掃描結果會顯示在上方的通知橫幅中',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

