import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karvocab_flutter/core/utils/member_id.dart';
import 'package:karvocab_flutter/data/mock/mock_vocab_data.dart';
import 'package:karvocab_flutter/data/models/account_plan.dart';
import 'package:karvocab_flutter/data/repositories/auth_repository.dart';
import 'package:karvocab_flutter/data/repositories/collection_store.dart';
import 'package:karvocab_flutter/presentation/ai_vocab/ai_generate_screen.dart';
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
      expect(user.plan, AccountPlan.standard);

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

  group('Hạn mức loại tài khoản', () {
    test('Thường: 3 lượt AI mỗi ngày, sang ngày mới thì có lại', () async {
      var now = DateTime(2026, 11, 22, 9);
      final auth = AuthRepository(latency: Duration.zero, clock: () => now);
      await auth.register(fullName: 'C', email: 'c@test.com', password: 'Hocvien123');

      expect(auth.aiRemainingToday, 3);
      for (var i = 0; i < 3; i++) {
        auth.recordAiGeneration();
      }
      expect(auth.aiRemainingToday, 0);

      now = DateTime(2026, 11, 23, 8);
      expect(auth.aiRemainingToday, 3);
    });

    test('Thường: tối đa 500 từ; Vip không giới hạn', () async {
      final auth = AuthRepository(latency: Duration.zero);
      await auth.register(fullName: 'D', email: 'd@test.com', password: 'Hocvien123');
      expect(auth.wordLimitError(currentTotal: 499, adding: 1), isNull);
      expect(auth.wordLimitError(currentTotal: 500, adding: 1), contains('tối đa 500 từ'));
      expect(auth.wordLimitError(currentTotal: 495, adding: 10), contains('còn lưu được 5 từ'));

      await auth.login(AuthRepository.testEmail, AuthRepository.testPassword);
      expect(auth.activePlan, AccountPlan.vip);
      expect(auth.aiRemainingToday, isNull);
      expect(auth.wordLimitError(currentTotal: 100000, adding: 50), isNull);
    });

    test('Plus hết 1 tháng dùng thử thì quay về Thường', () async {
      var now = DateTime(2026, 11, 22);
      final auth = AuthRepository(latency: Duration.zero, clock: () => now);
      await auth.login(AuthRepository.demoEmail, AuthRepository.demoPassword);
      expect(auth.activePlan, AccountPlan.plus);
      expect(auth.aiRemainingToday, 10);

      now = DateTime(2026, 12, 23);
      expect(auth.activePlan, AccountPlan.standard);
      expect(auth.aiRemainingToday, 3);
    });

    testWidgets('Màn 13: hết lượt AI trong ngày thì báo lỗi, không gọi AI', (tester) async {
      final auth = AuthRepository(latency: Duration.zero);
      // Repository dùng Future.delayed: chạy bằng đồng hồ thật, không phải đồng hồ giả của testWidgets.
      await tester.runAsync(() => auth.register(fullName: 'E', email: 'e@test.com', password: 'Hocvien123'));
      for (var i = 0; i < 3; i++) {
        auth.recordAiGeneration();
      }
      await tester.pumpWidget(MaterialApp(home: AiGenerateScreen(authRepository: auth)));
      expect(find.text('Còn 0/3 lượt tạo từ bằng AI hôm nay'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Travel');
      await tester.pump();
      await tester.tap(find.text('Tạo từ vựng ngay'));
      await tester.pump();
      expect(find.textContaining('Bạn đã dùng hết 3 lượt'), findsOneWidget);
    });
  });

  testWidgets('Màn 15: hiện mã ID, email, ngày sinh DD/MM/YYYY và loại tài khoản', (tester) async {
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
    expect(find.text('Plus'), findsNWidgets(2)); // dưới tên và ở dòng Loại tài khoản
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget); // email chỉ xem
    expect(find.text('Thành tựu'), findsOneWidget);
  });
}
