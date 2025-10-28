import 'package:flutter/material.dart';
import 'screens/batch_settings_screen.dart';
import 'screens/used_codes_screen.dart';
import 'models/batch.dart';

void main() {
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
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;

  List<Widget> _buildScreens() {
    return [
      const BatchSettingsScreen(),
      UsedCodesScreen(
        currentBatch: Batch(
          id: '1',
          name: '1234',
          startNumber: 500,
          endNumber: 1000,
          isActive: true,
        ),
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
