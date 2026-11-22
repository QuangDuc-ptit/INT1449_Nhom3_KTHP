import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karvocab_flutter/core/widgets/app_button.dart';
import 'package:karvocab_flutter/data/mock/mock_vocab_data.dart';
import 'package:karvocab_flutter/data/repositories/collection_store.dart';
import 'package:karvocab_flutter/presentation/screens/word_detail_screen.dart';
import 'package:karvocab_flutter/presentation/screens/word_form_screen.dart';

void main() {
  late CollectionStore store;

  Future<void> openDetail(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    store = CollectionStore(
      collections: MockVocabData.seedCollections(),
      vocabularies: MockVocabData.seedVocabularies(),
      latency: Duration.zero,
    );
    final word = store.wordsOf('col-1').firstWhere((w) => w.term == 'coherent');
    await tester.pumpWidget(MaterialApp(home: WordDetailScreen(vocabulary: word, store: store)));
  }

  group('Màn 07 ↔ Màn 09 · Chi tiết và Sửa từ', () {
    testWidgets('Chi tiết hiện nghĩa, ví dụ, đồng nghĩa / trái nghĩa và nút xoá', (tester) async {
      await openDetail(tester);
      expect(find.text('Chi tiết từ vựng'), findsOneWidget);
      expect(find.text('coherent'), findsOneWidget);
      expect(find.text('NGHĨA TIẾNG VIỆT'), findsOneWidget);
      expect(find.text('VÍ DỤ SỬ DỤNG'), findsOneWidget);
      expect(find.text('Từ đồng nghĩa'), findsOneWidget);
      expect(find.text('Từ trái nghĩa'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('word_detail_delete')));
      expect(find.text('Xóa từ vựng'), findsOneWidget);
    });

    testWidgets('Bút chì mở form đã điền sẵn; quay lại không lưu', (tester) async {
      await openDetail(tester);
      await tester.tap(find.byKey(const Key('word_detail_edit')));
      await tester.pumpAndSettle();
      expect(find.byType(WordFormScreen), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(2), 'nghĩa chưa lưu');
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();

      expect(find.byType(WordFormScreen), findsNothing);
      expect(find.text('nghĩa chưa lưu'), findsNothing);
      expect(store.wordsOf('col-1').firstWhere((w) => w.term == 'coherent').definitionVi, isNot('nghĩa chưa lưu'));
    });

    testWidgets('Lưu thay đổi → về chi tiết, hiện nội dung mới, giữ đồng nghĩa', (tester) async {
      await openDetail(tester);
      await tester.tap(find.byKey(const Key('word_detail_edit')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(2), 'mạch lạc, chặt chẽ');
      await tester.ensureVisible(find.widgetWithText(AppButton, 'Lưu thay đổi'));
      await tester.tap(find.widgetWithText(AppButton, 'Lưu thay đổi'));
      await tester.pumpAndSettle();

      expect(find.byType(WordFormScreen), findsNothing);
      expect(find.text('mạch lạc, chặt chẽ'), findsOneWidget);
      final saved = store.wordsOf('col-1').firstWhere((w) => w.term == 'coherent');
      expect(saved.synonyms, isNotEmpty);
    });

    testWidgets('Xoá từ cần xác nhận trước', (tester) async {
      await openDetail(tester);
      await tester.ensureVisible(find.byKey(const Key('word_detail_delete')));
      await tester.tap(find.byKey(const Key('word_detail_delete')));
      await tester.pumpAndSettle();
      expect(find.text('Xoá từ vựng này?'), findsOneWidget);
      await tester.tap(find.text('Huỷ'));
      await tester.pumpAndSettle();
      expect(store.wordsOf('col-1').any((w) => w.term == 'coherent'), isTrue);
    });
  });
}
