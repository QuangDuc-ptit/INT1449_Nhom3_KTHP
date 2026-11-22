/// Loại tài khoản và hạn mức đi kèm (Màn 15).
///
/// - Thường: tạo từ bằng AI 3 lần / ngày, lưu tối đa 500 từ.
/// - Plus: gói trải nghiệm 1 tháng, AI 10 lần / ngày, lưu không giới hạn.
/// - Vip: không giới hạn cả hai.
///
/// FE chặn trước để báo người dùng ngay; backend (chưa có cột `plan`) vẫn phải
/// tự kiểm tra lại khi nối API, vì hạn mức phía FE có thể bị vượt qua.
enum AccountPlan {
  standard(aiDailyLimit: 3, wordLimit: 500),
  plus(aiDailyLimit: 10, wordLimit: null, trialDays: 30),
  vip(aiDailyLimit: null, wordLimit: null);

  const AccountPlan({required this.aiDailyLimit, required this.wordLimit, this.trialDays});

  /// Số lần tạo từ bằng AI mỗi ngày; `null` = không giới hạn.
  final int? aiDailyLimit;

  /// Tổng số từ được lưu; `null` = không giới hạn.
  final int? wordLimit;

  /// Thời hạn của gói trải nghiệm (Plus); `null` = không hết hạn.
  final int? trialDays;
}
