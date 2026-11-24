import 'part_of_speech.dart';

/// Chuỗi hiển thị dùng chung (tương đương strings.xml).
/// Chuỗi có số viết thành hàm nhận tham số.
class AppStrings {
  AppStrings._();

  // Màn 02 · Đăng nhập — lỗi hiển thị dưới ô nhập
  static const String loginEmailNotRegistered = 'Email chưa được đăng ký';
  static const String loginWrongPassword = 'Mật khẩu không đúng';

  // Màn 21 · Quên mật khẩu
  static const String forgotPasswordTitle = 'Quên mật khẩu';
  static const String forgotPasswordDescription = 'Tôi sẽ giúp bạn lấy lại quyền truy cập tài khoản.';
  static const String emailLabel = 'Địa chỉ email';
  static const String emailHint = 'name@email.com';
  static const String forgotPasswordEmailLabel = emailLabel;
  static const String forgotPasswordEmailHint = emailHint;
  static const String forgotPasswordNote =
      'Liên kết đặt lại mật khẩu sẽ được gửi đến địa chỉ email bạn đã đăng ký.';
  static const String forgotPasswordSend = 'Gửi liên kết đặt lại';
  static const String forgotPasswordBackToLogin = 'Quay lại đăng nhập';
  /// Nhãn đọc cho trình đọc màn hình của nút "<" (không hiển thị).
  static const String backButtonSemantics = 'Quay lại';

  // Màn 05 · Thư viện
  static const String libraryTitle = 'Thư viện';
  static const String librarySearchHint = 'Tìm học phần';
  static const String libraryAllCategories = 'Tất cả';
  static String libraryWordCount(int words) => '$words từ';
  static String libraryProgressPercent(int percent) => '$percent%';
  static const String libraryEmpty = 'Bạn chưa có học phần nào';
  static const String libraryNoResults = 'Không tìm thấy học phần phù hợp';
  static const String libraryCreateCourse = 'Tạo học phần mới';
  static String libraryCourseCreated(String title) => 'Đã tạo học phần "$title"';
  static const String libraryLoadErrorTitle = 'Không tải được thư viện';
  static const String libraryLoadErrorFallback = 'Đã có lỗi xảy ra.';
  /// Nhãn đọc cho trình đọc màn hình (không hiển thị).
  static const String libraryClearSearch = 'Xoá tìm kiếm';
  static const String libraryLoading = 'Đang tải dữ liệu';
  static String libraryOverviewWords(int total) => '$total từ vựng';
  static String libraryOverviewCourses(int count) => '$count học phần';
  static const String libraryEmptyMessage = 'Tạo học phần đầu tiên để bắt đầu lưu từ vựng.';
  static const String libraryClearFilters = 'Xoá bộ lọc';

  // Sửa / xoá học phần (Màn 05, 06, 22)
  static const String collectionMenu = 'Tuỳ chọn học phần';
  static const String collectionEdit = 'Sửa học phần';
  static const String collectionDelete = 'Xoá học phần';
  static const String collectionSave = 'Lưu thay đổi';
  static String collectionUpdated(String title) => 'Đã lưu học phần "$title"';
  static String collectionDeleted(String title) => 'Đã xoá học phần "$title"';
  static String collectionDeleteTitle(String title) => 'Xoá học phần "$title"?';
  static String collectionDeleteMessage(int words) => words == 0
      ? 'Học phần sẽ bị xoá vĩnh viễn.'
      : '$words từ vựng trong học phần cũng sẽ bị xoá vĩnh viễn.';

  // Thanh điều hướng dưới
  static const String navHome = 'Trang chủ';
  static const String navLibrary = 'Thư viện';
  static const String navPractice = 'Luyện tập';
  static const String navProfile = 'Cá nhân';

  // Màn 04 · Trang chủ
  static const String homeGreeting = 'Xin chào, Karmate!';
  static const String homeNotificationsTooltip = 'Thông báo';

  static const String homeStatTotalWords = 'Tổng số từ';
  static const String homeStatStreak = 'Chuỗi ngày học';
  static const String homeStatNewWords = 'Từ chưa học';
  static const String homeStatToReview = 'Cần ôn lại';
  static String homeStreakValue(int days) => '$days ngày';

