/// API 設定檔
class ApiConfig {
  /// API Base URL
  /// 開發環境：http://192.168.4.54/BarcodeValidatorApi
  /// 正式環境：https://NT-SVN-LDR-IIS.makalot.com/BarcodeValidatorApi
  static const String baseUrl = 'https://nt-svn-ldr-iis.makalot.com/BarcodeValidatorApi';
  
  /// HTTP 請求超時時間（秒）
  static const int timeoutSeconds = 30;
}