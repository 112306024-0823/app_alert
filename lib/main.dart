import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/batch_settings_screen.dart';
import 'screens/used_codes_screen.dart';
import 'screens/test_scanner_screen.dart';
import 'models/batch.dart';
import 'services/fcm_service.dart';

// 背景訊息處理器（必須是頂層函數）
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('收到背景通知: ${message.notification?.title}');
  debugPrint('通知內容: ${message.notification?.body}');
  debugPrint('通知資料: ${message.data}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 Firebase
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase 初始化成功');
    
    // 設定背景訊息處理器
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    // 初始化 FCM 服務
    await FcmService.initialize();
  } catch (e) {
    debugPrint('Firebase 初始化失敗: $e');
    // 即使 Firebase 初始化失敗，也繼續運行 App
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Alert - Batch Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

/// 主頁面（包含狀態列和導航）
class MyHomePage extends StatefulWidget {
  final int initialIndex;
  const MyHomePage({super.key, this.initialIndex = 0});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;
  Batch? _selectedBatch;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  List<Widget> _buildScreens() {
    return [
      BatchSettingsScreen(
        onSwitchTab: (newIndex, batch) {
          setState(() {
            _currentIndex = newIndex;
            _selectedBatch = batch;
          });
        },
      ),
      UsedCodesScreen(
        currentBatch: _selectedBatch ?? Batch(
          id: '1',
          name: '1234',
          startNumber: 500,
          endNumber: 1000,
          isActive: true,
          allowDuplicate: false,
        ),
        onSwitchTab: (newIndex) {
          setState(() {
            _currentIndex = newIndex;
          });
        },
      ),
      const TestScannerScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 內容區域
          Expanded(child: _buildScreens()[_currentIndex]),
          // 底部導航欄
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  /// 底部導航欄
  Widget _buildBottomNavigation() {
    return Container(
      height: 84,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: Icons.batch_prediction,
              label: 'Batch Settings',
              index: 0,
            ),
            _buildNavItem(
              icon: Icons.assignment,
              label: 'Used Codes',
              index: 1,
            ),
            _buildNavItem(
              icon: Icons.qr_code_scanner,
              label: 'Test Scanner',
              index: 2,
            ),
          ],
        ),
      ),
    );
  }

  /// 導航項目
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF2B7FFF) : const Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? const Color(0xFF2B7FFF) : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
