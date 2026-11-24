import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'fixtures/mock_vocab_data.dart';
import 'package:karvocab_flutter/data/repositories/collection_store.dart';
import 'package:karvocab_flutter/data/services/device_tts_service.dart';
import 'package:karvocab_flutter/data/services/pronunciation_service.dart';
import 'package:karvocab_flutter/data/services/speech_service.dart';
import 'package:karvocab_flutter/presentation/screens/word_form_screen.dart';

/// Ghi lại các từ được yêu cầu đọc thay vì phát tiếng thật.
class _RecordingSpeech implements SpeechService {
  final List<String> spoken = [];

  @override
  Future<void> speak(String text) async => spoken.add(text);
}

void main() {
  group('Phát âm từ vựng', () {
    late SpeechService original;
    late _RecordingSpeech speech;

    setUp(() {
      original = SpeechService.instance;
      speech = _RecordingSpeech();
      SpeechService.instance = speech;
    });
    tearDown(() => SpeechService.instance = original);

    test('Giọng UK đọc bằng en-GB, US bằng en-US', () {
      expect(DeviceTts.languageOf(Accent.uk), 'en-GB');
      expect(DeviceTts.languageOf(Accent.us), 'en-US');
    });

    testWidgets('Màn 24: nút nghe thử phát âm tắt khi chưa gõ, gõ xong thì đọc đúng từ', (tester) async {
      final store = CollectionStore(
        collections: MockVocabData.seedCollections(),
        vocabularies: MockVocabData.seedVocabularies(),
        latency: Duration.zero,
      );
      await tester.pumpWidget(MaterialApp(home: WordFormScreen(collectionId: 'col-1', store: store)));

      final listen = find.byKey(const Key('word_form_listen'));
      expect(tester.widget<IconButton>(listen).onPressed, isNull);
      expect(tester.getSize(listen).height, greaterThanOrEqualTo(48));

      await tester.enterText(find.byType(TextField).first, '  resilient ');
      await tester.pump();
      await tester.tap(listen);
      await tester.pump();

      expect(speech.spoken, ['resilient']);
    });
  });
}
