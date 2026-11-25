import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karvocab_flutter/presentation/screens/info_screen.dart';
import 'package:karvocab_flutter/presentation/screens/login_screen.dart';

void main() {
  testWidgets('Màn Hướng dẫn hiện đủ các mục', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: InfoScreen.help()));
    expect(find.text('Hướng dẫn & Trợ giúp'), findsOneWidget);
    expect(find.text(InfoScreen.helpSections.first.title), findsOneWidget);
  });

  testWidgets('Link Điều khoản ở Đăng nhập mở màn Điều khoản & Quyền riêng tư', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.ensureVisible(find.byKey(const Key('login_terms')));
    await tester.tap(find.byKey(const Key('login_terms')));
    await tester.pumpAndSettle();
    expect(find.byType(InfoScreen), findsOneWidget);
    expect(find.text('Điều khoản & Quyền riêng tư'), findsOneWidget);
  });
}
