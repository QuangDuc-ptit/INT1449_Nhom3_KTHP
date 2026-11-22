import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karvocab_flutter/core/widgets/app_button.dart';
import 'package:karvocab_flutter/data/mock/mock_vocab_data.dart';
import 'package:karvocab_flutter/data/repositories/collection_store.dart';
import 'package:karvocab_flutter/presentation/screens/word_form_screen.dart';
import 'package:karvocab_flutter/presentation/widgets/tag_input_field.dart';

void main() {
  group('Ô nhập dạng thẻ', () {
    test('Tách theo dấu cách / dấu phẩy, bỏ từ trùng', () {
      expect(TagInputField.merge(const [], 'logical, consistent'), ['logical', 'consistent']);
      expect(TagInputField.merge(const ['logical'], 'Logical clear'), ['logical', 'clear']);
      expect(TagInputField.merge(const [], '  ,  '), isEmpty);
    });

    Finder antonymInput() =>
        find.descendant(of: find.byKey(const Key('word_form_antonyms')), matching: find.byType(TextField));

    late CollectionStore store;

    Future<void> openEdit(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      store = CollectionStore(
        collections: MockVocabData.seedCollections(),
        vocabularies: MockVocabData.seedVocabularies(),
        latency: Duration.zero,
      );
      final word = store.wordsOf('col-1').firstWhere((w) => w.term == 'coherent');
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => WordFormScreen(collectionId: 'col-1', initialWord: word, store: store),
              )),
              child: const Text('Mở'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
    }

    Set<String> savedAntonyms() => store.wordsOf('col-1').firstWhere((w) => w.term == 'coherent').antonyms.toSet();

    testWidgets('Gõ từ rồi nhấn cách thì thành thẻ; bấm × thì xoá', (tester) async {
      await openEdit(tester);
      final before = savedAntonyms();

      await tester.enterText(antonymInput(), 'chaotic ');
      await tester.pump();
      expect(find.text('chaotic'), findsOneWidget);
      expect(tester.widget<TextField>(antonymInput()).controller!.text, isEmpty);

      await tester.tap(find.bySemanticsLabel('Xoá "chaotic"'));
      await tester.pump();
      expect(find.text('chaotic'), findsNothing);

      // Chữ đang gõ dở (chưa nhấn cách) vẫn được lưu khi bấm Lưu thay đổi.
      await tester.enterText(antonymInput(), 'muddled');
      await tester.ensureVisible(find.widgetWithText(AppButton, 'Lưu thay đổi'));
      await tester.tap(find.widgetWithText(AppButton, 'Lưu thay đổi'));
      await tester.pumpAndSettle();

      expect(savedAntonyms(), {...before, 'muddled'});
    });
  });
}
