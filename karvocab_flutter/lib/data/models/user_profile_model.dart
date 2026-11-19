/// Model Huy hiệu thành tựu (Achievement Badge)
class BadgeModel {
  final String id;
  final String code;
  final String title;
  final String description;
  final String iconName;
  final bool isUnlocked;
  final int currentProgress;
  final int maxProgress;

  const BadgeModel({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.iconName,
    required this.isUnlocked,
    required this.currentProgress,
    required this.maxProgress,
  });
}

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
  final List<BadgeModel> badges;

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
    required this.badges,
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
    List<BadgeModel>? badges,
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
      badges: badges ?? this.badges,
    );
  }

  // Dữ liệu mẫu khởi tạo ban đầu
  static UserProfileModel mockDefault() {
    return const UserProfileModel(
      fullName: 'Nguyễn Văn A',
      email: 'learner@karvocab.com',
      avatarUrl: '',
      totalWordsLearned: 42,
      currentStreak: 7,
      totalCollections: 3,
      dailyGoalWords: 10,
      reminderTime: '20:00',
      isNotificationEnabled: true,
      badges: [
        BadgeModel(
          id: 'b-1',
          code: 'streak_7',
          title: 'Chuỗi 7 Ngày',
          description: 'Học từ vựng liên tục 7 ngày không gián đoạn',
          iconName: 'local_fire_department_rounded',
          isUnlocked: true,
          currentProgress: 7,
          maxProgress: 7,
        ),
        BadgeModel(
          id: 'b-2',
          code: 'word_explorer',
          title: 'Nhà Thám Hiểm',
          description: 'Tạo hoặc tham gia từ 3 học phần trở lên',
          iconName: 'explore_rounded',
          isUnlocked: true,
          currentProgress: 3,
          maxProgress: 3,
        ),
        BadgeModel(
          id: 'b-3',
          code: 'first_100',
          title: 'Bách Khoa 100 Từ',
          description: 'Làm chủ và ghi nhớ thành thạo 100 từ vựng',
          iconName: 'military_tech_rounded',
          isUnlocked: false,
          currentProgress: 42,
          maxProgress: 100,
        ),
      ],
    );
  }
}