  static String homeReviewReminderTitle(int words) => '$words từ đang chờ bạn ôn tập';
  static const String homeDailyGoalTitle = 'Mục tiêu hôm nay';
  static String homeDailyGoalProgress(int done, int goal) => '$done/$goal từ';
  static const String homeDailyGoalReached = 'Đã hoàn thành mục tiêu hôm nay';
  static String homeReviewReminderSubtitle(int minutes) =>
      'Một phiên ngắn · khoảng $minutes phút';

  static String homeStartReview(int words) => 'Bắt đầu ôn tập · $words từ';
  static const String homeNoWordsToReview = 'Không có từ cần ôn';

  static const String homeWeeklyActivity = 'Hoạt động tuần này';
  static const List<String> weekdayShort = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  static const String homeYourCourses = 'Học phần của bạn';
  static const String homeSeeAll = 'Xem tất cả';
  static String homeCourseWordCount(int words) => '$words từ';
  static const String homeNoCourses = 'Bạn chưa có học phần nào';

  // Popup thông báo (Màn 04)
  static const String notificationBadgeOverflow = '99+';
  static String notificationTitle(int total) => 'Thông báo của tôi ($total)';
  static const String notificationRefresh = 'Làm mới';
  static const String notificationMarkAllRead = 'Đánh dấu tất cả đã đọc';
  static const String notificationLoadMore = 'Tải thêm';
  static const String notificationEmpty = 'Bạn chưa có thông báo nào';

  // Thời gian tương đối
  static const String timeJustNow = 'Vừa xong';
  static String timeMinutesAgo(int n) => '$n phút trước';
  static String timeHoursAgo(int n) => '$n giờ trước';
  static String timeDaysAgo(int n) => '$n ngày trước';
  /// Ngày cụ thể dạng dd/MM/yyyy.
  static String timeDate(int day, int month, int year) =>
      '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';

  // Dùng chung
  static const String back = 'Quay lại';
  static const String cancel = 'Hủy';
  static const String update = 'Cập nhật';
  static String wordCount(int words) => '$words từ';
  static String partOfSpeech(String pos) => PartOfSpeech.bracket(pos);

  // Màn 06 · Nút "Thêm từ"
  static const String addWordManual = 'Thêm thủ công';
  static const String addWordWithAi = 'Tạo bằng AI';

  // ===========================================================================
  // TRACK B (FE2)
  // ===========================================================================

  // Màn 10 · Chọn chế độ luyện tập
  static const String practiceTitle = 'Luyện tập';
  static const String practiceSourceLabel = 'Nguồn học phần';
  static const String practiceSourceHint = 'Chọn tối đa 3 học phần';
  static const String practiceSourceEmpty = 'Chưa chọn học phần';
  static const String practiceStatusLabel = 'Trạng thái từ';
  static const String practiceStatusUnmastered = 'Chưa thuộc';
  static const String practiceStatusMastered = 'Đã thuộc';
  static const String practiceStatusAll = 'Tất cả';
  static const String practiceCountLabel = 'Số lượng từ';
  static const String practiceOrderLabel = 'Thứ tự hiển thị';
  static const String practiceOrderAlphabet = 'Theo thứ tự (A-Z)';
  static const String practiceOrderRandom = 'Ngẫu nhiên';
  static const String practiceGamesTitle = 'Danh sách trò chơi';
  static const String practiceSheetDone = 'Xong';

