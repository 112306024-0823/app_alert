/// 批次資料模型
class Batch {
  final String id;
  final String name;
  final int startNumber;
  final int endNumber;
  final bool isActive;
  final bool allowDuplicate; // whether duplicate validation is ignored for this batch

  Batch({
    required this.id,
    required this.name,
    required this.startNumber,
    required this.endNumber,
    this.isActive = false,
    this.allowDuplicate = false,
  });

  /// 檢查代碼是否在批次範圍內
  bool isCodeInRange(int code) {
    return code >= startNumber && code <= endNumber;
  }

  /// 取得批次的顯示名稱
  String get displayName => '$name ($startNumber - $endNumber)';

  /// 建立一個修改部分欄位的新實例
  Batch copyWith({
    String? id,
    String? name,
    int? startNumber,
    int? endNumber,
    bool? isActive,
    bool? allowDuplicate,
  }) {
    return Batch(
      id: id ?? this.id,
      name: name ?? this.name,
      startNumber: startNumber ?? this.startNumber,
      endNumber: endNumber ?? this.endNumber,
      isActive: isActive ?? this.isActive,
      allowDuplicate: allowDuplicate ?? this.allowDuplicate,
    );
  }
}

/// 代碼記錄模型
class CodeRecord {
  final String code;
  final String status; // Valid, Duplicate, Invalid
  final DateTime timestamp;
  final String? alert;

  CodeRecord({
    required this.code,
    required this.status,
    required this.timestamp,
    this.alert,
  });
}

/// 警示記錄模型
class AlertRecord {
  final String code;
  final String alertType;
  final DateTime timestamp;

  AlertRecord({
    required this.code,
    required this.alertType,
    required this.timestamp,
  });
}

