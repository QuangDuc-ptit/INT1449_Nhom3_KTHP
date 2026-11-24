import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karvocab_flutter/core/constants/app_strings.dart';
import 'package:karvocab_flutter/core/widgets/app_button.dart';
import 'package:karvocab_flutter/data/repositories/auth_repository.dart';
import 'package:karvocab_flutter/data/mock/mock_vocab_data.dart';
import 'package:karvocab_flutter/data/repositories/collection_store.dart';
import 'package:karvocab_flutter/presentation/screens/library_screen.dart';
import 'package:karvocab_flutter/presentation/screens/login_screen.dart';
import 'package:karvocab_flutter/presentation/screens/word_detail_screen.dart';
import 'package:karvocab_flutter/presentation/screens/word_form_screen.dart';
import 'package:karvocab_flutter/presentation/widgets/collection_form_sheet.dart';
import 'package:karvocab_flutter/presentation/widgets/delete_word_dialog.dart';

CollectionStore _freshStore() => CollectionStore(
      collections: MockVocabData.seedCollections(),
      vocabularies: MockVocabData.seedVocabularies(),
      latency: Duration.zero,
    );

Widget _app(Widget home) => MaterialApp(home: home);

/// Màn hình có 1 nút mở [builder] — để kiểm thử các màn `pop` trả kết quả.
Widget _launcher(Widget Function() builder) {
  return MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => builder())),
            child: const Text('Mở'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('Màn 02 · Đăng nhập', () {
    testWidgets('Icon con mắt ẩn/hiện mật khẩu', (tester) async {
      await tester.pumpWidget(_app(const LoginScreen()));

      TextField passwordField() => tester.widget<TextField>(find.byType(TextField).at(1));
      expect(passwordField().obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();
      expect(passwordField().obscureText, isFalse);

      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();
      expect(passwordField().obscureText, isTrue);
    });
  });

  group('Màn 02 · Đăng nhập (bố cục)', () {
    testWidgets('Placeholder mật khẩu và dòng "Đăng ký ngay." căn giữa', (tester) async {
      await tester.pumpWidget(_app(const LoginScreen()));

      expect(find.text('Nhập mật khẩu của bạn'), findsOneWidget);

      final screenCenter = tester.getSize(find.byType(Scaffold)).width / 2;
      final line = find.ancestor(of: find.text('Đăng ký ngay.'), matching: find.byType(Wrap));
      final lineRect = tester.getRect(find.descendant(of: line, matching: find.byType(Text)).first)
          .expandToInclude(tester.getRect(find.text('Đăng ký ngay.')));
      expect(lineRect.center.dx, moreOrLessEquals(screenCenter, epsilon: 1));

      await tester.tap(find.descendant(of: find.byType(AuthSegmentTabs), matching: find.text('Đăng ký')));
      await tester.pump();
      expect(find.text('Nhập mật khẩu của bạn'), findsOneWidget);
      expect(find.text('Nhập lại mật khẩu của bạn'), findsOneWidget);
    });
  });

  group('Màn 03 · Đăng ký', () {
    testWidgets('Thanh tab chuyển qua lại giữa form Đăng ký và Đăng nhập', (tester) async {
      await tester.pumpWidget(_app(const LoginScreen()));
      final tabs = find.byType(AuthSegmentTabs);

      await tester.tap(find.descendant(of: tabs, matching: find.text('Đăng ký')));
      await tester.pump();
      // Họ và tên, Email, Ngày sinh, Mật khẩu, Xác nhận mật khẩu.
      expect(find.byType(TextField), findsNWidgets(5));
      expect(find.text('Họ và tên'), findsOneWidget);
      expect(find.text('Ngày sinh'), findsOneWidget);
      expect(find.text('Xác nhận mật khẩu'), findsOneWidget);
      // Ô Xác nhận mật khẩu cũng nhập dạng ẩn
      expect(tester.widget<TextField>(find.byType(TextField).at(4)).obscureText, isTrue);

      await tester.tap(find.descendant(of: tabs, matching: find.text('Đăng nhập')));
      await tester.pump();
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Chào mừng trở lại'), findsOneWidget);
    });
  });

  group('Màn 03 · Đăng ký có họ tên, nút mạng xã hội hoạt động', () {
    testWidgets('Bỏ trống họ tên thì báo lỗi dưới ô Họ và tên', (tester) async {
      await tester.pumpWidget(_app(LoginScreen(initialTab: 1, authRepository: AuthRepository(latency: Duration.zero))));
      await tester.ensureVisible(find.widgetWithText(AppButton, AppStrings.registerButton));
      await tester.tap(find.widgetWithText(AppButton, AppStrings.registerButton));
      await tester.pump();
      expect(find.text('Vui lòng nhập họ và tên'), findsOneWidget);
    });

    testWidgets('Bấm Google thì đăng nhập bằng tài khoản Google (không còn là nút chết)', (tester) async {
      final auth = AuthRepository(latency: Duration.zero);
      await tester.pumpWidget(_app(LoginScreen(authRepository: auth)));
      await tester.ensureVisible(find.byKey(const Key('auth_google')));
      await tester.tap(find.byKey(const Key('auth_google')));
      await tester.pump(const Duration(milliseconds: 10));
      expect(auth.currentUser?.fullName, 'Người dùng Google');
      // Đã sang Trang chủ: gỡ cây widget và chạy hết timer của các màn
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });
  });

  group('Màn 05 · Thư viện học phần', () {
    testWidgets('Hiển thị danh sách sau khi tải và tìm kiếm có debounce 300ms', (tester) async {
      final store = _freshStore();
      await tester.pumpWidget(_app(LibraryScreen(store: store)));
      await tester.pump(); // post-frame → load()
      // pump() không thời lượng không chạy timer Future.delayed(zero) → cho đồng hồ chạy 1ms.
      await tester.pump(const Duration(milliseconds: 1));

      expect(find.text('Học thuật & IELTS Core'), findsOneWidget);
      expect(find.text('Tiếng Anh Du lịch & Trải nghiệm'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'sân bay');
      await tester.pump(const Duration(milliseconds: 100));
      // Chưa hết 300ms: danh sách chưa bị lọc
      expect(find.text('Học thuật & IELTS Core'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Học thuật & IELTS Core'), findsNothing);
      expect(find.text('Tiếng Anh Du lịch & Trải nghiệm'), findsOneWidget);
    });

    testWidgets('Error State có nút Thử lại đưa về danh sách', (tester) async {
      final store = _freshStore()..simulateNetworkError = true;
      await tester.pumpWidget(_app(LibraryScreen(store: store)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      expect(find.text('Không tải được thư viện'), findsOneWidget);
      await tester.tap(find.text('Thử lại ngay'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      expect(find.text('Không tải được thư viện'), findsNothing);
      expect(find.text('Học thuật & IELTS Core'), findsOneWidget);
    });
  });

  group('Màn 22 · Tạo học phần', () {
    testWidgets('Báo lỗi khi tên quá ngắn hoặc trùng tên đã có', (tester) async {
      final store = _freshStore();
      await tester.pumpWidget(_app(Scaffold(body: CollectionFormSheet(store: store))));

      await tester.enterText(find.byType(TextField).first, 'A');
      await tester.tap(find.widgetWithText(AppButton, 'Tạo học phần'));
      await tester.pump();
      expect(find.text('Tên học phần cần ít nhất 2 ký tự'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'học thuật & ielts core');
      await tester.tap(find.widgetWithText(AppButton, 'Tạo học phần'));
      await tester.pump();
      expect(find.textContaining('Bạn đã có học phần tên'), findsOneWidget);
      expect(store.collections.length, 3);
    });
  });

  group('Màn 24 · Thêm từ vựng', () {
    testWidgets('Bắt buộc từ tiếng Anh & nghĩa tiếng Việt; chặn trùng từ', (tester) async {
      final store = _freshStore();
      await tester.pumpWidget(_app(WordFormScreen(collectionId: 'col-1', store: store)));

      await tester.ensureVisible(find.widgetWithText(AppButton, 'Lưu vào học phần'));
      await tester.tap(find.widgetWithText(AppButton, 'Lưu vào học phần'));
      await tester.pump();
      expect(find.text('Vui lòng nhập từ tiếng Anh'), findsOneWidget);
      expect(find.text('Vui lòng nhập nghĩa tiếng Việt'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'Coherent');
      await tester.enterText(find.byType(TextField).at(2), 'mạch lạc');
      await tester.ensureVisible(find.widgetWithText(AppButton, 'Lưu vào học phần'));
      await tester.tap(find.widgetWithText(AppButton, 'Lưu vào học phần'));
      await tester.pump();
      expect(find.text('Từ "Coherent" đã có trong học phần này'), findsOneWidget);
    });

    testWidgets('Lưu hợp lệ → thêm vào store, chuẩn hoá IPA và quay lại màn trước', (tester) async {
      final store = _freshStore();
      await tester.pumpWidget(_launcher(() => WordFormScreen(collectionId: 'col-1', store: store)));
      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'resilient');
      await tester.enterText(find.byType(TextField).at(1), 'rɪˈzɪliənt');
      await tester.enterText(find.byType(TextField).at(2), 'kiên cường');
      await tester.ensureVisible(find.widgetWithText(AppButton, 'Lưu vào học phần'));
      await tester.tap(find.widgetWithText(AppButton, 'Lưu vào học phần'));
      await tester.pumpAndSettle();

      expect(find.byType(WordFormScreen), findsNothing);
      final words = store.wordsOf('col-1');
      expect(words.length, 6);
      expect(words.first.term, 'resilient');
      expect(words.first.ipa, '/rɪˈzɪliənt/');
      expect(store.findCollection('col-1')!.totalWords, 6);
    });
  });

  group('Màn 07 & 28 · Chi tiết & Xoá từ', () {
    testWidgets('Dialog xác nhận xoá trả về true khi bấm "Xoá từ", false khi Huỷ', (tester) async {
      final results = <bool>[];
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async => results.add(await showDeleteWordDialog(context, 'coherent')),
              child: const Text('Xoá'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Xoá'));
      await tester.pumpAndSettle();
      expect(find.text('Xoá từ vựng này?'), findsOneWidget);
      await tester.tap(find.text('Huỷ'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xoá'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xoá từ'));
      await tester.pumpAndSettle();

      expect(results, [false, true]);
    });

    testWidgets('Câu ví dụ in đậm từ khoá, kể cả biến thể có hậu tố', (tester) async {
      await tester.pumpWidget(_app(const Scaffold(
        body: HighlightedSentence(sentence: 'We explored the island.', keyword: 'explore'),
      )));

      final richText = tester.widget<RichText>(find.byType(RichText).first);
      final bold = <String>[];
      richText.text.visitChildren((span) {
        if (span is TextSpan && span.text != null && span.style?.fontWeight == FontWeight.w800) {
          bold.add(span.text!);
        }
        return true;
      });
      expect(bold, ['explored']);
    });
  });
}