  // Màn 10 · Thời gian đếm ngược mỗi câu & âm lượng hiệu ứng
  static const String practiceTimerLabel = 'Thời gian mỗi câu';
  static const String practiceTimerPerGame = 'Theo từng trò chơi';
  static const String practiceTimerOff = 'Không giới hạn';
  static const String practiceTimerEnable = 'Đếm ngược mỗi câu';
  static const String practiceTimerHint = 'Hết giờ sẽ tính là trả lời sai. 5 giây cuối có tiếng tích tắc.';
  static const String practiceTimerReset = 'Khôi phục mặc định';
  static String practiceGameSeconds(int seconds) => '$seconds giây/câu';
  static String secondsShort(int seconds) => '${seconds}s';
  static String timerDecrease(String game) => 'Giảm thời gian $game';
  static String timerIncrease(String game) => 'Tăng thời gian $game';
  static const String volumeLabel = 'Âm lượng hiệu ứng';
  static const String volumeHint = 'Tiếng đúng / sai và tiếng tích tắc đếm ngược';
  static const String volumeDecrease = 'Giảm âm lượng';
  static const String volumeIncrease = 'Tăng âm lượng';
  static const String volumeMuted = 'Tắt tiếng';
  static String volumePercent(int percent) => '$percent%';
  static const String volumePreview = 'Nghe thử';
  // Màn 15 · Hồ sơ cá nhân
  static const String profileTitle = 'Hồ sơ cá nhân';
  static const String profileAccountInfo = 'Thông tin tài khoản';
  static const String profileMemberId = 'Mã ID';
  static const String profileEmail = 'Email';
  static const String profileBirthDate = 'Ngày sinh';
  static const String profileLocked = 'Không thể thay đổi';
  static const String profileCopyId = 'Sao chép mã ID';
  static const String profileIdCopied = 'Đã sao chép mã ID';
  static const String profileNoBirthDate = 'Chưa cập nhật';
  static const String profileNoMemberId = 'Cập nhật ngày sinh để nhận mã ID';
  static const String profileEditBirthDate = 'Sửa ngày sinh';
  static const String profileBirthDateSaved = 'Đã cập nhật ngày sinh';
  static const String profileBirthDateHelp = 'Chọn ngày sinh';
  static const String profileAchievements = 'Thành tựu';
  static const String profileWordsLearned = 'Từ đã học';
  /// Màn 17: mục tiêu ngày đếm số từ khác nhau trả lời đúng (giống Trang chủ).
  static const String settingsDailyGoalLabel = 'Số từ cần học mỗi ngày';
  static const String profileStreak = 'Chuỗi ngày';
  static const String profileStreakUnit = 'ngày';
  static const String profileCollections = 'Học phần';
  static const String profileMore = 'Tùy chọn khác';
  static const String profileOpenSettings = 'Cài đặt tài khoản & Mục tiêu';
  static const String profileHelp = 'Hướng dẫn & Trợ giúp';
  static const String profileHelpMessage = 'Hệ thống học từ vựng Spaced Repetition (SM-2) KarVocab.';

  // Màn 03 · Đăng ký
  static const String registerFullName = 'Họ và tên';
  static const String registerFullNameHint = 'VD: Nguyễn Văn An';
  static const String registerBirthDate = 'Ngày sinh';
  static const String registerBirthDateHint = 'DD/MM/YYYY';
  static const String registerBirthDateRequired = 'Vui lòng chọn ngày sinh';
  static const String registerEmailTaken = 'Email này đã được đăng ký';
  static const String registerButton = 'Đăng ký';

  // Màn 09 · Sửa từ vựng & Màn 24 · Thêm từ vựng
  static const String wordFormEditTitle = 'Sửa từ vựng';
  static const String wordFormAddTitle = 'Thêm từ vựng';
  static const String wordFormTerm = 'Từ tiếng Anh';
  static const String wordFormTermHint = 'VD: resilient';
  static const String wordFormIpa = 'IPA';
  static const String wordFormIpaHint = 'VD: /rɪˈzɪliənt/';
  static const String wordFormMeaning = 'Nghĩa tiếng Việt';
  static const String wordFormMeaningHint = 'VD: Kiên cường, bền bỉ';
  static const String wordFormPartOfSpeech = 'Từ loại';
  static const String wordFormExample = 'Ví dụ';
  static const String wordFormExampleHint = 'VD: She stayed resilient through challenges.';
  static const String wordFormLevel = 'Trình độ';
  static const String wordFormNote = 'Ghi chú';
  static const String wordFormSynonyms = 'Từ đồng nghĩa';
  static const String wordFormAntonyms = 'Từ trái nghĩa';
  static const String wordFormTagHint = 'Gõ từ hoặc cụm từ rồi nhấn dấu phẩy';
  static String tagRemove(String word) => 'Xoá "$word"';
  static const String wordFormNoteHint = 'VD: Gợi nhớ đứng dậy sau những khó khăn.';
  static const String wordFormSaveChanges = 'Lưu thay đổi';
  static const String wordFormMeaningRequired = 'Vui lòng nhập nghĩa tiếng Việt';
  static const String wordFormPosHint = 'Chọn từ loại';
  static const String wordFormPosRequired = 'Vui lòng chọn từ loại';
  static const String wordFormLevelHint = 'Chọn trình độ';
  static const String wordFormLevelRequired = 'Vui lòng chọn trình độ';
  /// Nhãn đọc cho dấu * của ô bắt buộc (không hiển thị).
  static const String requiredField = 'bắt buộc';
  static String wordFormDuplicate(String term) => 'Từ "$term" đã có trong học phần này';

