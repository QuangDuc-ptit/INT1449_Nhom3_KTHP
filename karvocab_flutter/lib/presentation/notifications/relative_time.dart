import '../../core/constants/app_strings.dart';

/// Thời gian tương đối của thông báo, tính từ [createdAt] tới [now]:
/// "Vừa xong" · "{n} phút trước" · "{n} giờ trước" · "{n} ngày trước" ·
/// từ 7 ngày trở lên là ngày cụ thể dd/MM/yyyy.
String formatRelativeTime(DateTime createdAt, DateTime now) {
  final diff = now.difference(createdAt);
  if (diff.inMinutes < 1) return AppStrings.timeJustNow;
  if (diff.inHours < 1) return AppStrings.timeMinutesAgo(diff.inMinutes);
  if (diff.inDays < 1) return AppStrings.timeHoursAgo(diff.inHours);
  if (diff.inDays < 7) return AppStrings.timeDaysAgo(diff.inDays);
  final local = createdAt.toLocal();
  return AppStrings.timeDate(local.day, local.month, local.year);
}
