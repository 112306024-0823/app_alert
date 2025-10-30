import 'package:flutter/material.dart';
import '../models/batch.dart';
import '../services/api_service.dart';

/// 已使用代碼畫面（階段四：App 查詢紀錄）
class UsedCodesScreen extends StatefulWidget {
  final Batch currentBatch;
  final void Function(int newIndex)? onSwitchTab;

  const UsedCodesScreen({
    super.key,
    required this.currentBatch,
    this.onSwitchTab,
  });

  @override
  State<UsedCodesScreen> createState() => _UsedCodesScreenState();
}

class _UsedCodesScreenState extends State<UsedCodesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<CodeRecord> _codes = [];
  List<AlertRecord> _alerts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 載入資料（階段四：App 查詢紀錄）
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 並行載入成功和錯誤紀錄
      final results = await Future.wait([
        ApiService.getSuccessLogs(),
        ApiService.getAlertLogs(),
      ]);

      final successLogs = results[0];
      final alertLogs = results[1];

      setState(() {
        // 轉換為 CodeRecord
        _codes = successLogs.map((log) {
          return CodeRecord(
            code: log['scannedCode']?.toString() ?? '',
            status: log['status']?.toString() ?? '',
            timestamp: _parseDateTime(log['timestamp']),
          );
        }).toList();

        // 轉換為 AlertRecord
        _alerts = alertLogs.map((log) {
          return AlertRecord(
            code: log['scannedCode']?.toString() ?? '',
            alertType: log['status']?.toString() ?? '',
            timestamp: _parseDateTime(log['timestamp']),
          );
        }).toList();

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('載入資料失敗：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 解析日期時間
  DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return DateTime.now();
    
    if (dateTime is String) {
      try {
        return DateTime.parse(dateTime);
      } catch (e) {
        return DateTime.now();
      }
    }
    
    return DateTime.now();
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
              // 標題：顯示 Batch Name 與 Batch Range
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Batch Name: ${widget.currentBatch.name}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Batch Range: ${widget.currentBatch.startNumber} - ${widget.currentBatch.endNumber}',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6A7282),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Duplicate check disabled for current batch',
              style: TextStyle(fontSize: 13, color: Color(0xFF856404)),
            ),
          ),
              const SizedBox(height: 24),
              
              // 搜尋框和刷新按鈕
              Row(
                children: [
                  Expanded(child: _buildSearchBar()),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    onPressed: _isLoading ? null : _loadData,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Valid Codes 區塊
              Expanded(
                child: _isLoading && _codes.isEmpty && _alerts.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildValidCodesSection(),
                              const SizedBox(height: 24),
                              _buildAlertRecordsSection(),
                              const SizedBox(height: 24),
                              _buildBatchSettingsButton(),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 當前批次卡片
  Widget _buildCurrentBatchCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.currentBatch.displayName,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF101828),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right,
            size: 20,
            color: Color(0xFF101828),
          ),
        ],
      ),
    );
  }

  /// 搜尋框
  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Search',
          hintStyle: TextStyle(
            fontSize: 14,
            color: Color(0xFF717182),
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 16,
            color: Color(0xFF717182),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  /// Valid Codes 區塊
  Widget _buildValidCodesSection() {
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '✓ Valid Codes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF00A63E),
              ),
            ),
            Text(
              '列印數：${_codes.length}',
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF4A5565),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTableHeader(['Code', 'Status', 'Time']),
        const SizedBox(height: 12),
        ..._codes.map((code) => _buildTableRow(
          code: code.code,
          status: code.status,
          time: code.timestamp,
          isAlert: false,
        )),
      ],
    );
  }

  /// Alert Records 區塊
  Widget _buildAlertRecordsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '⚠ Alert Records',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE7000B),
              ),
            ),
            Text(
              '警告次數：${_alerts.length}',
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF4A5565),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTableHeader(['Code', 'Alert', 'Time']),
        const SizedBox(height: 12),
        ..._alerts.map((alert) => _buildTableRow(
          code: alert.code,
          status: alert.alertType,
          time: alert.timestamp,
          isAlert: true,
        )),
      ],
    );
  }

  /// 表格標題
  Widget _buildTableHeader(List<String> headers) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1.25,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              headers[0],
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4A5565),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              headers[1],
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4A5565),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                headers[2],
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF4A5565),
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 表格資料列
  Widget _buildTableRow({
    required String code,
    required String status,
    required DateTime time,
    required bool isAlert,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isAlert ? const Color(0xFFF3F4F6) : Colors.transparent,
            width: 1.25,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              code,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF101828),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              status,
              style: TextStyle(
                fontSize: 15,
                color: isAlert ? const Color(0xFFE7000B) : const Color(0xFF00A63E),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDate(time),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6A7282),
                  ),
                ),
                Text(
                  _formatTime(time),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6A7282),
                  ),
                ),
              ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Batch Settings 按鈕
  Widget _buildBatchSettingsButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () {
          // 切回 Batch Settings 主頁（index=0）。若無回呼則嘗試返回。
          if (widget.onSwitchTab != null) {
            widget.onSwitchTab!(0);
          } else {
            Navigator.pop(context);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2B7FFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Batch Settings',
          style: TextStyle(
            fontSize: 17,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// 格式化日期
  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')}';
  }

  /// 格式化時間
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

