import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/batch.dart';
import '../services/api_service.dart';
import '../widgets/system_notification_banner.dart';

/// 批次設定畫面
class BatchSettingsScreen extends StatefulWidget {
  /// 切換分頁回呼：index 與欲帶入的當前批次
  final void Function(int newIndex, Batch? batch)? onSwitchTab;

  const BatchSettingsScreen({super.key, this.onSwitchTab});

  @override
  State<BatchSettingsScreen> createState() => _BatchSettingsScreenState();
}

class _BatchSettingsScreenState extends State<BatchSettingsScreen> {
  final List<Batch> _batches = [];
  Batch? _currentBatch;
  bool _isLoading = false;
  final Set<int> _batchesWithLogs = {}; // 儲存有 log 的 ruleId 集合
  final Map<int, int> _batchPrintCounts = {}; // 儲存每個 batch 的已列印數量 (ruleId -> count)
  Timer? _notificationTimer;
  String? _notificationMessage;
  NotificationType? _notificationType;
  bool _isNotificationVisible = false;

  @override
  void initState() {
    super.initState();
    // 從 API 載入批次清單
    _loadBatchesFromApi();
  }

  /// 從 API 載入批次清單
  Future<void> _loadBatchesFromApi() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 並行載入批次清單和所有 log
      final results = await Future.wait([
        ApiService.getBatchList(),
        ApiService.getSuccessLogs(), // 不傳 ruleId，取得所有 log
        ApiService.getAlertLogs(), // 不傳 ruleId，取得所有 log
      ]);

      final items = results[0];
      final successLogs = results[1];
      final alertLogs = results[2];

      // 找出所有有 log 的 ruleId 並計算每個 batch 的已列印數量
      final batchesWithLogs = <int>{};
      final batchPrintCounts = <int, int>{};
      
      // 計算每個 batch 的已列印數量（從 successLogs）
      for (var log in successLogs) {
        final ruleId = log['ruleId'];
        if (ruleId is int) {
          batchesWithLogs.add(ruleId);
          batchPrintCounts[ruleId] = (batchPrintCounts[ruleId] ?? 0) + 1;
        }
      }
      
      // 記錄有 alert log 的 batch（但不計算數量）
      for (var log in alertLogs) {
        final ruleId = log['ruleId'];
        if (ruleId is int) {
          batchesWithLogs.add(ruleId);
        }
      }

      final loaded = items.map((m) {
        
        final startCode = m['startCode']?.toString() ?? '';
        final endCode = m['endCode']?.toString() ?? '';
        final startNum = int.tryParse(startCode) ?? startCode.hashCode;
        final endNum = int.tryParse(endCode) ?? endCode.hashCode;

        return Batch(
          id: m['ruleId']?.toString() ?? '', 
          name: m['batchName']?.toString() ?? '',
          startNumber: startNum,
          endNumber: endNum,
          isActive: m['isActive'] == true,
          allowDuplicate: m['allowDuplicate'] == true,
        );
      }).toList();

      // 找出當前 Active 批次
      final activeBatches = loaded.where((b) => b.isActive).toList();

      setState(() {
        _batches.clear();
        // 非 Active 的批次放入列表
        _batches.addAll(loaded.where((b) => !b.isActive));
        // Active 批次設為當前批次
        _currentBatch = activeBatches.isNotEmpty ? activeBatches.first : null;
        // 更新有 log 的 batch 集合
        _batchesWithLogs.clear();
        _batchesWithLogs.addAll(batchesWithLogs);
        // 更新每個 batch 的已列印數量
        _batchPrintCounts.clear();
        _batchPrintCounts.addAll(batchPrintCounts);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });

