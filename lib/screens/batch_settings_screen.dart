import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/batch.dart';
import '../services/api_service.dart';

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

      // 找出所有有 log 的 ruleId
      final batchesWithLogs = <int>{};
      for (var log in successLogs) {
        final ruleId = log['ruleId'];
        if (ruleId is int) {
          batchesWithLogs.add(ruleId);
        }
      }
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                      height: 42/28,
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
                child: _batches.isEmpty
                    ? _buildEmptyState()
                    : _buildBatchList(),
              ),
            ],
          ),
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

  /// 顯示成功訊息
  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 顯示錯誤訊息
  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// 當前批次區塊
  Widget _buildCurrentBatchSection() {
    if (_currentBatch == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Current Batch',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _currentBatch!.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.circle,
                            size: 8,
                            color: Color(0xFF2B7FFF),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF2B7FFF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_currentBatch!.startNumber} - ${_currentBatch!.endNumber}',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  // 只有在該 batch 沒有 log 時才顯示編輯按鈕
                  if (_currentBatch != null && !_hasLogs(_currentBatch!.id))
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        if (_currentBatch == null) return;
                        _showEditBatchDialog(_currentBatch!);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Ignore duplicate check - simple switch row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Ignore duplicate check',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
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
                          title: enabling ? 'Enable ignore duplicate' : 'Disable ignore duplicate',
                          message: enabling
                              ? 'This will skip duplicate validation for the current batch.'
                              : 'This will enable duplicate validation for the current batch.',
                          confirmText: 'OK',
                        );
                        if (!ok) return;

                        // 呼叫 PATCH API 更新 allowDuplicate
                        setState(() {
                          _isLoading = true;
                        });

                        try {
                          await ApiService.updateBatchPartial(
                            ruleId: _currentBatch!.id,
                            allowDuplicate: val,
                          );

                          if (!mounted) return;

                          // 更新本地狀態
                          setState(() {
                            _currentBatch = _currentBatch!.copyWith(allowDuplicate: val);
                            _isLoading = false;
                          });

                          _showSuccessMessage(val 
                              ? 'Enable ignore duplicate' 
                              : 'Disable ignore duplicate');

                          // 重新載入批次資料以同步後端狀態
                          await _loadBatchesFromApi();
                        } catch (e) {
                          if (!mounted) return;

                          setState(() {
                            _isLoading = false;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('更新失敗：$e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      activeColor: const Color(0xFF2B7FFF),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // 透過上層回呼切換到 Used Codes 分頁（index=1）
                        widget.onSwitchTab?.call(1, _currentBatch);
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('View Record'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B7FFF),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ),
      ],
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
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          b.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (b.allowDuplicate)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3CD),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'ignore-dup-check',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF856404),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${b.startNumber} - ${b.endNumber}',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF6A7282),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          final ok = await _showConfirm(
                            title: 'Set Active',
                            message: 'Set ${b.name} (${b.startNumber} - ${b.endNumber}) as the current batch?\nOther batches will be deactivated.',
                            confirmText: 'Set Active',
                          );
                          if (!ok) return;

                          // 呼叫 API 設定為 Active
                          setState(() {
                            _isLoading = true;
                          });

                          try {
                            await ApiService.setBatchActive(ruleId: b.id);

                            if (!mounted) return;

                            // 更新本地狀態
                            setState(() {
                              // 更新 current 與列表 isActive 標記
                              _currentBatch = b.copyWith(isActive: true);
                              for (var i = 0; i < _batches.length; i++) {
                                final item = _batches[i];
                                _batches[i] = item.copyWith(isActive: item.id == b.id);
                              }
                              _isLoading = false;
                            });

                            _showSuccessMessage('已切換當前批次為 ${b.name} (${b.startNumber} - ${b.endNumber})');

                            // 重新載入批次資料以同步後端狀態
                            await _loadBatchesFromApi();
                          } catch (e) {
                            if (!mounted) return;

                            setState(() {
                              _isLoading = false;
                            });

                            _showErrorMessage('設定失敗：$e');
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFD1D5DC)),
                          foregroundColor: const Color(0xFF101828),
                        ),
                        child: const Text('Set Active'),
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
      await ApiService.createBatch(
        name: name,
        start: start,
        end: end,
      );

      if (!mounted) return;

      Navigator.of(context).pop();
      _showSuccessMessage('批次建立成功！');

      // 重新載入批次資料以同步後端狀態
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
              width: 50,
              height: 50,
              child: TextField(
                controller: controllers[index],
                focusNode: focusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: const TextStyle(
                  fontSize: 20,
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
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DC)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DC)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
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
  }
}
