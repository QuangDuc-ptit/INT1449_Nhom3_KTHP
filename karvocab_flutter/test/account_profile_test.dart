import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karvocab_flutter/core/utils/member_id.dart';
import 'package:karvocab_flutter/data/mock/mock_vocab_data.dart';
import 'package:karvocab_flutter/data/repositories/auth_repository.dart';
import 'package:karvocab_flutter/data/repositories/collection_store.dart';
import 'package:karvocab_flutter/presentation/screens/profile_screen.dart';

void main() {
  group('Mã ID người dùng', () {
    final birth = DateTime(2005, 9, 20);

    test('KM + YYMMDD + số thứ tự, cùng ngày sinh thì tăng dần', () {
      expect(MemberId.generate(birth, const []), 'KM05092000');
      expect(MemberId.generate(birth, const ['KM05092000']), 'KM05092001');
    });

    test('Quá 99 người cùng ngày sinh thì số thứ tự thành 3 chữ số', () {
      final taken = [for (var i = 0; i < 100; i++) 'KM050920${i.toString().padLeft(2, '0')}'];
      expect(MemberId.generate(birth, taken), 'KM050920100');
    });

    test('Đăng ký cấp mã theo ngày sinh; sửa ngày sinh thì mã giữ nguyên', () async {
      final auth = AuthRepository(latency: Duration.zero);
      // Tài khoản demo đã giữ KM05092000.
      final user = await auth.register(
        fullName: 'B', email: 'b@test.com', password: 'Hocvien123', birthDate: birth,
      );
      expect(user.memberId, 'KM05092001');

      auth.updateBirthDate(DateTime(2004, 1, 2));
      expect(auth.currentUser!.memberId, 'KM05092001');
      expect(auth.currentUser!.birthDate, DateTime(2004, 1, 2));
    });

    test('Google chưa có ngày sinh thì chưa có mã; bổ sung ngày sinh thì được cấp', () async {
      final auth = AuthRepository(latency: Duration.zero);
      await auth.loginWithSocial(SocialProvider.google);
      expect(auth.currentUser!.memberId, isNull);

      auth.updateBirthDate(DateTime(1999, 12, 31));
      expect(auth.currentUser!.memberId, 'KM99123100');
    });
  });

  testWidgets('Màn 15: hiện mã ID, email và ngày sinh DD/MM/YYYY', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final auth = AuthRepository(latency: Duration.zero);
    await tester.runAsync(() => auth.login(AuthRepository.demoEmail, AuthRepository.demoPassword));
    final store = CollectionStore(
      collections: MockVocabData.seedCollections(),
      vocabularies: MockVocabData.seedVocabularies(),
      latency: Duration.zero,
    );
    await tester.pumpWidget(MaterialApp(home: ProfileScreen(authRepository: auth, store: store)));

    expect(find.text('KM05092000'), findsOneWidget);
    expect(find.text(AuthRepository.demoEmail), findsOneWidget);
    expect(find.text('20/09/2005'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget); // email chỉ xem
    expect(find.text('Thành tựu'), findsOneWidget);
  });
}