      // API 失敗時
      _showErrorMessage('載入批次失敗：$e');
    }
  }

  

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double contentTopPadding = _isNotificationVisible ? 96 : 24;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            if (_notificationType != null && _notificationMessage != null)
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  offset: _isNotificationVisible ? Offset.zero : const Offset(0, -1),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: _isNotificationVisible ? 1 : 0,
                    child: SystemNotificationBanner(
                      type: _notificationType!,
                      title: 'Batch Settings',
                      message: _notificationMessage!,
                      isVisible: true,
                      onDismiss: _hideNotificationBanner,
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, contentTopPadding, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 標題和新增按鈕
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Batch',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w400,
                            height: 42 / 28,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF2B7FFF),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _showCreateBatchDialog(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 內容區域
                    Expanded(
                      child: _batches.isEmpty ? _buildEmptyState() : _buildBatchList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 空狀態（無批次時顯示）
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '尚無批次',
            style: TextStyle(
              fontSize: 17,
              color: Color(0xFF99A1AF),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '點擊右上角 + 建立第一個批次',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF99A1AF),
            ),
          ),
        ],
      ),
    );
  }

  /// 批次列表
  Widget _buildBatchList() {
    return ListView(
      children: [
        _buildCurrentBatchSection(),
        const SizedBox(height: 24),
        _buildAllBatchSection(),
      ],
    );
  }

  /// 確認對話框
  Future<bool> _showConfirm({
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showNotificationBanner({
    required NotificationType type,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!mounted) return;

    _notificationTimer?.cancel();

    setState(() {
      _notificationType = type;
      _notificationMessage = message;
      _isNotificationVisible = true;
    });

    _notificationTimer = Timer(duration, () {
      if (!mounted) return;
      setState(() {
        _isNotificationVisible = false;
      });
    });
  }

  void _hideNotificationBanner() {
    if (!mounted) return;
    _notificationTimer?.cancel();
    setState(() {
      _isNotificationVisible = false;
    });
  }

  /// 顯示成功訊息
  void _showSuccessMessage(String message) {
    if (!mounted) return;
    _showNotificationBanner(
      type: NotificationType.success,
      message: message,
    );
  }

  /// 顯示錯誤訊息
  void _showErrorMessage(String message) {
    if (!mounted) return;
    _showNotificationBanner(
      type: NotificationType.error,
      message: message,
    );
  }

  /// 當前批次區塊
  Widget _buildCurrentBatchSection() {
    if (_currentBatch == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current Batch',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2B7FFF), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2B7FFF).withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 標題列：名稱和狀態標籤
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _currentBatch!.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF101828),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2B7FFF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 編輯按鈕
                  if (_currentBatch != null && !_hasLogs(_currentBatch!.id))
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 24),
                      color: const Color(0xFF6A7282),
                      onPressed: () {
                        if (_currentBatch == null) return;
                        _showEditBatchDialog(_currentBatch!);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              // 資訊卡片：範圍和已列印數量
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildInfoItem(
                      label: 'Range',
                      value: '${_currentBatch!.startNumber} - ${_currentBatch!.endNumber}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _buildInfoItem(
                      label: 'Printed',
                      value: '${_getPrintCount(_currentBatch!.id)}',
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // 重複檢查開關
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Allow Duplicate',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF101828),
                        ),
                      ),
                    ),
                    Switch(
                      value: _currentBatch?.allowDuplicate ?? false,
                      onChanged: (val) async {
                        if (_currentBatch == null) return;
                        final enabling = val == true;
                        final ok = await _showConfirm(
                          title: enabling ? 'Enable Allow Duplicate' : 'Disable Allow Duplicate',
                          message: enabling
                              ? 'This will allow duplicate codes for the current batch.'
                              : 'This will enable duplicate validation for the current batch.',
                          confirmText: 'OK',
                        );
                        if (!ok) return;

                        setState(() {
                          _isLoading = true;
                        });

                        try {
                          await ApiService.updateBatchPartial(
                            ruleId: _currentBatch!.id,
                            allowDuplicate: val,
                          );

                          if (!mounted) return;

                          setState(() {
                            _currentBatch = _currentBatch!.copyWith(allowDuplicate: val);
                            _isLoading = false;
                          });

                          _showSuccessMessage(val 
                              ? 'Allow Duplicate Enabled' 
                              : 'Allow Duplicate Disabled');

                          await _loadBatchesFromApi();
                        } catch (e) {
                          if (!mounted) return;

                          setState(() {
                            _isLoading = false;
                          });

                          _showErrorMessage('更新失敗：$e');
                        }
                      },
                      activeColor: const Color(0xFF2B7FFF),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 10),
              
              // 查看記錄按鈕
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    widget.onSwitchTab?.call(1, _currentBatch);
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('View Records'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B7FFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 建立資訊項目（用於顯示範圍和已列印數量）
  Widget _buildInfoItem({
    IconData? icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: const Color(0xFF6A7282)),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6A7282),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF101828),
            ),
          ),
        ],
      ),
    );
  }

  /// All Batch 區塊
  Widget _buildAllBatchSection() {
    final others = _batches;
    if (others.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'All Batch',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...others.map((b) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 標題列：名稱和標籤
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            b.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF101828),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (b.allowDuplicate)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3CD),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Allow Duplicate',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF856404),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // 資訊行：範圍和已列印數量
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildInfoItem(
                            label: 'Range',
                            value: '${b.startNumber} - ${b.endNumber}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _buildInfoItem(
                            label: 'Printed',
                            value: '${_getPrintCount(b.id)}',
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // 設為 Active 按鈕
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final ok = await _showConfirm(
                            title: 'Set Active',
                            message: 'Set ${b.name} (${b.startNumber} - ${b.endNumber}) as the current batch?\nOther batches will be deactivated.',
                            confirmText: 'Set Active',
                          );
                          if (!ok) return;

                          setState(() {
                            _isLoading = true;
                          });

                          try {
                            await ApiService.setBatchActive(ruleId: b.id);

                            if (!mounted) return;

                            setState(() {
                              _currentBatch = b.copyWith(isActive: true);
                              for (var i = 0; i < _batches.length; i++) {
                                final item = _batches[i];
                                _batches[i] = item.copyWith(isActive: item.id == b.id);
                              }
                              _isLoading = false;
                            });

                            _showSuccessMessage('已切換當前批次為 ${b.name} (${b.startNumber} - ${b.endNumber})');

                            await _loadBatchesFromApi();
                          } catch (e) {
                            if (!mounted) return;

                            setState(() {
                              _isLoading = false;
                            });

                            _showErrorMessage('設定失敗：$e');
                          }
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Set Active'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF2B7FFF)),
                          foregroundColor: const Color(0xFF2B7FFF),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  /// 檢查 batch 是否有 log
  bool _hasLogs(String batchId) {
    final ruleId = int.tryParse(batchId);
    if (ruleId == null) return false;
    return _batchesWithLogs.contains(ruleId);
  }

  /// 取得 batch 的已列印數量
  int _getPrintCount(String batchId) {
    final ruleId = int.tryParse(batchId);
    if (ruleId == null) return 0;
    return _batchPrintCounts[ruleId] ?? 0;
  }

  /// 建立新批次對話框
  void _showCreateBatchDialog() {
    final nameController = TextEditingController();
    final startController = TextEditingController();
    final endController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFFEFEFEF), // 亮灰色背景
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 標題欄
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'New Batch',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 表單內容
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF), 
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: nameController,
                        label: 'Batch Name',
                        hint: 'LCA1210',
                      ),
                      const SizedBox(height: 16),
                      _buildCodeInputField(
                        label: 'Start Number',
                        onChanged: (value) => startController.text = value,
                        initialValue: '',
                      ),
                      const SizedBox(height: 16),
                      _buildCodeInputField(
                        label: 'End Number',
                        onChanged: (value) => endController.text = value,
                        initialValue: '',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Create 按鈕
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _handleCreateBatch(
                      context,
                      nameController.text,
                      startController.text,
                      endController.text,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B7FFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Create',
                            style: TextStyle(
                              fontSize: 17,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditBatchDialog(Batch batch) {
    final nameController = TextEditingController(text: batch.name);
    final startController = TextEditingController(text: batch.startNumber.toString());
    final endController = TextEditingController(text: batch.endNumber.toString());

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFFEFEFEF), // 亮灰色背景
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 標題欄
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Batch',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 表單內容
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF), 
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: nameController,
                        label: 'Batch Name',
                        hint: batch.name,
                      ),
                      const SizedBox(height: 16),
                      _buildCodeInputField(
                        label: 'Start Number',
                        onChanged: (value) => startController.text = value,
                        initialValue: batch.startNumber.toString().padLeft(5, '0'),
                      ),
                      const SizedBox(height: 16),
                      _buildCodeInputField(
                        label: 'End Number',
                        onChanged: (value) => endController.text = value,
                        initialValue: batch.endNumber.toString().padLeft(5, '0'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Update 按鈕
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _handleUpdateBatch(
                      context,
                      batch,
                      nameController.text,
                      startController.text,
                      endController.text,  
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B7FFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 17,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

      

  /// 處理更新批次
  Future<void> _handleUpdateBatch(
    BuildContext context,
    Batch original,
    String name,
    String start,
    String end,
  ) async {
    if (name.isEmpty || start.isEmpty || end.isEmpty) {
      _showErrorMessage('請填寫所有欄位');
      return;
    }
    
    // 驗證 Start Number 和 End Number 必須是 5 碼數字
    if (start.length != 5 || !RegExp(r'^\d{5}$').hasMatch(start)) {
      _showErrorMessage('Start Number 必須是 5 碼數字');
      return;
    }
    
    if (end.length != 5 || !RegExp(r'^\d{5}$').hasMatch(end)) {
      _showErrorMessage('End Number 必須是 5 碼數字');
      return;
    }
    
    // 驗證區間規則：End Number 必須大於 Start Number
    final startNum = int.tryParse(start);
    final endNum = int.tryParse(end);
    
    if (startNum == null || endNum == null) {
      _showErrorMessage('數字格式錯誤');
      return;
    }
    
    if (endNum <= startNum) {
      _showErrorMessage('End Number 必須大於 Start Number');
      return;
    }

    final normalizedName = name.trim().toLowerCase();
    final existingNames = <String>{};
    if (_currentBatch != null && _currentBatch!.id != original.id) {
      existingNames.add(_currentBatch!.name.trim().toLowerCase());
    }
    for (final batch in _batches) {
      if (batch.id == original.id) continue;
      existingNames.add(batch.name.trim().toLowerCase());
    }
    if (existingNames.contains(normalizedName)) {
      _showNotificationBanner(
        type: NotificationType.warning,
        message: '此批次名稱已存在，請輸入不同的名稱',
      );
      return;
    }

    setState(() { _isLoading = true; });
    try {
      await ApiService.updateBatch(
        ruleId: original.id,
        name: name,
        start: start,
        end: end,
        allowDuplicate: original.allowDuplicate,
        isActive: original.isActive,
      );

      if (!mounted) return;
      
      Navigator.of(context).pop();
      _showSuccessMessage('批次已更新');
      
      // 重新載入批次資料以同步後端狀態
      await _loadBatchesFromApi();
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; });
      _showErrorMessage('更新失敗：$e');
    }
  }

  /// 驗證碼風格的數字輸入欄位（5 個格子）
  Widget _buildCodeInputField({
    required String label,
    required void Function(String value) onChanged,
    String initialValue = '',
  }) {
    return _CodeInputField(
      label: label,
      onChanged: onChanged,
      initialValue: initialValue,
    );
  }

  /// 輸入欄位
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF101828),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 14,
              color: Color(0xFF717182),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFD1D5DC)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFD1D5DC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2B7FFF)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  String? _extractBatchIdFromResponse(
    Map<String, dynamic> response,
  ) {
    const possibleKeys = ['ruleId', 'id', 'batchId'];
    for (final key in possibleKeys) {
      final value = response[key];
      if (value == null) continue;
      return value.toString();
    }
    return null;
  }

  /// 處理建立批次
  Future<void> _handleCreateBatch(
    BuildContext context,
    String name,
    String start,
    String end,
  ) async {
    if (name.isEmpty || start.isEmpty || end.isEmpty) {
      _showErrorMessage('請填寫所有欄位');
      return;
    }

    final normalizedName = name.trim().toLowerCase();
    final existingNames = <String>{};
    if (_currentBatch != null) {
      existingNames.add(_currentBatch!.name.trim().toLowerCase());
    }
    for (final batch in _batches) {
      existingNames.add(batch.name.trim().toLowerCase());
    }
    if (existingNames.contains(normalizedName)) {
      _showNotificationBanner(
        type: NotificationType.warning,
        message: '此批次名稱已存在，請輸入不同的名稱',
      );
      return;
    }
    
    // 驗證 Start Number 和 End Number 必須是 5 碼數字
    if (start.length != 5 || !RegExp(r'^\d{5}$').hasMatch(start)) {
      _showErrorMessage('Start Number 必須是 5 碼數字');
      return;
    }
    
    if (end.length != 5 || !RegExp(r'^\d{5}$').hasMatch(end)) {
      _showErrorMessage('End Number 必須是 5 碼數字');
      return;
    }
    
    // 驗證區間規則：End Number 必須大於 Start Number
    final startNum = int.tryParse(start);
    final endNum = int.tryParse(end);
    
    if (startNum == null || endNum == null) {
      _showErrorMessage('數字格式錯誤');
      return;
    }
    
    if (endNum <= startNum) {
      _showErrorMessage('End Number 必須大於 Start Number');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final createdBatch = await ApiService.createBatch(
        name: name,
        start: start,
        end: end,
      );

      if (!mounted) return;

      Navigator.of(context).pop();
      _showSuccessMessage('批次建立成功，已設定為目前批次');

      final newBatchId = _extractBatchIdFromResponse(createdBatch);

      if (newBatchId != null) {
        try {
          await ApiService.setBatchActive(ruleId: newBatchId);
        } catch (e) {
          if (!mounted) return;

          setState(() {
            _isLoading = false;
          });

          _showErrorMessage('批次建立成功，但設定為當前批次失敗：$e');
          await _loadBatchesFromApi();
          return;
        }
      }

      // 重新載入批次資料以同步後端狀態（並反映新 Active 批次）
      await _loadBatchesFromApi();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showErrorMessage('建立批次失敗：$e');
    }
  }
}

