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
}
