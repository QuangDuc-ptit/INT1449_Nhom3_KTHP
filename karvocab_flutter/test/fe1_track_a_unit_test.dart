import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:karvocab_flutter/core/utils/validators.dart';
import 'fixtures/mock_vocab_data.dart';
import 'package:karvocab_flutter/data/models/vocabulary_model.dart';
import 'package:karvocab_flutter/data/repositories/auth_repository.dart';
import 'package:karvocab_flutter/data/repositories/collection_store.dart';
import 'package:karvocab_flutter/data/services/pronunciation_service.dart';
import 'package:karvocab_flutter/data/services/reminder_service.dart';

CollectionStore _freshStore() => CollectionStore(
      collections: MockVocabData.seedCollections(),
      vocabularies: MockVocabData.seedVocabularies(),
      latency: Duration.zero,
    );

VocabularyModel _word({String id = '', String collectionId = 'col-1', String term = 'resilient'}) {
  return VocabularyModel(
    id: id,
    collectionId: collectionId,
    term: term,
    partOfSpeech: 'adj',
    ipa: '/rɪˈzɪliənt/',
    definitionVi: 'kiên cường',
    definitionEn: 'Able to recover quickly.',
    exampleSentence: 'Children are resilient.',
    cefrLevel: 'B2',
  );
}

