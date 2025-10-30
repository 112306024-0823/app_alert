import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// API 服務類別
/// 負責與 C# 後端 API 溝通的所有 HTTP 請求
class ApiService {
  /// API Base URL（從配置檔讀取）
  static String get baseUrl => ApiConfig.baseUrl;
  
  /// HTTP 請求超時時間
  static Duration get timeout => Duration(seconds: ApiConfig.timeoutSeconds);
  
  /// 建立新批次
  /// 
  /// 參數：
  /// - name: 批次名稱（例如 "2025-10A"）
  /// - start: 開始編號（例如 "1000"）
  /// - end: 結束編號（例如 "1999"）
  /// 
  /// 回傳：API 回應的 JSON 資料
  /// 
  /// API: POST /api/batch/create
  static Future<Map<String, dynamic>> createBatch({
    required String name,
    required String start,
    required String end,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/Batch/create');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'batchName': name,
          'startCode': start,
          'endCode': end,
        }),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'API 錯誤: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('建立批次失敗: $e');
    }
  }
  
  /// 階段一：註冊裝置（取得 FCM Token 並註冊）
  /// 
  /// 參數：
  /// - token: FCM Token（例如 "c3po...R2D2"）
  /// 
  /// API: POST /api/Batch/register
  /// Body: { "fcmToken": "c3po...R2D2" }
  static Future<Map<String, dynamic>> registerDevice({
    required String token,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/Batch/register');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fcmToken': token,
        }),
      ).timeout(timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'API 錯誤: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('註冊裝置失敗: $e');
    }
  }

  /// 掃描代碼（測試掃描器）
  /// 
  /// 參數：
  /// - code: 掃描的代碼（例如 "1234"）
  /// 
  /// 回傳：API 回應的 JSON 資料，包含驗證結果
  /// 
  /// API: POST /api/scan/validate
  /// Body: { "code": "1234" }
  static Future<Map<String, dynamic>> scanCode({
    required String code,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/scan/validate');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'code': code,
        }),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'API 錯誤: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('掃描代碼失敗: $e');
    }
  }

  /// 階段四：取得警示紀錄（錯誤紀錄）
  /// 
  /// API: GET /api//alerts
  /// 
  /// Response Format:
  /// {
  ///   "count": 2,
  ///   "logs": [...]
  /// }
  static Future<List<Map<String, dynamic>>> getAlertLogs() async {
    try {
      final url = Uri.parse('$baseUrl/api/Batch/alerts');
      
      final response = await http.get(url).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // 處理新的 Response 格式
        if (data is Map && data.containsKey('logs')) {
          return List<Map<String, dynamic>>.from(data['logs']);
        }
        
        return [];
      } else {
        throw Exception('API 錯誤: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('取得警示紀錄失敗: $e');
    }
  }


  static Future<List<Map<String, dynamic>>> getSuccessLogs() async {
    try {
      final url = Uri.parse('$baseUrl/api/Batch/success');
      
      final response = await http.get(url).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // 處理新的 Response 格式
        if (data is Map && data.containsKey('logs')) {
          return List<Map<String, dynamic>>.from(data['logs']);
        }
        
        return [];
      } else {
        throw Exception('API 錯誤: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('取得成功紀錄失敗: $e');
    }
  }
  
  /// 測試 API 連線
  static Future<bool> testConnection() async {
    try {
      final url = Uri.parse('$baseUrl/swagger/index.html');
      final response = await http.get(url).timeout(timeout);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// 更新批次資訊
  ///
  /// API: POST /api/Batch/update
  ///
  /// 參數說明（依既有 create 命名推測）：
  /// - id: 批次 ID（batchId）
  /// - name: 批次名稱（batchName）
  /// - start: 開始編號（startCode）
  /// - end: 結束編號（endCode）
  /// - allowDuplicate: 是否忽略重複檢查（選填）
  /// - isActive: 是否為當前批次（選填）
  static Future<Map<String, dynamic>> updateBatch({
    required String id,
    required String name,
    required String start,
    required String end,
    bool? allowDuplicate,
    bool? isActive,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/Batch/update');
      final body = <String, dynamic>{
        'batchId': id,
        'batchName': name,
        'startCode': start,
        'endCode': end,
      };
      if (allowDuplicate != null) body['allowDuplicate'] = allowDuplicate;
      if (isActive != null) body['isActive'] = isActive;

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'API 錯誤: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('更新批次失敗: $e');
    }
  }
}
