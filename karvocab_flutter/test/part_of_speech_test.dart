import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karvocab_flutter/core/constants/part_of_speech.dart';
import 'package:karvocab_flutter/core/widgets/app_button.dart';
import 'package:karvocab_flutter/data/mock/mock_vocab_data.dart';
import 'package:karvocab_flutter/data/repositories/collection_store.dart';
import 'package:karvocab_flutter/presentation/screens/word_form_screen.dart';

void main() {
  group('Loại từ', () {
    test('Đủ 13 loại, key không trùng, giữ 5 key backend đang nhận', () {
      expect(PartOfSpeech.values.length, 13);
      expect(PartOfSpeech.values.map((p) => p.key).toSet().length, 13);
      for (final key in ['noun', 'verb', 'adj', 'adv', 'idiom']) {
        expect(PartOfSpeech.of(key), isNotNull, reason: key);
      }
    });

    test('Viết tắt trong ngoặc vuông; key lạ hiện nguyên key', () {
      expect(PartOfSpeech.bracket('noun'), '[n.]');
      expect(PartOfSpeech.bracket('phrasal_verb'), '[phr. v.]');
      expect(PartOfSpeech.bracket('abc'), '[abc]');
    });

    testWidgets('Màn 24: chọn "Cụm động từ (Phrasal Verb)" rồi lưu', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final store = CollectionStore(
        collections: MockVocabData.seedCollections(),
        vocabularies: MockVocabData.seedVocabularies(),
        latency: Duration.zero,
      );
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => WordFormScreen(collectionId: 'col-1', store: store)),
              ),
              child: const Text('Mở'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();

      // Thêm từ mới: chưa chọn sẵn từ loại.
      expect(find.text('Chọn từ loại'), findsOneWidget);

      await tester.tap(find.byKey(const Key('word_form_pos')));
      await tester.pumpAndSettle();
      // Menu chỉ dựng các mục đang hiện: cuộn tới mục cần chọn rồi mới bấm.
      final item = find.text('Cụm động từ (Phrasal Verb)');
      await tester.dragUntilVisible(item, find.byType(Scrollable).last, const Offset(0, -80));
      await tester.tap(item.last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'give up');
      await tester.enterText(find.byType(TextField).at(2), 'từ bỏ');
      await tester.tap(find.byKey(const Key('word_form_level')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('B1 · Trung cấp').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Lưu vào học phần'));
      await tester.pumpAndSettle();

      final saved = store.wordsOf('col-1').firstWhere((w) => w.term == 'give up');
      expect(saved.partOfSpeech, 'phrasal_verb');
    });
  });
}
