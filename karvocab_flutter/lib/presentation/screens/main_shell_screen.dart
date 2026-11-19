import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'library_screen.dart';
import 'profile_screen.dart';

/// Khung Điều hướng chính (Main Shell Screen) với Bottom Navigation 4 Tab
/// Chuẩn Figma & Đảm bảo Dev FE1 và FE2 không bị xung đột code
class MainShellScreen extends StatefulWidget {
  final int initialTabIndex;

  const MainShellScreen({super.key, this.initialTabIndex = 1}); // Mặc định mở Thư viện

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
  }

  @override
  Widget build(BuildContext context) {
    // 4 Màn hình tương ứng 4 Tab
    final List<Widget> pages = [
      _buildHomePlaceholder(),
      const LibraryScreen(), // Tab Thư viện do FE1 phát triển
      _buildPracticePlaceholder(), // Tab Luyện tập chờ FE2 cắm Quiz Engine
      const ProfileScreen(), // Tab Hồ sơ cá nhân do FE1 phát triển (Màn 15)
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.borderLight, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: AppColors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primaryBlue,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: AppTypography.labelSmall.copyWith(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_library_outlined),
              activeIcon: Icon(Icons.local_library_rounded),
              label: 'Thư viện',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology_outlined),
              activeIcon: Icon(Icons.psychology_rounded),
              label: 'Luyện tập',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Cá nhân',
            ),
          ],
        ),
      ),
    );
  }

  // Placeholder cho Trang chủ (Màn 04 - do FE2 phụ trách)
  Widget _buildHomePlaceholder() {
    return Scaffold(
      appBar: AppBar(title: Text('Trang chủ', style: AppTypography.headingLarge)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.softBlueSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_fire_department_rounded, size: 64, color: AppColors.warningOrange),
            ),
            const SizedBox(height: 20),
            Text('Chào mừng bạn đến với KarVocab!', style: AppTypography.headingMedium),
            const SizedBox(height: 8),
            Text(
              'Chuyển sang tab "Thư viện" để bắt đầu khám phá từ vựng.',
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  // Placeholder cho Luyện tập (Màn 10 - do FE2 phụ trách)
  Widget _buildPracticePlaceholder() {
    return Scaffold(
      appBar: AppBar(title: Text('Luyện tập & Quiz', style: AppTypography.headingLarge)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.softBlueSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school_rounded, size: 64, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 20),
            Text('Khu vực Luyện tập (Quiz Engine)', style: AppTypography.headingMedium),
            const SizedBox(height: 8),
            Text(
              '4 Chế độ luyện tập đang được FE2 hoàn thiện.',
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
