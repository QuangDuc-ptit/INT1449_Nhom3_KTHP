import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karvocab_flutter/core/constants/app_strings.dart';
import 'package:karvocab_flutter/data/mock/mock_ai_vocab_bank.dart';
import 'package:karvocab_flutter/data/repositories/ai_vocab_repository.dart';
import 'package:karvocab_flutter/presentation/ai_vocab/ai_generate_screen.dart';
import 'package:karvocab_flutter/presentation/ai_vocab/ai_preview_screen.dart';

void main() {
  final repo = MockAiVocabRepository(latency: Duration.zero, random: Random(1));
  Set<String> termsOf(String topicName) =>
      MockAiVocabBank.topics.firstWhere((t) => t.name == topicName).words.map((w) => w.term).toSet();

  group('Màn 13 · Nhận diện chủ đề', () {
    test('Tiếng Việt có dấu, không dấu và tiếng Anh đều nhận ra', () {
      expect(MockAiVocabBank.match('Du lịch').map((t) => t.name), ['Du lịch']);
      expect(MockAiVocabBank.match('du lich bui').map((t) => t.name), ['Du lịch']);
      expect(MockAiVocabBank.match('Travel & Airport').map((t) => t.name), ['Du lịch']);
      expect(MockAiVocabBank.match('Công nghệ thông tin').map((t) => t.name), ['Công nghệ']);
      expect(MockAiVocabBank.match('Ẩm thực & cà phê').map((t) => t.name), ['Ẩm thực & đồ uống']);
      expect(MockAiVocabBank.match('Sức khoẻ').map((t) => t.name), ['Sức khoẻ']);
      expect(MockAiVocabBank.match('Sức khỏe').map((t) => t.name), ['Sức khoẻ']);
    });

    test('Không khớp nhầm theo một phần của từ', () {
      // "tech" không được khớp trong "technique"; "cafe" không khớp trong "cafeteria"
      expect(MockAiVocabBank.match('technique'), isEmpty);
      expect(MockAiVocabBank.match('cafeteria'), isEmpty);
    });
  });

  group('Màn 13 · Từ sinh ra', () {
    test('Chủ đề tiếng Việt, không chọn cấp độ: toàn bộ từ thuộc đúng chủ đề', () async {
      final drafts = await repo.generate(topic: 'Môi trường', wordCount: 5);
      expect(drafts, hasLength(5));
      expect(termsOf('Môi trường'), containsAll(drafts.map((d) => d.term)));
    });

    test('Số lượng lớn hơn kho: chỉ trả từ đúng chủ đề, không chèn từ chủ đề khác', () async {
      final drafts = await repo.generate(topic: 'Thể thao', wordCount: 20);
      expect(drafts.length, termsOf('Thể thao').length);
      expect(termsOf('Thể thao'), containsAll(drafts.map((d) => d.term)));
    });

    test('Nhãn CEFR là trình độ thật của từ; chọn cấp thì ưu tiên đúng cấp, tối đa lệch 1 cấp', () async {
      final bank = {
        for (final t in MockAiVocabBank.topics)
          for (final w in t.words) w.term: w.cefrLevel,
      };
      final drafts = await repo.generate(topic: 'Business', cefrLevel: 'B2', wordCount: 5);
      for (final d in drafts) {
        expect(d.cefrLevel, bank[d.term]);
        expect(['B1', 'B2', 'C1'], contains(d.cefrLevel));
      }
      // Kho "Công việc" có 3 từ B2 → 3 từ đầu đều là B2
      expect(drafts.take(3).map((d) => d.cefrLevel), everyElement('B2'));
    });

    test('Hai chủ đề trong một câu: lấy xen kẽ từ cả hai', () async {
      final drafts = await repo.generate(topic: 'Du lịch và ẩm thực', wordCount: 6);
      final terms = drafts.map((d) => d.term).toSet();
      expect(terms.intersection(termsOf('Du lịch')), hasLength(3));
      expect(terms.intersection(termsOf('Ẩm thực & đồ uống')), hasLength(3));
    });

    test('Chủ đề chưa có trong kho Demo → lỗi TOPIC_UNSUPPORTED, thông báo gợi ý chủ đề có sẵn', () async {
      await expectLater(
        repo.generate(topic: 'Quantum physics', wordCount: 5),
        throwsA(isA<AiVocabException>().having((e) => e.errorCode, 'errorCode', 'TOPIC_UNSUPPORTED')),
      );
      expect(
        AiGenerateScreen.aiErrorMessage(const AiVocabException('TOPIC_UNSUPPORTED')),
        allOf(contains('Du lịch'), contains('Công nghệ')),
      );
    });
  });

  testWidgets('Màn 13 · Không còn chọn CEFR; kéo thanh để đổi số lượng 3–20 rồi tạo từ', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: AiGenerateScreen(repository: repo)));

    expect(find.text('B2'), findsNothing);
    expect(find.byIcon(Icons.add_rounded), findsNothing);
    final slider = find.byKey(const Key('ai_word_count_slider'));
    expect(tester.widget<Slider>(slider).value, 5);
    expect(tester.getSize(slider).height, greaterThanOrEqualTo(48));

    await tester.drag(slider, const Offset(-1000, 0)); // kéo hết về trái
    await tester.pump();
    expect(find.text(AppStrings.aiWordCountValue(3)), findsOneWidget);
    await tester.drag(slider, const Offset(1000, 0)); // kéo hết về phải
    await tester.pump();
    expect(find.text(AppStrings.aiWordCountValue(20)), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Giáo dục');
    await tester.pump();
    await tester.tap(find.text('Tạo từ vựng ngay'));
    await tester.pump();
    expect(find.text(AppStrings.aiLoadingSubtitle(20)), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.byType(AiPreviewScreen), findsOneWidget);
    final preview = tester.widget<AiPreviewScreen>(find.byType(AiPreviewScreen));
    expect(termsOf('Giáo dục'), containsAll(preview.drafts.map((d) => d.term)));
  });
}
