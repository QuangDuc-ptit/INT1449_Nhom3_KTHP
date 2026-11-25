import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karvocab_flutter/presentation/screens/main_shell_screen.dart';
import 'package:karvocab_flutter/presentation/widgets/app_bottom_nav_bar.dart';

/// Nút Back của Android ở màn chính: tab khác → về Trang chủ, không thoát app.
void main() {
  testWidgets('Back ở tab Thư viện quay về Trang chủ thay vì thoát app', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: MainShellScreen(initialTabIndex: 1)));
    await tester.pump();
    int tab() => tester.widget<AppBottomNavBar>(find.byType(AppBottomNavBar)).currentIndex;
    expect(tab(), 1);

    final handled = await tester.binding.handlePopRoute();
    await tester.pump();
    expect(handled, isTrue, reason: 'App không được thoát khi đang ở tab khác Trang chủ');
    expect(tab(), 0);
    await tester.pump(const Duration(seconds: 1)); // chờ Thư viện tải xong (độ trễ giả lập)
  });
}