  // Màn 07 · Chi tiết từ vựng
  static const String wordDetailTitle = 'Chi tiết từ vựng';
  static const String wordDetailEdit = 'Sửa từ vựng';
  static const String wordDetailMeaning = 'NGHĨA TIẾNG VIỆT';
  static const String wordDetailExample = 'VÍ DỤ SỬ DỤNG';
  static const String wordDetailNoteLabel = 'GHI CHÚ';
  static const String wordDetailSynonyms = 'Từ đồng nghĩa';
  static const String wordDetailAntonyms = 'Từ trái nghĩa';
  static const String wordDetailDelete = 'Xóa từ vựng';
  static String wordDetailSpeak(String term) => 'Phát âm từ $term';
  static String wordDetailUpdated(String term) => 'Đã cập nhật từ "$term"';
  static String wordDetailDeleted(String term) => 'Đã xoá từ "$term"';
  static const String wordDetailUndo = 'Hoàn tác';

  /// Tên tiếng Việt của các cấp CEFR.
  static const Map<String, String> cefrNames = {
    'A1': 'Mới bắt đầu',
    'A2': 'Sơ cấp',
    'B1': 'Trung cấp',
    'B2': 'Trên trung cấp',
    'C1': 'Cao cấp',
  };
  static String cefrOption(String level) => '$level · ${cefrNames[level] ?? ''}';

  static const String practiceNoRelations =
      'Các từ đã chọn chưa có từ đồng nghĩa / trái nghĩa. Hãy chọn học phần khác.';
  static const String practiceNoWords = 'Không có từ phù hợp. Hãy đổi học phần hoặc trạng thái từ.';

  static const String gamePronunciation = 'Luyện phát âm';
  static const String gameListenType = modeListenType;
  static const String gameListenChoose = 'Nghe và chọn từ';
  static const String gameChooseMeaning = modeMeaningChoose;
  static const String gameSynonymAntonym = 'Đồng nghĩa và trái nghĩa';
  static const String gameRecallType = modeRecallType;

  static const String modeListenChoose = 'Nghe chọn từ';
  static const String modeListenType = 'Nghe và điền từ';
  static const String modeMeaningChoose = 'Chọn nghĩa đúng';
  static const String modeRecallType = 'Nhớ từ qua nghĩa';

  // Màn 08 / 19 / 20 / 25 · Làm bài
  static const String quizExitTooltip = 'Thoát';
  static const String quizVolumeTooltip = 'Âm lượng';
  static String quizTimeLeft(int seconds) => 'Còn $seconds giây';
  static const String quizPaused = 'Tạm dừng';
  static const String quizExitTitle = 'Thoát buổi luyện tập?';
  static const String quizExitMessage = 'Tiến độ của phiên này sẽ không được lưu.';
  static const String quizExitStay = 'Tiếp tục học';
  static const String quizExitLeave = 'Thoát';
  static String quizProgress(int current, int total) => '$current/$total';
  static const String quizNoQuestionsTitle = 'Chưa có câu hỏi nào';
  static const String quizNoQuestionsMessage =
      'Hãy thêm từ vựng vào học phần rồi quay lại luyện tập nhé.';
  static const String quizPromptListenChoose = 'Nghe và chọn từ bạn vừa nghe được';
  static const String quizPromptMeaningChoose = 'Chọn nghĩa tiếng Việt đúng của từ';
  static const String quizPromptListenType = 'Nghe và gõ chính xác từ bạn nghe được';
  static const String quizPromptRecallType = 'Đọc nghĩa và gõ từ tiếng Anh tương ứng';
  static const String quizListenTooltip = 'Nghe phát âm';
  static String quizListenWordTooltip(String term) => 'Nghe $term';
  static const List<String> quizOptionLetters = ['A', 'B', 'C', 'D'];
  static String quizOptionSemantics(String letter, String text) => 'Đáp án $letter: $text';
  static const String quizBlank = '_____';
  static String quizRecallHint(String firstLetter, int length) =>
      'Gợi ý: bắt đầu bằng "$firstLetter" • $length chữ cái';
  static const String quizTypingHint = 'Nhập từ tiếng Anh...';
  static const String quizListenTypeHint = 'Gõ từ bạn nghe được...';
  static const String quizCheck = 'Kiểm tra';

