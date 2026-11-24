/// Kho từ của chế độ Demo cho Màn 13 (tạo từ bằng AI) khi chưa nối BE / Gemini.
///
/// Mỗi chủ đề có từ khoá tiếng Anh và tiếng Việt (không dấu) để nhận diện chủ đề
/// người dùng nhập. Mỗi từ mang trình độ CEFR của chính nó (tham khảo Oxford 3000/5000),
/// không lấy theo trình độ người dùng chọn, để nhãn trình độ luôn đúng.
library;

class MockAiWord {
  final String term;
  final String partOfSpeech;
  final String ipa;
  final String cefrLevel;
  final String definitionEn;
  final String definitionVi;
  final String example;

  const MockAiWord(
    this.term,
    this.partOfSpeech,
    this.ipa,
    this.cefrLevel,
    this.definitionEn,
    this.definitionVi,
    this.example,
  );
}

class MockAiTopic {
  /// Tên hiển thị khi gợi ý chủ đề có sẵn trong bản Demo.
  final String name;

  /// Từ khoá viết thường, không dấu; khớp theo nguyên từ / cụm từ.
  final List<String> keywords;
  final List<MockAiWord> words;

  const MockAiTopic(this.name, this.keywords, this.words);
}

class MockAiVocabBank {
  MockAiVocabBank._();

