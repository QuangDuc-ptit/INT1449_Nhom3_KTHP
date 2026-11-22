import '../models/collection_model.dart';
import '../models/vocabulary_model.dart';

/// Dữ liệu mẫu chuẩn trích xuất từ chính xác file Figma KarVocab
class MockVocabData {
  /// Danh sách "sống" (mutable) mà `CollectionStore` và cầu nối AI của FE2 cùng thao tác.
  static final List<CollectionModel> initialCollections = seedCollections();

  /// Danh sách "sống" của toàn bộ từ vựng.
  static final List<VocabularyModel> initialVocabularies = seedVocabularies();

  /// Bản sao mới của dữ liệu gốc — dùng để reset store (Demo / kiểm thử).
  static List<CollectionModel> seedCollections() => [
    const CollectionModel(
      id: 'col-1',
      title: 'Học thuật & IELTS Core',
      description: 'Các từ vựng nâng cao B2 - C1 thiết yếu trong các bài thi IELTS/TOEIC',
      category: 'academic',
      iconName: 'school_rounded',
      totalWords: 5,
      level: 'B2',
    ),
    const CollectionModel(
      id: 'col-2',
      title: 'Tiếng Anh Du lịch & Trải nghiệm',
      description: 'Hành trang từ vựng khi đi sân bay, khách sạn, hỏi đường và khám phá',
      category: 'travel',
      iconName: 'flight_takeoff_rounded',
      totalWords: 4,
      level: 'A2',
    ),
    const CollectionModel(
      id: 'col-3',
      title: 'Giao tiếp & Đời sống hằng ngày',
      description: 'Từ vựng thông dụng thường gặp trong công việc và các cuộc trò chuyện thường nhật',
      category: 'life',
      iconName: 'chat_bubble_outline_rounded',
      totalWords: 3,
      level: 'B1',
    ),
  ];

