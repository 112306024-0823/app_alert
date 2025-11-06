import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_msg.dart'; 

import 'firebase_options.dart';
import 'screens/batch_settings_screen.dart';
import 'screens/used_codes_screen.dart';
import 'utils/navigation_helper.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 Firebase（加入錯誤處理）
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase 初始化成功');
    
    // 初始化 FCM（加入錯誤處理）
    try {
      await FirebaseMsg().initFCM();
    } catch (e) {
      debugPrint('FCM 初始化失敗: $e');
      // 即使 FCM 失敗，也繼續運行 App
    }
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
      title: 'Barcode Validator',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // 設置全局導航鍵
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
          });
        },
      ),
      UsedCodesScreen(
        onSwitchTab: (newIndex) {
          setState(() {
            _currentIndex = newIndex;
          });
        },
      ),
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
