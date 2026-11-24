import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karvocab_flutter/core/widgets/app_button.dart';
import 'fixtures/mock_vocab_data.dart';
import 'package:karvocab_flutter/data/repositories/collection_store.dart';
import 'package:karvocab_flutter/presentation/screens/word_form_screen.dart';

void main() {
  testWidgets('Màn 09: sửa từ hiện dữ liệu đã điền, lưu ghi chú và giữ các trường ẩn', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = CollectionStore(
      collections: MockVocabData.seedCollections(),
      vocabularies: MockVocabData.seedVocabularies(),
      latency: Duration.zero,
    );
    final word = store.wordsOf('col-1').firstWhere((w) => w.term == 'coherent');
    await tester.pumpWidget(MaterialApp(
      home: WordFormScreen(collectionId: 'col-1', initialWord: word, store: store),
    ));

    expect(find.text('Sửa từ vựng'), findsOneWidget);
    expect(find.text(store.findCollection('col-1')!.title), findsNothing); // không còn dòng phụ dưới tiêu đề
    expect(find.text('Tính từ'), findsOneWidget);
    expect(find.text('B2 · Trên trung cấp'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'Gợi nhớ: co + here');
    final save = find.widgetWithText(AppButton, 'Lưu thay đổi');
    await tester.ensureVisible(save);
    expect(tester.getSize(save).height, greaterThanOrEqualTo(48));
    await tester.tap(save);
    await tester.pumpAndSettle();

    final saved = store.wordsOf('col-1').firstWhere((w) => w.id == word.id);
    expect(saved.note, 'Gợi nhớ: co + here');
    expect(saved.definitionEn, word.definitionEn);
    expect(saved.synonyms, word.synonyms);
  });
}