void main() {
  group('Validators (Màn 02, 03, 21, 22, 24)', () {
    test('email: chấp nhận email hợp lệ, từ chối email sai định dạng', () {
      expect(Validators.email('user@gmail.com'), isNull);
      expect(Validators.email('  a.b@school.edu.vn '), isNull);
      expect(Validators.email(''), 'Vui lòng nhập địa chỉ email');
      expect(Validators.email('user@gmail'), isNotNull);
      expect(Validators.email('user gmail.com'), isNotNull);
    });

    test('loginPassword: tối thiểu 6 ký tự', () {
      expect(Validators.loginPassword(''), 'Vui lòng nhập mật khẩu');
      expect(Validators.loginPassword('12345'), isNotNull);
      expect(Validators.loginPassword('123456'), isNull);
    });

    test('strongPassword: ≥ 8 ký tự, có chữ hoa và chữ số', () {
      expect(Validators.strongPassword('Abc123'), 'Mật khẩu phải có ít nhất 8 ký tự');
      expect(Validators.strongPassword('abcdefg1'), 'Mật khẩu cần ít nhất 1 chữ hoa');
      expect(Validators.strongPassword('Abcdefgh'), 'Mật khẩu cần ít nhất 1 chữ số');
      expect(Validators.strongPassword('Karvocab1'), isNull);
    });

    test('confirmPassword: phải khớp 100%', () {
      expect(Validators.confirmPassword('Karvocab1', 'Karvocab1'), isNull);
      expect(Validators.confirmPassword('karvocab1', 'Karvocab1'), 'Mật khẩu xác nhận không khớp');
      expect(Validators.confirmPassword('', 'Karvocab1'), isNotNull);
    });

    test('collectionTitle: giới hạn 2 – 50 ký tự', () {
      expect(Validators.collectionTitle(' '), 'Vui lòng nhập tên học phần');
      expect(Validators.collectionTitle('A'), 'Tên học phần cần ít nhất 2 ký tự');
      expect(Validators.collectionTitle('AB'), isNull);
      expect(Validators.collectionTitle('A' * 50), isNull);
      expect(Validators.collectionTitle('A' * 51), 'Tên học phần tối đa 50 ký tự');
    });

    test('otp: đúng 6 chữ số', () {
      expect(Validators.otp('123456'), isNull);
      expect(Validators.otp('12345'), isNotNull);
      expect(Validators.otp('12a456'), isNotNull);
    });

    test('term: chỉ gồm chữ cái, khoảng trắng, gạch nối, nháy đơn', () {
      expect(Validators.term('well-being'), isNull);
      expect(Validators.term("o'clock"), isNull);
      expect(Validators.term('look up'), isNull);
      expect(Validators.term(''), 'Vui lòng nhập từ tiếng Anh');
      expect(Validators.term('h3llo'), isNotNull);
    });
  });

  group('CollectionStore (Thư viện — Track A)', () {
    test('load(): chuyển Loading → Ready và đồng bộ số từ mỗi học phần', () async {
      final store = _freshStore();
      expect(store.status, LoadStatus.initial);
      final future = store.load();
      expect(store.status, LoadStatus.loading);
      await future;
      expect(store.status, LoadStatus.ready);
      expect(store.findCollection('col-1')!.totalWords, 5);
    });

    test('load(): giả lập lỗi mạng → Error, thử lại → Ready', () async {
      final store = _freshStore()..simulateNetworkError = true;
      await store.load();
      expect(store.status, LoadStatus.error);
      expect(store.errorMessage, isNotNull);
      await store.load();
      expect(store.status, LoadStatus.ready);
    });

    test('createCollection: thêm lên đầu, chặn trùng tên (không phân biệt hoa thường)', () {
      final store = _freshStore();
      final created = store.createCollection(title: '  Marketing B2 ', category: 'career');
      expect(store.collections.first.id, created.id);
      expect(created.title, 'Marketing B2');
      expect(created.iconName, 'work_outline_rounded');
      expect(() => store.createCollection(title: 'marketing b2'), throwsArgumentError);
    });

    test('search: lọc theo chủ đề và từ khoá trong tên/mô tả', () {
      final store = _freshStore();
      expect(store.search(category: 'travel').map((c) => c.id), ['col-2']);
      expect(store.search(query: 'SÂN BAY').map((c) => c.id), ['col-2']);
      expect(store.search(query: 'ielts', category: 'travel'), isEmpty);
      expect(store.search().length, 3);
    });

    test('addWord / deleteWord / restoreWord cập nhật totalWords', () {
      final store = _freshStore();
      final saved = store.addWord(_word());
      expect(saved.id, isNotEmpty);
      expect(store.findCollection('col-1')!.totalWords, 6);

      final removed = store.deleteWord(saved.id);
      expect(removed?.term, 'resilient');
      expect(store.findCollection('col-1')!.totalWords, 5);

      store.restoreWord(removed!);
      expect(store.findWord(saved.id), isNotNull);
      expect(store.findCollection('col-1')!.totalWords, 6);
    });

    test('updateWord: sửa nội dung và trả về false nếu không tồn tại', () {
      final store = _freshStore();
      final original = store.findWord('voc-1')!;
      expect(store.updateWord(original.copyWith(definitionVi: 'Mạch lạc')), isTrue);
      expect(store.findWord('voc-1')!.definitionVi, 'Mạch lạc');
      expect(store.updateWord(_word(id: 'khong-ton-tai')), isFalse);
    });

    test('addWords (cầu nối Track B — Lưu từ AI) gán đúng học phần và tăng số từ', () {
      final store = _freshStore();
      store.addWords('col-3', [_word(term: 'boarding'), _word(term: 'layover')]);
      final words = store.wordsOf('col-3');
      expect(words.length, 5);
      expect(words.every((w) => w.id.isNotEmpty && w.collectionId == 'col-3'), isTrue);
      expect(store.findCollection('col-3')!.totalWords, 5);
    });

    test('isTermTaken: phát hiện từ trùng trong cùng học phần, bỏ qua chính nó khi sửa', () {
      final store = _freshStore();
      expect(store.isTermTaken('col-1', 'COHERENT'), isTrue);
      expect(store.isTermTaken('col-2', 'coherent'), isFalse);
      expect(store.isTermTaken('col-1', 'coherent', excludeId: 'voc-1'), isFalse);
    });
  });

  group('AuthRepository (Màn 02, 03, 21, 23)', () {
    late AuthRepository auth;

    setUp(() => auth = AuthRepository(latency: Duration.zero, random: Random(7)));

    test('login: đúng tài khoản mẫu thì đăng nhập, sai mật khẩu báo lỗi', () async {
      await expectLater(
        auth.login(AuthRepository.demoEmail, 'sai-mat-khau'),
        throwsA(isA<AuthException>()),
      );
      expect(auth.isLoggedIn, isFalse);

      final profile = await auth.login(' LEARNER@karvocab.com ', AuthRepository.demoPassword);
      expect(auth.isLoggedIn, isTrue);
      expect(profile.email, AuthRepository.demoEmail);
      expect(await auth.restoreSession(), isTrue);
    });

    test('login: tài khoản test cũ admin@123 đã bị xoá', () async {
      await expectLater(auth.login('admin@123', '123456'), throwsA(isA<AuthException>()));
      expect(auth.isLoggedIn, isFalse);
    });

    test('register: tạo tài khoản mới, chặn email đã tồn tại', () async {
      final profile = await auth.register(fullName: 'Nguyễn Văn B', email: 'nvb@test.com', password: 'Hocvien123');
      expect(profile.totalWordsLearned, 0);
      expect(auth.currentUser?.fullName, 'Nguyễn Văn B');
      await expectLater(
        auth.register(fullName: 'Ai đó', email: AuthRepository.demoEmail, password: 'Karvocab1'),
        throwsA(isA<AuthException>()),
      );
    });

    test('quên mật khẩu: OTP sai bị từ chối, OTP đúng cho phép đặt mật khẩu mới', () async {
      await expectLater(auth.requestPasswordReset('khongco@test.com'), throwsA(isA<AuthException>()));

      final code = await auth.requestPasswordReset(AuthRepository.demoEmail);
      expect(code, matches(RegExp(r'^\d{6}$')));

      // Chưa xác thực OTP thì không được đặt lại
      await expectLater(auth.resetPassword(AuthRepository.demoEmail, 'MoiMoi123'), throwsA(isA<AuthException>()));

      final wrong = code == '000000' ? '111111' : '000000';
      await expectLater(auth.verifyOtp(AuthRepository.demoEmail, wrong), throwsA(isA<AuthException>()));

      await auth.verifyOtp(AuthRepository.demoEmail, code);
      await auth.resetPassword(AuthRepository.demoEmail, 'MoiMoi123');
      await auth.login(AuthRepository.demoEmail, 'MoiMoi123');
      expect(auth.isLoggedIn, isTrue);
    });

    test('changePassword: kiểm tra mật khẩu hiện tại; Demo Mode không được đổi', () async {
      await auth.login(AuthRepository.demoEmail, AuthRepository.demoPassword);
      await expectLater(auth.changePassword('sai', 'Newpass123'), throwsA(isA<AuthException>()));
      await auth.changePassword(AuthRepository.demoPassword, 'Newpass123');

      auth.enterDemoMode();
      expect(auth.isDemo, isTrue);
      await expectLater(auth.changePassword('Newpass123', 'Other1234'), throwsA(isA<AuthException>()));
    });

    test('logout: xoá phiên đăng nhập', () async {
      auth.enterDemoMode();
      auth.logout();
      expect(auth.isLoggedIn, isFalse);
      expect(auth.isDemo, isFalse);
      expect(await auth.restoreSession(), isFalse);
    });
  });

  group('Services', () {
    test('PronunciationService: đánh dấu từ đang phát rồi xoá khi phát xong, ghi nhớ cache', () async {
      final service = PronunciationService(const SimulatedPronunciationEngine(duration: Duration.zero));
      final word = _word(id: 'voc-x');
      final playing = service.play(word, accent: Accent.us);
      expect(service.isPlaying('voc-x'), isTrue);
      await playing;
      expect(service.playingWordId, isNull);
      expect(service.isCached('resilient', Accent.us), isTrue);
      expect(service.isCached('resilient', Accent.uk), isFalse);
    });

    test('ReminderService: lên lịch giờ hợp lệ, từ chối giờ sai, huỷ được lịch', () async {
      final reminders = ReminderService();
      await reminders.scheduleDaily('20:00');
      expect(reminders.scheduledTime, '20:00');
      await expectLater(reminders.scheduleDaily('25:00'), throwsArgumentError);
      await reminders.cancel();
      expect(reminders.isScheduled, isFalse);
    });
  });

  test('Mật khẩu mạnh: tối đa 72 ký tự như BE', () {
    expect(Validators.strongPassword('Abcdefg1${'a' * 64}'), isNull); // 72 ký tự
    expect(Validators.strongPassword('Abcdefg1${'a' * 65}'), 'Mật khẩu tối đa 72 ký tự');
  });
}