  // Game Luyện phát âm
  static const String quizPromptPronunciation = 'Đọc to từ dưới đây';
  static const String speakTapToStart = 'Chạm để bắt đầu nói';
  static const String speakListening = 'Đang nghe... chạm để dừng';
  static const String speakMicSemantics = 'Bắt đầu hoặc dừng ghi âm';
  static String speakHeard(String text) => 'Máy nghe được: "$text"';
  static const String speakUnavailable =
      'Thiết bị hoặc trình duyệt này chưa hỗ trợ nhận dạng giọng nói. Hãy thử Chrome hoặc điện thoại Android.';
  static const String speakPermissionDenied = 'Hãy cho phép KarVocab dùng micro để luyện phát âm.';
  static const String speakNoSpeech = 'Chưa nghe rõ, bạn hãy thử nói lại nhé.';
  static const String speakSkip = 'Bỏ qua câu này';

  // Game Đồng nghĩa và trái nghĩa
  static const String quizPromptSynonymAntonym = 'Hai từ này có quan hệ gì với nhau?';
  static const String relationSynonym = 'Đồng nghĩa';
  static const String relationAntonym = 'Trái nghĩa';
  static String relationExplain(String term, String relation, String pair) =>
      '"$term" ${relation.toLowerCase()} với "$pair"';
  static const String audioPlaySemantics = 'Phát âm thanh';
  static const String listenPronunciation = 'Nghe thử phát âm';
  static String listenPronunciationOf(String term) => 'Nghe phát âm từ $term';
  static const String audioPlaying = 'Đang phát...';
  static const String audioTapToReplay = 'Chạm để nghe lại';

  // Màn 11 · Phản hồi đáp án
  static const String feedbackCorrect = 'Chính xác!';
  static String feedbackAlmost(String term) => 'Suýt đúng! Chú ý chính tả: $term';
  static const String feedbackWrong = 'Chưa đúng rồi';
  static const String feedbackTimeUp = 'Hết giờ!';
  static const String feedbackCorrectAnswer = 'Đáp án đúng:';
  static const String feedbackContinue = 'Tiếp tục';
  static const String feedbackSeeResult = 'Xem kết quả';

  // Màn 12 / 26 · Kết quả & luyện lại câu sai
  static const String resultExcellent = 'Xuất sắc!';
  static const String resultEncourage = 'Cố gắng thêm một chút nhé!';
  static const String resultSubtitle = 'Kết quả buổi luyện tập';
  static const String resultRetrySubtitle = 'Kết quả luyện lại câu sai';
  static String resultPercent(int percent) => '$percent%';
  static const String resultCorrect = 'Đúng';
  static const String resultWrong = 'Sai';
  static const String resultDuration = 'Thời gian';
  static String resultDurationValue(int minutes, int seconds) =>
      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  static const String resultMissedWords = 'Từ cần ôn lại';
  static String resultRetryMissed(int count) => 'Luyện lại câu sai ($count)';
  static const String resultDone = 'Hoàn thành';
  static const String resultAccuracy = 'chính xác';
  static const String resultNoMistakes = 'Bạn không sai câu nào. Tiếp tục phát huy nhé!';
  static const String quizRetryChip = 'Luyện lại câu sai';
  static const String quizMeaningLabel = 'Nghĩa';
  static const String quizExampleLabel = 'Ví dụ';

