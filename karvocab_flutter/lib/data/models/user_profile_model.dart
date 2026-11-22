/// Model Thông tin người học & Thống kê cá nhân
class UserProfileModel {
  final String fullName;
  final String email;
  final String avatarUrl;
  final int totalWordsLearned;
  final int currentStreak;
  final int totalCollections;
  final int dailyGoalWords;
  final String reminderTime;
  final bool isNotificationEnabled;

  /// Mã ID (vd `KM05092000`), cấp khi có ngày sinh; không sửa được.
  /// `null` = tài khoản Google / Facebook chưa bổ sung ngày sinh.
  final String? memberId;
  final DateTime? birthDate;

  const UserProfileModel({
    required this.fullName,
    required this.email,
    required this.avatarUrl,
    required this.totalWordsLearned,
    required this.currentStreak,
    required this.totalCollections,
    required this.dailyGoalWords,
    required this.reminderTime,
    required this.isNotificationEnabled,
    this.memberId,
    this.birthDate,
  });

  UserProfileModel copyWith({
    String? fullName,
    String? email,
    String? avatarUrl,
    int? totalWordsLearned,
    int? currentStreak,
    int? totalCollections,
    int? dailyGoalWords,
    String? reminderTime,
    bool? isNotificationEnabled,
    String? memberId,
    DateTime? birthDate,
  }) {
    return UserProfileModel(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      totalWordsLearned: totalWordsLearned ?? this.totalWordsLearned,
      currentStreak: currentStreak ?? this.currentStreak,
      totalCollections: totalCollections ?? this.totalCollections,
      dailyGoalWords: dailyGoalWords ?? this.dailyGoalWords,
      reminderTime: reminderTime ?? this.reminderTime,
      isNotificationEnabled: isNotificationEnabled ?? this.isNotificationEnabled,
      memberId: memberId ?? this.memberId,
      birthDate: birthDate ?? this.birthDate,
    );
  }

  // Dữ liệu mẫu khởi tạo ban đầu
  static UserProfileModel mockDefault() {
    return UserProfileModel(
      fullName: 'Nguyễn Văn A',
      email: 'learner@karvocab.com',
      avatarUrl: '',
      totalWordsLearned: 42,
      currentStreak: 7,
      totalCollections: 3,
      dailyGoalWords: 10,
      reminderTime: '20:00',
      isNotificationEnabled: true,
      memberId: 'KM05092000',
      birthDate: DateTime(2005, 9, 20),
    );
  }
}
