import 'dart:math';

import '../models/ai_vocab_draft.dart';

/// Hợp đồng gọi `POST /api/v1/ai/generate-vocab`.
/// Khi BE sẵn sàng, tạo `RemoteAiVocabRepository` implement lớp này (khoá Gemini nằm ở server, KHÔNG nằm trong app).
abstract class AiVocabRepository {
  Future<List<AiVocabDraft>> generate({
    required String topic,
    required String cefrLevel,
    required int wordCount,
  });
}

/// Bản Demo offline: trả dữ liệu mẫu sau ~2 giây, có công tắc giả lập lỗi để trình diễn Error State.
class MockAiVocabRepository implements AiVocabRepository {
  /// Bật để mô phỏng mất mạng / AI timeout (Màn 13 - Error state).
  static bool simulateFailure = false;

  static const List<Map<String, String>> _bank = [
    {'t': 'boarding', 'p': 'noun', 'i': '/ˈbɔːdɪŋ/', 'e': 'The process of getting on a plane, ship or train.', 'v': 'Việc lên máy bay, tàu thuyền', 's': 'Boarding starts at gate 12 in twenty minutes.'},
    {'t': 'luggage', 'p': 'noun', 'i': '/ˈlʌɡɪdʒ/', 'e': 'Bags and suitcases that you take on a journey.', 'v': 'Hành lý', 's': 'Please keep your luggage with you at all times.'},
    {'t': 'departure', 'p': 'noun', 'i': '/dɪˈpɑːtʃə/', 'e': 'The act of leaving a place.', 'v': 'Sự khởi hành', 's': 'The departure time has been delayed by an hour.'},
    {'t': 'customs', 'p': 'noun', 'i': '/ˈkʌstəmz/', 'e': 'The place where your bags are checked when you enter a country.', 'v': 'Hải quan', 's': 'We had to go through customs after landing.'},
    {'t': 'layover', 'p': 'noun', 'i': '/ˈleɪəʊvə/', 'e': 'A short stop between two parts of a journey.', 'v': 'Điểm dừng chân quá cảnh', 's': 'I have a four-hour layover in Singapore.'},
    {'t': 'algorithm', 'p': 'noun', 'i': '/ˈælɡərɪðəm/', 'e': 'A set of rules for solving a problem step by step.', 'v': 'Thuật toán', 's': 'The search algorithm ranks results by relevance.'},
    {'t': 'interface', 'p': 'noun', 'i': '/ˈɪntəfeɪs/', 'e': 'The way a user interacts with a program or device.', 'v': 'Giao diện', 's': 'The app has a clean and simple interface.'},
    {'t': 'bandwidth', 'p': 'noun', 'i': '/ˈbændwɪdθ/', 'e': 'The amount of data that can be sent over a connection.', 'v': 'Băng thông', 's': 'Video calls need a lot of bandwidth.'},
    {'t': 'encryption', 'p': 'noun', 'i': '/ɪnˈkrɪpʃn/', 'e': 'Turning data into a secret code to protect it.', 'v': 'Sự mã hoá', 's': 'Encryption keeps your messages private.'},
    {'t': 'prototype', 'p': 'noun', 'i': '/ˈprəʊtətaɪp/', 'e': 'A first model of something from which others are developed.', 'v': 'Bản mẫu thử nghiệm', 's': 'The team built a prototype in two weeks.'},
    {'t': 'roast', 'p': 'verb', 'i': '/rəʊst/', 'e': 'To heat coffee beans until they turn brown.', 'v': 'Rang (cà phê)', 's': 'They roast their beans fresh every morning.'},
    {'t': 'brew', 'p': 'verb', 'i': '/bruː/', 'e': 'To make coffee or tea by adding hot water.', 'v': 'Pha, ủ (cà phê, trà)', 's': 'I like to brew a strong cup before work.'},
    {'t': 'barista', 'p': 'noun', 'i': '/bəˈriːstə/', 'e': 'A person who makes and serves coffee in a café.', 'v': 'Nhân viên pha chế cà phê', 's': 'The barista drew a leaf on my latte.'},
    {'t': 'espresso', 'p': 'noun', 'i': '/eˈspresəʊ/', 'e': 'Strong coffee made by forcing steam through ground beans.', 'v': 'Cà phê espresso', 's': 'He ordered a double espresso.'},
    {'t': 'aroma', 'p': 'noun', 'i': '/əˈrəʊmə/', 'e': 'A pleasant and noticeable smell.', 'v': 'Hương thơm', 's': 'The aroma of fresh coffee filled the room.'},
    {'t': 'negotiate', 'p': 'verb', 'i': '/nɪˈɡəʊʃieɪt/', 'e': 'To discuss something to reach an agreement.', 'v': 'Đàm phán, thương lượng', 's': 'We need to negotiate the price with the supplier.'},
    {'t': 'deadline', 'p': 'noun', 'i': '/ˈdedlaɪn/', 'e': 'The latest time by which something must be done.', 'v': 'Hạn chót', 's': 'The deadline for the report is Friday.'},
    {'t': 'revenue', 'p': 'noun', 'i': '/ˈrevənjuː/', 'e': 'Money that a company receives from its business.', 'v': 'Doanh thu', 's': 'Annual revenue grew by fifteen percent.'},
    {'t': 'proposal', 'p': 'noun', 'i': '/prəˈpəʊzl/', 'e': 'A formal plan or suggestion put forward for consideration.', 'v': 'Bản đề xuất', 's': 'She submitted a proposal for a new marketing campaign.'},
    {'t': 'stakeholder', 'p': 'noun', 'i': '/ˈsteɪkhəʊldə/', 'e': 'A person with an interest or concern in a business.', 'v': 'Bên liên quan', 's': 'Every stakeholder must approve the plan.'},
  ];

  // Từ khoá chủ đề → các chỉ số trong ngân hàng mẫu
  static const Map<String, List<int>> _topicIndex = {
    'airport': [0, 1, 2, 3, 4],
    'travel': [0, 1, 2, 3, 4],
    'technology': [5, 6, 7, 8, 9],
    'tech': [5, 6, 7, 8, 9],
    'coffee': [10, 11, 12, 13, 14],
    'business': [15, 16, 17, 18, 19],
  };

  @override
  Future<List<AiVocabDraft>> generate({
    required String topic,
    required String cefrLevel,
    required int wordCount,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (simulateFailure) {
      throw Exception('Không thể kết nối tới máy chủ AI');
    }

    final lower = topic.toLowerCase();
    final preferred = <int>[];
    _topicIndex.forEach((key, indexes) {
      if (lower.contains(key)) {
        for (final i in indexes) {
          if (!preferred.contains(i)) preferred.add(i);
        }
      }
    });

    final rest = List<int>.generate(_bank.length, (i) => i)
      ..removeWhere(preferred.contains)
      ..shuffle(Random());
    final order = [...preferred, ...rest].take(wordCount);

    return [
      for (final i in order)
        AiVocabDraft.fromJson({
          'term': _bank[i]['t'],
          'partOfSpeech': _bank[i]['p'],
          'ipa': _bank[i]['i'],
          'definitionEn': _bank[i]['e'],
          'definitionVi': _bank[i]['v'],
          'exampleSentence': _bank[i]['s'],
          'cefrLevel': cefrLevel,
        }),
    ];
  }
}