/// 驗證碼風格的數字輸入欄位（5 個格子）
class _CodeInputField extends StatefulWidget {
  final String label;
  final void Function(String value) onChanged;
  final String initialValue;

  const _CodeInputField({
    required this.label,
    required this.onChanged,
    this.initialValue = '',
  });

  @override
  State<_CodeInputField> createState() => _CodeInputFieldState();
}

class _CodeInputFieldState extends State<_CodeInputField> {
  late List<TextEditingController> controllers;
  late List<FocusNode> focusNodes;

  @override
  void initState() {
    super.initState();
    // 創建 5 個 TextEditingController
    controllers = List.generate(5, (index) {
      final controller = TextEditingController();
      if (widget.initialValue.length > index) {
        controller.text = widget.initialValue[index];
      }
      return controller;
    });

    // 創建 5 個 FocusNode
    focusNodes = List.generate(5, (index) => FocusNode());
  }

  @override
  void dispose() {
    // 釋放資源
    for (var controller in controllers) {
      controller.dispose();
    }
    for (var focusNode in focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  // 更新完整值的函數
  void updateValue() {
    final value = controllers.map((c) => c.text).join();
    widget.onChanged(value);
  }

  // 處理輸入，自動跳轉到下一個輸入框
  void handleInput(int index, String value) {
    if (value.isNotEmpty) {
      // 只保留最後一個輸入的字元（處理複製貼上的情況）
      final lastChar = value[value.length - 1];
      if (RegExp(r'^\d$').hasMatch(lastChar)) {
        controllers[index].text = lastChar;
        updateValue();
        
        // 使用 SchedulerBinding 確保在下一幀更新焦點
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // 跳轉到下一個輸入框
          if (index < 4) {
            focusNodes[index + 1].requestFocus();
          } else {
            // 最後一個輸入框，收起鍵盤
            focusNodes[index].unfocus();
          }
        });
      } else {
        // 如果不是數字，清空輸入框
        controllers[index].text = '';
        updateValue();
      }
    } else if (value.isEmpty) {
      // 刪除時跳轉到上一個輸入框
      controllers[index].text = '';
      updateValue();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (index > 0) {
          focusNodes[index - 1].requestFocus();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 計算每個方格的大小（考慮間距）
        // 可用寬度減去 Row 的間距（4 個間距，每個約 8px）
        final availableWidth = constraints.maxWidth;
        final spacing = 8.0 * 4; // 5 個方格之間有 4 個間距
        final cellSize = ((availableWidth - spacing) / 5).clamp(40.0, 60.0);
        // 字體大小根據方格大小調整
        final fontSize = (cellSize * 0.4).clamp(16.0, 24.0);
        // 圓角半徑根據方格大小調整
        final borderRadius = (cellSize * 0.2).clamp(8.0, 12.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF101828),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                return SizedBox(
                  width: cellSize,
                  height: cellSize,
                  child: TextField(
                    controller: controllers[index],
                    focusNode: focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                        borderSide: const BorderSide(color: Color(0xFFD1D5DC)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                        borderSide: const BorderSide(color: Color(0xFFD1D5DC)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                        borderSide: const BorderSide(color: Color(0xFF2B7FFF), width: 2),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) => handleInput(index, value),
                    onTap: () {
                      // 點擊時自動選中所有文字，方便刪除
                      controllers[index].selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: controllers[index].text.length,
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}
