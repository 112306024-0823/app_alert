import 'package:flutter/material.dart';
import '../models/batch.dart';
import '../services/api_service.dart';

/// 已使用代碼畫面（階段四：App 查詢紀錄）
class UsedCodesScreen extends StatefulWidget {
  final void Function(int newIndex)? onSwitchTab;

  const UsedCodesScreen({
    super.key,
    this.onSwitchTab,
  });

  @override
  State<UsedCodesScreen> createState() => _UsedCodesScreenState();
}

/// 全局刷新回呼管理器
class UsedCodesRefreshManager {
  static final List<VoidCallback> _refreshCallbacks = [];

  /// 註冊刷新回呼
  static void register(VoidCallback callback) {
    _refreshCallbacks.add(callback);
  }

  /// 移除刷新回呼
  static void unregister(VoidCallback callback) {
    _refreshCallbacks.remove(callback);
  }

  /// 觸發所有註冊的畫面刷新
  static void triggerRefresh() {
    for (var callback in _refreshCallbacks) {
      callback();
    }
  }
}

class _UsedCodesScreenState extends State<UsedCodesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<CodeRecord> _codes = [];
  List<AlertRecord> _alerts = [];
  bool _isLoading = false;
  bool? _allowDuplicate; // 從 API 取得的 allowDuplicate 狀態
  Batch? _currentBatch; // 當前 active 批次
  String _searchQuery = ''; // 搜尋關鍵字

  @override
  void initState() {
    super.initState();
    _loadData();
    // 監聽搜尋框輸入
    _searchController.addListener(_onSearchChanged);
    // 註冊刷新回呼（用於 FCM 通知觸發更新）
    UsedCodesRefreshManager.register(_loadData);
  }

  /// 搜尋框內容變更時觸發
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  /// 根據搜尋關鍵字過濾代碼列表
  List<CodeRecord> get _filteredCodes {
    if (_searchQuery.isEmpty) {
      return _codes;
    }
    return _codes.where((code) {
      return code.code.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  /// 根據搜尋關鍵字過濾警告列表
  List<AlertRecord> get _filteredAlerts {
    if (_searchQuery.isEmpty) {
      return _alerts;
    }
    return _alerts.where((alert) {
      return alert.code.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  /// 載入資料（階段四：App 查詢紀錄）
  /// [silent] 是否靜默載入（不顯示載入動畫）
  Future<void> _loadData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // 並行載入批次資訊、成功紀錄和錯誤紀錄
      final results = await Future.wait([
        ApiService.getBatchList(), // 取得批次清單以找出 active 批次
        ApiService.getSuccessLogs(), // 先取得所有 log
        ApiService.getAlertLogs(), // 先取得所有 log
      ]);

      final batchList = results[0];
      final successLogs = results[1];
      final alertLogs = results[2];
      
      // 找出當前 active 批次
      Batch? activeBatch;
      bool allowDuplicate = false;
      
      try {
        // 從批次清單中找到 isActive = true 的批次
        final activeBatchData = batchList.firstWhere(
          (batch) => batch['isActive'] == true,
        );
        
        final startCode = activeBatchData['startCode']?.toString() ?? '';
        final endCode = activeBatchData['endCode']?.toString() ?? '';
        final startNum = int.tryParse(startCode) ?? startCode.hashCode;
        final endNum = int.tryParse(endCode) ?? endCode.hashCode;
        
        activeBatch = Batch(
          id: activeBatchData['ruleId']?.toString() ?? '',
          name: activeBatchData['batchName']?.toString() ?? '',
          startNumber: startNum,
          endNumber: endNum,
          isActive: true,
          allowDuplicate: activeBatchData['allowDuplicate'] == true,
        );
        
        allowDuplicate = activeBatch.allowDuplicate;
      } catch (e) {
        // 如果找不到 active 批次，使用預設值
        activeBatch = null;
        allowDuplicate = false;
      }
      
      // 取得 active 批次的 ruleId
      final ruleId = activeBatch != null ? int.tryParse(activeBatch.id) : null;

      setState(() {
        // 更新當前 active 批次和 allowDuplicate 狀態
        _currentBatch = activeBatch;
        _allowDuplicate = allowDuplicate;
        
        // 根據 ruleId 過濾 log（ruleId 是 int 類型）
        final filteredSuccessLogs = ruleId != null
            ? successLogs.where((log) {
                final logRuleId = log['ruleId'];
                return logRuleId is int && logRuleId == ruleId;
              }).toList()
            : [];
        
        final filteredAlertLogs = ruleId != null
            ? alertLogs.where((log) {
                final logRuleId = log['ruleId'];
                return logRuleId is int && logRuleId == ruleId;
              }).toList()
            : [];
        
        // 轉換為 CodeRecord
        _codes = filteredSuccessLogs.map((log) {
          return CodeRecord(
            code: log['scannedCode']?.toString() ?? '',
            status: log['status']?.toString() ?? '',
            timestamp: _parseDateTime(log['timestamp']),
          );
        }).toList();

        // 轉換為 AlertRecord
        _alerts = filteredAlertLogs.map((log) {
          return AlertRecord(
            code: log['scannedCode']?.toString() ?? '',
            alertType: log['status']?.toString() ?? '',
            timestamp: _parseDateTime(log['timestamp']),
          );
        }).toList();

        if (!silent) {
          setState(() {
            _isLoading = false;
          });
        } else {
          // 靜默刷新時也要更新狀態，但不顯示載入動畫
          setState(() {});
        }
      });
    } catch (e) {
      if (!silent) {
        setState(() {
          _isLoading = false;
        });
      }

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
              _currentBatch != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Batch Name: ${_currentBatch!.name}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Batch Range: ${_currentBatch!.startNumber} - ${_currentBatch!.endNumber}',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF6A7282),
                          ),
                        ),
                      ],
                    )
                  : const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No Active Batch',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6A7282),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Please create and activate a batch first',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF6A7282),
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 24),
              
              // Ignore duplicate check 提醒（根據 API 取得的 allowDuplicate 狀態顯示）
              if (_allowDuplicate == true)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber, color: Color(0xFF856404), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Duplicate check disabled for current batch',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF856404),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_allowDuplicate == true)
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
        decoration: InputDecoration(
          hintText: 'Search by code...',
          hintStyle: const TextStyle(
            fontSize: 14,
            color: Color(0xFF717182),
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 16,
            color: Color(0xFF717182),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear,
                    size: 18,
                    color: Color(0xFF717182),
                  ),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              _searchQuery.isEmpty
                  ? '列印數：${_codes.length}'
                  : '列印數：${_filteredCodes.length} / ${_codes.length}',
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF4A5565),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _filteredCodes.isEmpty && _searchQuery.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    '找不到符合 "$_searchQuery" 的代碼',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6A7282),
                    ),
                  ),
                ),
              )
            : Column(
                children: [
                  _buildTableHeader(['Code', 'Status', 'Time']),
                  const SizedBox(height: 12),
                  ..._filteredCodes.map((code) => _buildTableRow(
                        code: code.code,
                        status: code.status,
                        time: code.timestamp,
                        isAlert: false,
                      )),
                ],
              ),
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
              _searchQuery.isEmpty
                  ? '警告次數：${_alerts.length}'
                  : '警告次數：${_filteredAlerts.length} / ${_alerts.length}',
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF4A5565),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _filteredAlerts.isEmpty && _searchQuery.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    '找不到符合 "$_searchQuery" 的警告記錄',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6A7282),
                    ),
                  ),
                ),
              )
            : Column(
                children: [
                  _buildTableHeader(['Code', 'Alert', 'Time']),
                  const SizedBox(height: 12),
                  ..._filteredAlerts.map((alert) => _buildTableRow(
                        code: alert.code,
                        status: alert.alertType,
                        time: alert.timestamp,
                        isAlert: true,
                      )),
                ],
              ),
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
    UsedCodesRefreshManager.unregister(_loadData);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
}