  static List<VocabularyModel> seedVocabularies() => [
    // Collection 1: Học thuật & IELTS
    const VocabularyModel(
      id: 'voc-1',
      collectionId: 'col-1',
      term: 'coherent',
      partOfSpeech: 'adj',
      ipa: '/kəʊˈhɪərənt/',
      definitionVi: 'Mạch lạc, chặt chẽ, dễ hiểu',
      definitionEn: 'Logical and consistent, clear and easy to understand.',
      exampleSentence: 'He proposed a coherent plan for comprehensive educational reform.',
      cefrLevel: 'B2',
    ),
    const VocabularyModel(
      id: 'voc-2',
      collectionId: 'col-1',
      term: 'inevitable',
      partOfSpeech: 'adj',
      ipa: '/ɪnˈevɪtəbl/',
      definitionVi: 'Không thể tránh khỏi, chắc chắn xảy ra',
      definitionEn: 'Certain to happen and unable to be avoided or prevented.',
      exampleSentence: 'Accidents are the inevitable consequence of careless driving.',
      cefrLevel: 'B2',
    ),
    const VocabularyModel(
      id: 'voc-3',
      collectionId: 'col-1',
      term: 'mitigate',
      partOfSpeech: 'verb',
      ipa: '/ˈmɪtɪɡeɪt/',
      definitionVi: 'Làm dịu bớt, giảm nhẹ mức độ thiệt hại',
      definitionEn: 'To make something less harmful, unpleasant, or bad.',
      exampleSentence: 'Early warnings can effectively mitigate the consequences of natural disasters.',
      cefrLevel: 'C1',
    ),
    const VocabularyModel(
      id: 'voc-4',
      collectionId: 'col-1',
      term: 'perspective',
      partOfSpeech: 'noun',
      ipa: '/pəˈspektɪv/',
      definitionVi: 'Góc nhìn, quan điểm cá nhân',
      definitionEn: 'A particular attitude toward or way of regarding something.',
      exampleSentence: 'Traveling across different cultures gives you a fresh perspective on life.',
      cefrLevel: 'B2',
    ),
    const VocabularyModel(
      id: 'voc-5',
      collectionId: 'col-1',
      term: 'investment',
      partOfSpeech: 'noun',
      ipa: '/ɪnˈvestmənt/',
      definitionVi: 'Sự đầu tư (tiền bạc, thời gian, công sức)',
      definitionEn: 'The act of putting money, effort, or time into something to get a profit.',
      exampleSentence: 'Building vocabulary every single day is the best investment in yourself.',
      cefrLevel: 'B1',
    ),

    // Collection 2: Du lịch
    const VocabularyModel(
      id: 'voc-6',
      collectionId: 'col-2',
      term: 'itinerary',
      partOfSpeech: 'noun',
      ipa: '/aɪˈtɪnərəri/',
      definitionVi: 'Lịch trình, lộ trình chi tiết chuyến đi',
      definitionEn: 'A detailed plan or route of a journey or trip.',
      exampleSentence: 'The tour guide gave everyone an itinerary for the 3-day exploration.',
      cefrLevel: 'B1',
    ),
    const VocabularyModel(
      id: 'voc-7',
      collectionId: 'col-2',
      term: 'destination',
      partOfSpeech: 'noun',
      ipa: '/ˌdestɪˈneɪʃn/',
      definitionVi: 'Điểm đến, nơi đến',
      definitionEn: 'The place to which someone or something is going or being sent.',
      exampleSentence: 'Da Nang is an extremely popular holiday destination for young people.',
      cefrLevel: 'A2',
    ),
    const VocabularyModel(
      id: 'voc-8',
      collectionId: 'col-2',
      term: 'explore',
      partOfSpeech: 'verb',
      ipa: '/ɪkˈsplɔːr/',
      definitionVi: 'Khám phá, thám hiểm nơi mới',
      definitionEn: 'To travel around an area to find out what it is like.',
      exampleSentence: 'We rented a motorbike to explore the remote corners of the island.',
      cefrLevel: 'A2',
    ),
    const VocabularyModel(
      id: 'voc-9',
      collectionId: 'col-2',
      term: 'souvenir',
      partOfSpeech: 'noun',
      ipa: '/ˌsuːvəˈnɪər/',
      definitionVi: 'Đồ lưu niệm, vật kỷ niệm',
      definitionEn: 'Something you keep to remember a special place you visited.',
      exampleSentence: 'I bought a handmade silk lantern as a souvenir from Hoi An.',
      cefrLevel: 'A2',
    ),

    // Collection 3: Đời sống
    const VocabularyModel(
      id: 'voc-10',
      collectionId: 'col-3',
      term: 'ambitious',
      partOfSpeech: 'adj',
      ipa: '/æmˈbɪʃəs/',
      definitionVi: 'Nhiều tham vọng, hoài bão lớn',
      definitionEn: 'Having a strong determination to achieve success and high goals.',
      exampleSentence: 'She is an ambitious student who aims to win a full scholarship.',
      cefrLevel: 'B1',
    ),
    const VocabularyModel(
      id: 'voc-11',
      collectionId: 'col-3',
      term: 'persistent',
      partOfSpeech: 'adj',
      ipa: '/pəˈsɪstənt/',
      definitionVi: 'Kiên trì, bền bỉ, không bỏ cuộc',
      definitionEn: 'Continuing to do something in a determined way despite difficulties.',
      exampleSentence: 'Persistent practice is the key to mastering English pronunciation.',
      cefrLevel: 'B2',
    ),
    const VocabularyModel(
      id: 'voc-12',
      collectionId: 'col-3',
      term: 'opportunity',
      partOfSpeech: 'noun',
      ipa: '/ˌɒpəˈtjuːnəti/',
      definitionVi: 'Cơ hội, thời cơ thuận lợi',
      definitionEn: 'A time or set of circumstances that makes it possible to do something.',
      exampleSentence: 'Never miss an opportunity to practice speaking with foreigners.',
      cefrLevel: 'A2',
    ),
  ];
}
