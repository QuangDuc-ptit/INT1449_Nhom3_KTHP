import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'fixtures/mock_vocab_data.dart';
import 'package:karvocab_flutter/data/repositories/auth_repository.dart';
import 'package:karvocab_flutter/data/repositories/collection_store.dart';
import 'package:karvocab_flutter/presentation/screens/profile_screen.dart';
import 'package:karvocab_flutter/presentation/screens/settings_screen.dart';

/// Các thẻ chứa ListTile phải là Material, không phải Container có màu nền —
/// nếu không Flutter báo "ListTile background color or ink splashes may be invisible".
void main() {
  testWidgets('Màn 15 · Hồ sơ: ListTile không bị nền Container che hiệu ứng bấm', (tester) async {
    final store = CollectionStore(
      collections: MockVocabData.seedCollections(),
      vocabularies: MockVocabData.seedVocabularies(),
      latency: Duration.zero,
    );
    await tester.pumpWidget(MaterialApp(
      home: ProfileScreen(authRepository: AuthRepository(latency: Duration.zero), store: store),
    ));
    await tester.pump();

    expect(find.byType(ListTile), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Màn 23 · Cài đặt: ListTile không bị nền Container che hiệu ứng bấm', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SettingsScreen(authRepository: AuthRepository(latency: Duration.zero)),
    ));
    await tester.pump();

    expect(find.byType(ListTile), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Màn 23 · Cài đặt: không còn dòng Ngày sinh (chỉ sửa ở Hồ sơ)', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SettingsScreen(authRepository: AuthRepository(latency: Duration.zero)),
    ));
    await tester.pump();

    expect(find.byKey(const Key('settings_birth_date')), findsNothing);
    expect(find.text('Đổi mật khẩu'), findsOneWidget);
  });
}