  static const List<MockAiTopic> topics = [
    MockAiTopic('Du lịch', [
      'travel', 'travelling', 'traveling', 'trip', 'tourism', 'tourist', 'airport', 'flight', 'holiday',
      'vacation', 'hotel', 'du lich', 'san bay', 'chuyen di', 'chuyen bay', 'khach san', 'nghi duong', 'di choi',
    ], [
      MockAiWord('ticket', 'noun', '/ˈtɪkɪt/', 'A1', 'A piece of paper or digital pass that shows you have paid to travel or enter a place.',
          'Vé', 'I bought a train ticket to Hue.'),
      MockAiWord('passport', 'noun', '/ˈpɑːspɔːt/', 'A2', 'An official document that proves who you are when you travel abroad.',
          'Hộ chiếu', 'Remember to bring your passport to the airport.'),
      MockAiWord('luggage', 'noun', '/ˈlʌɡɪdʒ/', 'A2', 'The bags and suitcases that you take with you on a journey.',
          'Hành lý', 'Please keep your luggage with you at all times.'),
      MockAiWord('reservation', 'noun', '/ˌrezəˈveɪʃn/', 'B1', 'An arrangement to keep a room, seat or table for you.',
          'Sự đặt chỗ trước', 'We have a reservation for two nights.'),
      MockAiWord('accommodation', 'noun', '/əˌkɒməˈdeɪʃn/', 'B1', 'A place where you stay, such as a hotel or a rented room.',
          'Chỗ ở', 'The price includes flights and accommodation.'),
      MockAiWord('departure', 'noun', '/dɪˈpɑːtʃə(r)/', 'B1', 'The act of leaving a place, especially at the start of a journey.',
          'Sự khởi hành', 'Our departure was delayed by two hours.'),
      MockAiWord('customs', 'noun', '/ˈkʌstəmz/', 'B2', 'The place at a border where officials check your bags and documents.',
          'Hải quan', 'It took us an hour to get through customs.'),
      MockAiWord('itinerary', 'noun', '/aɪˈtɪnərəri/', 'C1', 'A detailed plan of a journey, including places to visit.',
          'Lịch trình chuyến đi', 'Our itinerary includes three days in Hoi An.'),
    ]),
    MockAiTopic('Công nghệ', [
      'technology', 'tech', 'computer', 'computers', 'software', 'internet', 'digital', 'programming', 'coding',
      'cong nghe', 'may tinh', 'phan mem', 'lap trinh', 'cntt', 'cong nghe thong tin', 'ky thuat so',
    ], [
      MockAiWord('computer', 'noun', '/kəmˈpjuːtə(r)/', 'A1', 'An electronic machine that stores and processes information.',
          'Máy tính', 'She uses her computer for work every day.'),
      MockAiWord('password', 'noun', '/ˈpɑːswɜːd/', 'A2', 'A secret word or set of characters that lets you use a system.',
          'Mật khẩu', 'Never share your password with anyone.'),
      MockAiWord('download', 'verb', '/ˌdaʊnˈləʊd/', 'A2', 'To copy data from the internet onto your computer or phone.',
          'Tải xuống', 'You can download the app for free.'),
      MockAiWord('software', 'noun', '/ˈsɒftweə(r)/', 'B1', 'The programs used to operate a computer.',
          'Phần mềm', 'The company develops software for schools.'),
      MockAiWord('device', 'noun', '/dɪˈvaɪs/', 'B1', 'A machine or tool made for a particular purpose.',
          'Thiết bị', 'You can open the file on any device.'),
      MockAiWord('database', 'noun', '/ˈdeɪtəbeɪs/', 'B2', 'An organized collection of data stored in a computer.',
          'Cơ sở dữ liệu', 'All customer details are kept in a database.'),
      MockAiWord('innovation', 'noun', '/ˌɪnəˈveɪʃn/', 'B2', 'A new idea, method or product.',
          'Sự đổi mới', 'Innovation helps companies stay competitive.'),
      MockAiWord('algorithm', 'noun', '/ˈælɡərɪðəm/', 'C1', 'A set of rules a computer follows to solve a problem.',
          'Thuật toán', 'The algorithm recommends videos based on your history.'),
    ]),
    MockAiTopic('Ẩm thực & đồ uống', [
      'food', 'cooking', 'cuisine', 'restaurant', 'coffee', 'cafe', 'drink', 'drinks', 'eating', 'kitchen',
      'am thuc', 'nau an', 'do an', 'mon an', 'nha hang', 'ca phe', 'quan ca phe', 'do uong', 'an uong',
    ], [
      MockAiWord('menu', 'noun', '/ˈmenjuː/', 'A1', 'A list of the food and drinks you can order in a restaurant.',
          'Thực đơn', 'Could we see the menu, please?'),
      MockAiWord('delicious', 'adj', '/dɪˈlɪʃəs/', 'A1', 'Having a very pleasant taste.',
          'Ngon', 'This pho is absolutely delicious.'),
      MockAiWord('recipe', 'noun', '/ˈresəpi/', 'B1', 'A set of instructions for cooking a dish.',
          'Công thức nấu ăn', 'My grandmother gave me her recipe for spring rolls.'),
      MockAiWord('ingredient', 'noun', '/ɪnˈɡriːdiənt/', 'B1', 'One of the foods used to make a dish.',
          'Nguyên liệu', 'Fish sauce is a key ingredient in Vietnamese cooking.'),
      MockAiWord('flavour', 'noun', '/ˈfleɪvə(r)/', 'B1', 'The particular taste of a food or drink.',
          'Hương vị', 'This coffee has a rich chocolate flavour.'),
      MockAiWord('roast', 'verb', '/rəʊst/', 'B1', 'To cook food, or heat coffee beans, in an oven or over a fire.',
          'Nướng; rang', 'They roast the coffee beans every morning.'),
      MockAiWord('bitter', 'adj', '/ˈbɪtə(r)/', 'B2', 'Having a strong, sharp taste that is not sweet.',
          'Đắng', 'Black coffee tastes too bitter for me.'),
      MockAiWord('cuisine', 'noun', '/kwɪˈziːn/', 'B2', 'A style of cooking of a particular country or region.',
          'Ẩm thực (phong cách nấu ăn)', 'Vietnamese cuisine is famous for its fresh herbs.'),
    ]),
    MockAiTopic('Công việc & kinh doanh', [
      'business', 'work', 'job', 'jobs', 'office', 'career', 'negotiation', 'company', 'marketing', 'meeting',
      'kinh doanh', 'cong viec', 'van phong', 'nghe nghiep', 'dam phan', 'cong ty', 'viec lam', 'cong so',
    ], [
      MockAiWord('meeting', 'noun', '/ˈmiːtɪŋ/', 'A1', 'An occasion when people come together to discuss something.',
          'Cuộc họp', 'We have a team meeting every Monday.'),
      MockAiWord('salary', 'noun', '/ˈsæləri/', 'A2', 'The money you are paid every month for your job.',
          'Tiền lương', 'She asked for a higher salary.'),
      MockAiWord('interview', 'noun', '/ˈɪntəvjuː/', 'A2', 'A formal meeting where someone is asked questions for a job.',
          'Buổi phỏng vấn', 'I have a job interview tomorrow morning.'),
      MockAiWord('colleague', 'noun', '/ˈkɒliːɡ/', 'B1', 'A person you work with.',
          'Đồng nghiệp', 'My colleagues helped me finish the project.'),
      MockAiWord('profit', 'noun', '/ˈprɒfɪt/', 'B1', 'The money a business makes after paying its costs.',
          'Lợi nhuận', 'The shop made a small profit last year.'),
      MockAiWord('deadline', 'noun', '/ˈdedlaɪn/', 'B2', 'The latest time by which something must be finished.',
          'Hạn chót', 'The deadline for the report is Friday.'),
      MockAiWord('negotiate', 'verb', '/nɪˈɡəʊʃieɪt/', 'B2', 'To discuss something formally in order to reach an agreement.',
          'Đàm phán, thương lượng', 'We need to negotiate the price with the supplier.'),
      MockAiWord('revenue', 'noun', '/ˈrevənjuː/', 'B2', 'The money a company receives from its business.',
          'Doanh thu', 'Annual revenue grew by fifteen percent.'),
    ]),
    MockAiTopic('Sức khoẻ', [
      'health', 'healthy', 'medical', 'medicine', 'hospital', 'doctor', 'fitness', 'illness',
      'suc khoe', 'y te', 'benh vien', 'bac si', 'benh', 'om dau', 'khoe manh',
    ], [
      MockAiWord('doctor', 'noun', '/ˈdɒktə(r)/', 'A1', 'A person whose job is to treat people who are ill or injured.',
          'Bác sĩ', 'You should see a doctor about that cough.'),
      MockAiWord('headache', 'noun', '/ˈhedeɪk/', 'A2', 'A continuous pain in the head.',
          'Chứng đau đầu', 'I have a terrible headache today.'),
      MockAiWord('medicine', 'noun', '/ˈmedsn/', 'A2', 'A substance you take to treat an illness.',
          'Thuốc', 'Take this medicine twice a day after meals.'),
      MockAiWord('diet', 'noun', '/ˈdaɪət/', 'B1', 'The food that you eat regularly.',
          'Chế độ ăn uống', 'A healthy diet includes plenty of vegetables.'),
      MockAiWord('recover', 'verb', '/rɪˈkʌvə(r)/', 'B1', 'To become well again after an illness or injury.',
          'Hồi phục', 'He recovered quickly after the operation.'),
      MockAiWord('symptom', 'noun', '/ˈsɪmptəm/', 'B2', 'A sign that someone has an illness.',
          'Triệu chứng', 'Fever is a common symptom of flu.'),
      MockAiWord('prescription', 'noun', '/prɪˈskrɪpʃn/', 'B2', 'A written order from a doctor for medicine.',
          'Đơn thuốc', 'You need a prescription to buy this medicine.'),
      MockAiWord('immune', 'adj', '/ɪˈmjuːn/', 'C1', 'Protected against a disease and unable to catch it.',
          'Miễn dịch', 'After the vaccine, you are immune to the virus.'),
    ]),
    MockAiTopic('Môi trường', [
      'environment', 'environmental', 'climate', 'nature', 'pollution', 'green', 'energy', 'sustainability',
      'recycling', 'moi truong', 'khi hau', 'thien nhien', 'o nhiem', 'nang luong', 'tai che', 'bien doi khi hau',
    ], [
      MockAiWord('environment', 'noun', '/ɪnˈvaɪrənmənt/', 'A2', 'The natural world of land, water and air.',
          'Môi trường', 'We must protect the environment for future generations.'),
      MockAiWord('recycle', 'verb', '/ˌriːˈsaɪkl/', 'A2', 'To treat used materials so they can be used again.',
          'Tái chế', 'We recycle plastic bottles and paper at home.'),
      MockAiWord('pollution', 'noun', '/pəˈluːʃn/', 'B1', 'Harmful substances in the air, water or soil.',
          'Sự ô nhiễm', 'Air pollution is a serious problem in big cities.'),
      MockAiWord('climate', 'noun', '/ˈklaɪmət/', 'B1', 'The usual weather conditions in a place.',
          'Khí hậu', 'Climate change is causing more extreme weather.'),
      MockAiWord('waste', 'noun', '/weɪst/', 'B1', 'Materials that are no longer needed and are thrown away.',
          'Rác thải', 'Factories must reduce their waste.'),
      MockAiWord('renewable', 'adj', '/rɪˈnjuːəbl/', 'B2', 'Able to be replaced naturally, such as energy from the sun or wind.',
          'Có thể tái tạo', 'Solar power is a renewable source of energy.'),
      MockAiWord('sustainable', 'adj', '/səˈsteɪnəbl/', 'B2', 'Able to continue without harming the environment.',
          'Bền vững', 'The city is investing in sustainable transport.'),
      MockAiWord('emission', 'noun', '/iˈmɪʃn/', 'C1', 'Gas or other substances sent into the air.',
          'Khí thải', 'Cars produce a large share of carbon emissions.'),
    ]),
    MockAiTopic('Giáo dục', [
      'education', 'school', 'study', 'studying', 'university', 'student', 'students', 'learning', 'ielts', 'exam',
      'giao duc', 'truong hoc', 'hoc tap', 'dai hoc', 'sinh vien', 'hoc sinh', 'thi cu', 'on thi',
    ], [
      MockAiWord('homework', 'noun', '/ˈhəʊmwɜːk/', 'A1', 'Work that a teacher gives students to do at home.',
          'Bài tập về nhà', 'I finished my homework before dinner.'),
      MockAiWord('subject', 'noun', '/ˈsʌbdʒɪkt/', 'A1', 'An area of knowledge studied at school.',
          'Môn học', 'Maths is my favourite subject.'),
      MockAiWord('exam', 'noun', '/ɪɡˈzæm/', 'A2', 'A formal test of your knowledge or skill.',
          'Kỳ thi', 'She passed the English exam with a high score.'),
      MockAiWord('knowledge', 'noun', '/ˈnɒlɪdʒ/', 'B1', 'The information and understanding you gain through learning.',
          'Kiến thức', 'Reading widely improves your general knowledge.'),
      MockAiWord('lecture', 'noun', '/ˈlektʃə(r)/', 'B1', 'A talk given to a group of students on a subject.',
          'Bài giảng', 'The lecture on economics lasted two hours.'),
      MockAiWord('graduate', 'verb', '/ˈɡrædʒueɪt/', 'B1', 'To complete a university or school course successfully.',
          'Tốt nghiệp', 'He graduated from university last year.'),
      MockAiWord('scholarship', 'noun', '/ˈskɒləʃɪp/', 'B2', 'Money given to a student to help pay for their studies.',
          'Học bổng', 'She won a scholarship to study in Australia.'),
      MockAiWord('fluent', 'adj', '/ˈfluːənt/', 'B2', 'Able to speak a language easily and well.',
          'Trôi chảy, lưu loát', 'He is fluent in English and French.'),
    ]),
    MockAiTopic('Thể thao', [
      'sport', 'sports', 'football', 'soccer', 'gym', 'exercise', 'fitness', 'athlete', 'olympics',
      'the thao', 'bong da', 'tap gym', 'tap the duc', 'van dong',
    ], [
      MockAiWord('team', 'noun', '/tiːm/', 'A1', 'A group of people who play a sport together.',
          'Đội', 'Our team won the final match.'),
      MockAiWord('exercise', 'noun', '/ˈeksəsaɪz/', 'A1', 'Physical activity you do to stay healthy.',
          'Sự tập thể dục', 'Regular exercise keeps your heart healthy.'),
      MockAiWord('match', 'noun', '/mætʃ/', 'A2', 'A sports event where two people or teams compete.',
          'Trận đấu', 'The football match starts at eight.'),
      MockAiWord('coach', 'noun', '/kəʊtʃ/', 'B1', 'A person who trains a sports team or player.',
          'Huấn luyện viên', 'The coach told us to practise every day.'),
      MockAiWord('athlete', 'noun', '/ˈæθliːt/', 'B1', 'A person who competes in sports.',
          'Vận động viên', 'Professional athletes train for hours each day.'),
      MockAiWord('stadium', 'noun', '/ˈsteɪdiəm/', 'B1', 'A large sports ground surrounded by seats.',
          'Sân vận động', 'The stadium was full of excited fans.'),
      MockAiWord('opponent', 'noun', '/əˈpəʊnənt/', 'B2', 'A person or team you compete against.',
          'Đối thủ', 'She beat her opponent in three sets.'),
      MockAiWord('championship', 'noun', '/ˈtʃæmpiənʃɪp/', 'B2', 'A competition to find the best player or team.',
          'Giải vô địch', 'They won the national championship last year.'),
    ]),
  ];

