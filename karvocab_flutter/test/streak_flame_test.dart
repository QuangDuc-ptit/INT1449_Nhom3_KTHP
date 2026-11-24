import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karvocab_flutter/core/widgets/streak_flame.dart';
import 'package:karvocab_flutter/presentation/home/home_sample_data.dart';
import 'package:karvocab_flutter/presentation/screens/home_screen.dart';

void main() {
  testWidgets('Ngọn lửa chuỗi: vẽ riêng thay icon Material, tắt (xám) khi chuỗi 0 ngày', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Row(children: [StreakFlame(size: 32), StreakFlame(size: 32, lit: false)]),
    ));
    expect(find.byKey(const Key('streak_flame')), findsNWidgets(2));
    expect(tester.getSize(find.byKey(const Key('streak_flame')).first), const Size(32, 32));
  });

  testWidgets('Trang chủ: thẻ Chuỗi ngày học dùng ngọn lửa mới, khung ôn tập không còn chữ phụ', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: HomeScreen(state: HomeSampleData.full))));
    expect(find.byType(StreakFlame), findsOneWidget);
    expect(tester.widget<StreakFlame>(find.byType(StreakFlame)).lit, isTrue);
    expect(find.byIcon(Icons.local_fire_department_outlined), findsNothing);
    expect(find.textContaining('phút'), findsNothing);
  });
}
