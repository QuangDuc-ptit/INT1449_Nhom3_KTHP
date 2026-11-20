/// Dữ liệu hiển thị của Màn 21 · Quên mật khẩu.
///
/// Màn hình chỉ đọc state này; nơi mở màn giữ state và cập nhật qua
/// callback `onEmailChange`.
class ForgotPasswordUiState {
  final String email;

  const ForgotPasswordUiState({this.email = ''});

  /// Nút "Gửi liên kết đặt lại" chỉ bấm được khi ô email không trống.
  bool get canSendResetLink => email.trim().isNotEmpty;

  ForgotPasswordUiState copyWith({String? email}) => ForgotPasswordUiState(email: email ?? this.email);
}
