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
  static const String forgotPasswordEmailLabel = 'Địa chỉ email';
  static const String forgotPasswordEmailHint = 'name@email.com';
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

  // Thanh điều hướng dưới
  static const String navHome = 'Trang chủ';
  static const String navLibrary = 'Thư viện';
  static const String navPractice = 'Luyện tập';
  static const String navProfile = 'Cá nhân';

  // Màn 04 · Trang chủ
  static String homeGreeting(String userName) => 'Xin chào, $userName!';
  static const String homeNotificationsTooltip = 'Thông báo';

  static const String homeStatTotalWords = 'Tổng số từ';
  static const String homeStatStreak = 'Chuỗi ngày học';
  static const String homeStatNewWords = 'Số từ mới tạo';
  static const String homeStatToReview = 'Cần ôn lại';
  static String homeStreakValue(int days) => '$days ngày';

  static String homeReviewReminderTitle(int words) => '$words từ đang chờ bạn ôn tập';
  static String homeReviewReminderSubtitle(int minutes) =>
      'Một phiên ngắn · khoảng $minutes phút';

  static String homeStartReview(int words) => 'Bắt đầu ôn tập · $words từ';
  static const String homeNoWordsToReview = 'Không có từ cần ôn';

  static const String homeWeeklyActivity = 'Hoạt động tuần này';
  static const List<String> weekdayShort = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  static const String homeYourCourses = 'Học phần của bạn';
  static const String homeSeeAll = 'Xem tất cả';
  static String homeCourseWordCount(int words) => '$words từ';
  static String homeCourseProgress(int percent) => '$percent%';
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
  static String wordCount(int words) => '$words từ';
  static String partOfSpeech(String pos) => '[$pos.]';

  // Màn 06 · Nút "Thêm từ"
  static const String addWordManual = 'Thêm thủ công';
  static const String addWordWithAi = 'Tạo bằng AI';

  // ===========================================================================
  // TRACK B (FE2)
  // ===========================================================================

  // Màn 10 · Chọn chế độ luyện tập
  static const String practiceTitle = 'Luyện tập';
  static const String practiceCollection = 'Học phần';
  static const String practiceAllCollections = 'Tất cả';
  static const String practiceQuestionCount = 'Số câu hỏi';
  static String practiceQuestionOption(int n) => '$n câu';
  static const String practiceEmptyTitle = 'Học phần chưa có từ vựng';
  static const String practiceEmptyMessage = 'Thêm từ vào học phần này để bắt đầu luyện tập nhé.';
  static String practiceReady(int words) => '$words từ sẵn sàng • chọn chế độ bên dưới';

  static const String modeListenChoose = 'Nghe chọn từ';
  static const String modeListenType = 'Nghe và điền từ';
  static const String modeMeaningChoose = 'Chọn nghĩa đúng';
  static const String modeRecallType = 'Nhớ từ qua nghĩa';
  static const String modeListenChooseDesc = 'Nghe phát âm rồi chọn từ đúng trong 4 đáp án.';
  static const String modeListenTypeDesc = 'Nghe phát âm và gõ chính xác chính tả của từ.';
  static const String modeMeaningChooseDesc = 'Xem từ tiếng Anh, chọn nghĩa tiếng Việt chính xác.';
  static const String modeRecallTypeDesc = 'Đọc nghĩa tiếng Việt, gõ lại từ tiếng Anh tương ứng.';

  // Màn 08 / 19 / 20 / 25 · Làm bài
  static const String quizExitTooltip = 'Thoát';
  static const String quizExitTitle = 'Thoát buổi luyện tập?';
  static const String quizExitMessage = 'Tiến độ của phiên này sẽ không được lưu.';
  static const String quizExitStay = 'Tiếp tục học';
  static const String quizExitLeave = 'Thoát';
  static String quizProgress(int current, int total) => '$current/$total';
  static const String quizRetryBanner = 'Luyện lại các từ đã làm sai';
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
  static const String audioPlaySemantics = 'Phát âm thanh';
  static const String audioPlaying = 'Đang phát...';
  static const String audioTapToReplay = 'Chạm để nghe lại';

  // Màn 11 · Phản hồi đáp án
  static const String feedbackCorrect = 'Chính xác! 🎉';
  static String feedbackAlmost(String term) => 'Suýt đúng! Chú ý chính tả: $term';
  static const String feedbackWrong = 'Chưa đúng rồi';
  static const String feedbackCorrectAnswer = 'Đáp án đúng:';
  static String feedbackExplanation(String term, String ipa, String meaning) =>
      '$term $ipa — $meaning';
  static const String feedbackContinue = 'Tiếp tục';
  static const String feedbackSeeResult = 'Xem kết quả';

  // Màn 12 / 26 · Kết quả & luyện lại câu sai
  static const String resultEmojiExcellent = '🦎🎉';
  static const String resultEmojiEncourage = '🦎💪';
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
  static const String aiLoadingEmoji = '🦎';
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
  static String aiNewCollectionDefault(String topic) => 'AI · $topic';
  static String aiDestinationNew(String name) => 'Tạo mới: $name';
  static const String aiAlreadyInCollection = 'Đã có trong học phần';
  static String aiDraftMeta(String pos, String ipa) => '[$pos.]  $ipa';
  static String aiEditTooltip(String term) => 'Sửa từ $term';
  static String aiEditTitle(String term) => 'Sửa "$term"';
  static const String aiMeaningLabel = 'Nghĩa tiếng Việt';
  static const String aiMeaningHint = 'Nhập nghĩa...';
  static const String aiMeaningRequired = 'Nghĩa tiếng Việt không được để trống';
  static const String aiExampleLabel = 'Câu ví dụ';
  static const String aiExampleHint = 'Nhập câu ví dụ...';
  static const String aiUpdate = 'Cập nhật';
  static const String aiDestinationTitle = 'Lưu vào học phần';
  static const String aiNewCollectionLabel = 'Hoặc tạo học phần mới';
  static const String aiNewCollectionHint = 'Tên học phần (2–50 ký tự)';
  static const String aiCreateCollection = 'Tạo học phần mới';
  static const String aiCollectionDescription = 'Học phần được tạo bằng AI';

  // Màn 16 · Ôn tập hôm nay
  static const String reviewTitle = 'Ôn tập hôm nay';
  static const String reviewDoneTitle = 'Bạn đã ôn xong hôm nay! 🎉';
  static const String reviewDoneMessage = 'Không còn từ nào đến hạn. Quay lại vào ngày mai nhé.';
  static const String reviewBackHome = 'Về Trang chủ';
  static const String reviewDueNow = 'Đến hạn bây giờ';
  static String reviewOverdueHours(int h) => 'Quá hạn $h giờ';
  static String reviewOverdueDays(int d) => 'Quá hạn $d ngày';
  static String reviewStart(int count) => 'Bắt đầu ôn $count từ';

  // Màn 04 · Trang chủ (bản FE2 — dashboard/home_screen.dart)
  static const String dashboardTitle = 'Trang chủ';
  static const String dashboardGreeting = 'Xin chào! 👋';
  static const String dashboardTagline = 'Mỗi ngày một chút, nhớ lâu hơn.';
  static String dashboardStreak(int days) => '$days ngày';
  static const String dashboardStreakDone = 'Chuỗi học liên tiếp — hôm nay đã xong! ✅';
  static const String dashboardStreakPending = 'Chuỗi học liên tiếp — học ngay để giữ lửa!';
  static const String dashboardGoalTitle = 'Mục tiêu hôm nay';
  static String dashboardGoalReached(int reviewed, int goal) =>
      'Tuyệt vời! Bạn đã hoàn thành mục tiêu ($reviewed/$goal từ) 🎉';
  static String dashboardGoalProgress(int reviewed, int goal) =>
      '$reviewed / $goal từ đã ôn hôm nay';
  static String dashboardDueTitle(int count) => 'Bạn có $count từ cần ôn hôm nay';
  static const String dashboardDueMessage =
      'Ôn đúng hạn giúp bạn nhớ lâu hơn theo chu kỳ lặp lại ngắt quãng.';
  static const String dashboardReviewNow = 'Ôn tập ngay';
  static const String dashboardShortcuts = 'Lối tắt học nhanh';
  static String dashboardQuickPractice(int count) => 'Luyện nhanh\n$count câu';
  static const String dashboardAiShortcut = 'Tạo từ\nbằng AI';
}
