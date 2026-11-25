import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:karvocab_flutter/data/local/local_store.dart';
import 'package:karvocab_flutter/data/models/quiz_models.dart';
import 'package:karvocab_flutter/data/models/vocabulary_model.dart';
import 'package:karvocab_flutter/data/repositories/auth_repository.dart';
import 'package:karvocab_flutter/data/repositories/collection_store.dart';
import 'package:karvocab_flutter/data/repositories/dashboard_store.dart';
import 'package:karvocab_flutter/data/repositories/quiz_question_factory.dart';
import 'package:karvocab_flutter/data/repositories/track_sync.dart';

/// Mỗi tài khoản trên cùng một máy có dữ liệu học riêng.
void main() {
  VocabularyModel word(String term) => VocabularyModel(
    id: '',
    collectionId: '',
    term: term,
    partOfSpeech: 'noun',
    ipa: '',
    definitionVi: 'nghĩa $term',
    definitionEn: '',
    exampleSentence: '',
    cefrLevel: 'A1',
  );

  QuizSummary allCorrect(CollectionStore library) {
    final qs = QuizQuestionFactory.build(mode: QuizMode.meaningChoose, pool: library.allWords, count: library.totalWordCount);
    return QuizSummary(
      records: [
        for (final q in qs)
          QuizAnswerRecord(question: q, userAnswer: q.correctAnswer, result: AnswerResult.correct, responseTimeMs: 300),
      ],
      durationSeconds: 5,
      clientSessionId: 'phien-thu',
    );
  }

  test('Đăng nhập tài khoản khác không thấy học phần, tiến độ của tài khoản trước', () async {
    final disk = MemoryLocalStore();
    final auth = AuthRepository(latency: Duration.zero, random: Random(1), storage: disk);
    final library = CollectionStore(storage: disk, latency: Duration.zero, perUser: true);
    final dashboard = DashboardStore.forTest(collections: library, storage: disk, perUser: true);
    TrackSync.attach(auth: auth, dashboard: dashboard, collections: library);

    await auth.register(fullName: 'Nguyễn An', email: 'an@test.local', password: 'Matkhau123');
    final col = library.createCollection(title: 'Du lịch');
    library.addWords(col.id, [word('hotel'), word('ticket'), word('passport'), word('luggage')]);
    dashboard.recordSessionResult(allCorrect(library));
    expect(dashboard.streak, 1);

    auth.logout();
    expect(library.collections, isEmpty);
    expect(dashboard.streak, 0);

    await auth.register(fullName: 'Trần Bình', email: 'binh@test.local', password: 'Matkhau123');
    expect(library.collections, isEmpty);
    expect(library.totalWordCount, 0);
    expect(dashboard.streak, 0);
    expect(dashboard.reviewedToday, 0);

    // Quay lại tài khoản đầu: dữ liệu vẫn còn nguyên.
    auth.logout();
    await auth.login('AN@test.local', 'Matkhau123');
    expect(library.collections.single.title, 'Du lịch');
    expect(library.totalWordCount, 4);
    expect(dashboard.streak, 1);
    expect(dashboard.reviewedToday, 4);

    // Mở lại app (store mới trên cùng bộ nhớ) vẫn đúng dữ liệu của từng người.
    final reopened = CollectionStore(storage: disk, latency: Duration.zero, perUser: true);
    expect(reopened.collections, isEmpty); // chưa biết ai đăng nhập
    reopened.switchUser('binh@test.local');
    expect(reopened.collections, isEmpty);
    reopened.switchUser('an@test.local');
    expect(reopened.totalWordCount, 4);
  });

  test('Hoàn tác xoá từ trả từ về đúng vị trí cũ', () {
    final library = CollectionStore(latency: Duration.zero);
    final col = library.createCollection(title: 'Du lịch');
    for (final t in ['luggage', 'passport', 'ticket', 'hotel']) {
      library.addWord(word(t).copyWith(collectionId: col.id));
    }
    final before = library.wordsOf(col.id).map((w) => w.term).toList();
    final removed = library.deleteWord(library.wordsOf(col.id)[2].id)!;
    library.restoreWord(removed);
    expect(library.wordsOf(col.id).map((w) => w.term).toList(), before);
  });
}