  /// Các chủ đề khớp với nội dung người dùng nhập (tiếng Anh hoặc tiếng Việt, có hoặc không dấu).
  static List<MockAiTopic> match(String input) {
    final text = ' ${normalize(input)} ';
    return [
      for (final t in topics)
        if (t.keywords.any((k) => text.contains(' $k '))) t,
    ];
  }

  /// Chữ thường, bỏ dấu tiếng Việt, gom ký tự không phải chữ/số thành một khoảng trắng.
  static String normalize(String input) {
    final buffer = StringBuffer();
    for (final rune in input.toLowerCase().runes) {
      final ch = String.fromCharCode(rune);
      buffer.write(_plain[ch] ?? ch);
    }
    // Bỏ dấu tổ hợp (bàn phím gõ kiểu Unicode tổ hợp) trước khi gom ký tự lạ.
    return buffer
        .toString()
        .replaceAll(_combiningMarks, '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }

  /// Dấu tổ hợp Unicode U+0300–U+036F.
  static final RegExp _combiningMarks = RegExp('[${String.fromCharCode(0x0300)}-${String.fromCharCode(0x036F)}]');

  static final Map<String, String> _plain = () {
    const groups = {
      'a': 'àáạảãâầấậẩẫăằắặẳẵ',
      'e': 'èéẹẻẽêềếệểễ',
      'i': 'ìíịỉĩ',
      'o': 'òóọỏõôồốộổỗơờớợởỡ',
      'u': 'ùúụủũưừứựửữ',
      'y': 'ỳýỵỷỹ',
      'd': 'đ',
    };
    return {
      for (final e in groups.entries)
        for (final ch in e.value.split('')) ch: e.key,
    };
  }();
}
