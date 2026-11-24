import '../constants/app_strings.dart';

/// Số ngày lịch từ [now] tới [date] (bỏ giờ). Làm tròn theo giờ để ngày đổi giờ
/// mùa hè (23 hoặc 25 giờ) vẫn tính đúng 1 ngày.
int calendarDaysBetween(DateTime now, DateTime date) {
  final from = DateTime(now.year, now.month, now.day);
  final to = DateTime(date.year, date.month, date.day);
  return (to.difference(from).inHours / 24).round();
}

/// Nhãn lịch ôn lại của một từ: "Ôn lại hôm nay", "Ôn lại vào ngày mai", "Ôn lại sau N ngày".
/// Dùng chung cho Màn 07 (Chi tiết từ) và Màn 12 (Kết quả).
String reviewDueText(DateTime nextReviewAt, DateTime now) {
  final days = calendarDaysBetween(now, nextReviewAt);
  if (days <= 0) return AppStrings.reviewDueToday;
  if (days == 1) return AppStrings.reviewDueTomorrow;
  return AppStrings.reviewDueInDays(days);
}
