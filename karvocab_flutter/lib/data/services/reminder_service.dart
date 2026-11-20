import 'package:flutter/foundation.dart';

/// Lịch nhắc học hằng ngày (Màn 23 — DEV1-S3-04).
/// Bản hiện tại chỉ ghi nhận lịch trong bộ nhớ để chạy offline. Khi thêm
/// `flutter_local_notifications` + FCM, thay thân [scheduleDaily] / [cancel]
/// bằng lời gọi plugin; UI Cài đặt không cần sửa.
class ReminderService extends ChangeNotifier {
  static final ReminderService instance = ReminderService();

  String? _scheduledTime;

  /// Giờ nhắc đang được lên lịch, dạng `HH:mm`; `null` nếu đã tắt.
  String? get scheduledTime => _scheduledTime;
  bool get isScheduled => _scheduledTime != null;

  Future<void> scheduleDaily(String hhmm) async {
    if (!RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(hhmm)) {
      throw ArgumentError('Giờ nhắc không hợp lệ: $hhmm');
    }
    _scheduledTime = hhmm;
    notifyListeners();
  }

  Future<void> cancel() async {
    _scheduledTime = null;
    notifyListeners();
  }
}