  // Màn 13 · Tạo từ vựng bằng AI
  static const String aiGenerateTitle = 'Tạo từ vựng bằng AI';
  static const String aiTopicLabel = 'Chủ đề bạn muốn học';
  static const String aiTopicHint = 'VD: Airport, Travel...';
  static const List<String> aiTopicSuggestions = [
    'IELTS Speaking Part 2',
    'Technology',
    'Coffee Culture',
    'Business Negotiation',
  ];
  static const String aiCefrLabel = 'Cấp độ CEFR';
  static String aiWordCountLabel(int min, int max) => 'Số lượng từ ($min – $max)';
  static const String aiDecrease = 'Giảm';
  static const String aiIncrease = 'Tăng';
  static const String aiSimulateFailure = 'Mô phỏng lỗi AI (Demo)';
  static const String aiGenerateButton = 'Tạo từ vựng ngay';
  static const String aiLoadingTitle = 'Axolotl đang suy nghĩ...';
  static String aiLoadingSubtitle(int count, String level) =>
      'Đang tạo $count từ vựng cấp $level';
  static const String aiErrorTitle = 'Tạo từ vựng thất bại';
  static const String aiErrorRateLimited = 'Bạn thao tác quá nhanh. Vui lòng chờ một lát rồi thử lại.';
  static String aiErrorRateLimitedSeconds(int s) =>
      'Bạn thao tác quá nhanh. Vui lòng chờ $s giây rồi thử lại.';
  static const String aiErrorTimeout = 'AI phản hồi quá lâu. Vui lòng thử lại.';
  static const String aiErrorBadResponse = 'AI trả về dữ liệu không hợp lệ. Hãy thử lại hoặc đổi chủ đề.';
  static const String aiErrorUnavailable = 'Dịch vụ AI đang tạm thời không khả dụng. Vui lòng thử lại sau.';
  static const String aiErrorUnauthorized = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
  static const String aiErrorDefault = 'Không thể tạo từ vựng. Vui lòng thử lại.';
  static const String aiErrorConnection = 'Không thể kết nối tới máy chủ AI. Kiểm tra mạng và thử lại.';
  static const String aiBackToForm = 'Quay về';

  // Màn 14 · Xem trước & lưu từ AI
  static const String aiPreviewTitle = 'Xem trước từ vựng AI';
  static const String aiPreviewEmptyTitle = 'AI chưa trả về từ nào';
  static const String aiPreviewEmptyMessage = 'Hãy thử lại với chủ đề khác.';
  static String aiPreviewSelected(int selected, int total) => 'Đã chọn $selected/$total từ';
  static const String aiSelectAll = 'Chọn tất cả';
  static const String aiDeselectAll = 'Bỏ chọn tất cả';
  static String aiSaveSelected(int count) => 'Lưu $count từ đã chọn';
  static String aiSaved(int count) => 'Đã thêm $count từ vào học phần';
  static String aiSavedWithSkipped(int saved, int skipped) =>
      'Đã thêm $saved từ, bỏ qua $skipped từ đã có trong học phần';
  static String aiNewCollectionDefault(String topic) => 'AI · $topic';
  static String aiDestinationNew(String name) => 'Tạo mới: $name';
  static const String aiAlreadyInCollection = 'Đã có trong học phần';
  static String aiDraftMeta(String pos, String ipa) => '${PartOfSpeech.bracket(pos)}  $ipa';
  static String aiEditTooltip(String term) => 'Sửa từ $term';
  static String aiEditTitle(String term) => 'Sửa "$term"';
  static const String aiMeaningLabel = 'Nghĩa tiếng Việt';
  static const String aiMeaningHint = 'Nhập nghĩa...';
  static const String aiMeaningRequired = 'Nghĩa tiếng Việt không được để trống';
  static const String aiExampleLabel = 'Câu ví dụ';
  static const String aiExampleHint = 'Nhập câu ví dụ...';
  static const String aiUpdate = update;
  static const String aiDestinationTitle = 'Lưu vào học phần';
  static const String aiNewCollectionLabel = 'Hoặc tạo học phần mới';
  static const String aiNewCollectionHint = 'Tên học phần (2–50 ký tự)';
  static const String aiCreateCollection = libraryCreateCourse;
  static const String aiCollectionDescription = 'Học phần được tạo bằng AI';

  // Màn 16 · Ôn tập hôm nay
  static const String reviewTitle = 'Ôn tập hôm nay';
  static const String reviewDoneTitle = 'Bạn đã ôn xong hôm nay!';
  static const String reviewDoneMessage = 'Không còn từ nào đến hạn. Quay lại vào ngày mai nhé.';
  static const String reviewBackHome = 'Về Trang chủ';
  static const String reviewDueNow = 'Đến hạn bây giờ';
  static String reviewOverdueHours(int h) => 'Quá hạn $h giờ';
  static String reviewOverdueDays(int d) => 'Quá hạn $d ngày';
  static String reviewStart(int count) => 'Bắt đầu ôn $count từ';
}
