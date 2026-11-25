/// Các bước của Màn 21 theo FE-SPECIFICATION §4.1:
/// Email → nhập mã OTP 6 số → nhập mật khẩu mới.
enum ForgotPasswordStep { email, otp, newPassword }

/// Dùng trong [ForgotPasswordUiState.copyWith] để phân biệt "giữ nguyên" với
/// "đặt về null" cho các trường lỗi.
const Object _keep = Object();

/// Dữ liệu hiển thị của Màn 21 · Quên mật khẩu.
///
/// Màn hình chỉ đọc state này; nơi mở màn giữ state và cập nhật qua callback.
class ForgotPasswordUiState {
  /// Phải đợi bao nhiêu giây mới được gửi lại mã OTP (đặc tả Màn 21).
  static const int resendCooldownSeconds = 60;

  final ForgotPasswordStep step;
  final String email;
  final String otp;
  final String newPassword;
  final String confirmPassword;

  final String? emailError;
  final String? otpError;
  final String? newPasswordError;
  final String? confirmPasswordError;

  /// Đang chờ AuthRepository trả kết quả: nút chính hiện vòng quay.
  final bool isSubmitting;

  /// Số giây còn lại trước khi được gửi lại mã; 0 là gửi lại được.
  final int resendSecondsLeft;

  /// Mã OTP hiện trên màn khi chạy offline (không có máy chủ gửi email).
  /// `null` thì không hiện khung ghi chú.
  final String? offlineOtp;

  const ForgotPasswordUiState({
    this.step = ForgotPasswordStep.email,
    this.email = '',
    this.otp = '',
    this.newPassword = '',
    this.confirmPassword = '',
    this.emailError,
    this.otpError,
    this.newPasswordError,
    this.confirmPasswordError,
    this.isSubmitting = false,
    this.resendSecondsLeft = 0,
    this.offlineOtp,
  });

  /// Nút "Gửi mã OTP" chỉ bấm được khi ô email không trống.
  bool get canSendOtp => email.trim().isNotEmpty;

  /// Nút "Xác nhận mã" chỉ bấm được khi đã nhập mã.
  bool get canVerifyOtp => otp.trim().isNotEmpty;

  /// Nút "Đặt lại mật khẩu" chỉ bấm được khi cả hai ô mật khẩu đã nhập.
  bool get canResetPassword => newPassword.isNotEmpty && confirmPassword.isNotEmpty;

  /// Hết thời gian chờ và không có yêu cầu nào đang chạy.
  bool get canResendOtp => resendSecondsLeft == 0 && !isSubmitting;

  ForgotPasswordUiState copyWith({
    ForgotPasswordStep? step,
    String? email,
    String? otp,
    String? newPassword,
    String? confirmPassword,
    Object? emailError = _keep,
    Object? otpError = _keep,
    Object? newPasswordError = _keep,
    Object? confirmPasswordError = _keep,
    bool? isSubmitting,
    int? resendSecondsLeft,
    Object? offlineOtp = _keep,
  }) {
    return ForgotPasswordUiState(
      step: step ?? this.step,
      email: email ?? this.email,
      otp: otp ?? this.otp,
      newPassword: newPassword ?? this.newPassword,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      emailError: identical(emailError, _keep) ? this.emailError : emailError as String?,
      otpError: identical(otpError, _keep) ? this.otpError : otpError as String?,
      newPasswordError: identical(newPasswordError, _keep) ? this.newPasswordError : newPasswordError as String?,
      confirmPasswordError:
          identical(confirmPasswordError, _keep) ? this.confirmPasswordError : confirmPasswordError as String?,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      resendSecondsLeft: resendSecondsLeft ?? this.resendSecondsLeft,
      offlineOtp: identical(offlineOtp, _keep) ? this.offlineOtp : offlineOtp as String?,
    );
  }
}
