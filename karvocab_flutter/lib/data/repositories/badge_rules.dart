import '../models/user_profile_model.dart';

/// Quy tắc mở khoá huy hiệu (đặc tả Màn 15):
/// - `streak_7`: duy trì học 7 ngày liên tục.
/// - `first_100`: học đủ 100 từ vựng.
/// - `word_explorer`: tạo từ 5 học phần trở lên.
class BadgeRules {
  BadgeRules._();

  static const int streakTarget = 7;
  static const int wordsTarget = 100;
  static const int collectionsTarget = 5;

  static List<BadgeModel> evaluate({
    required int currentStreak,
    required int wordsLearned,
    required int collectionCount,
  }) {
    return [
      _badge(
        id: 'b-1',
        code: 'streak_7',
        title: 'Chuỗi 7 Ngày',
        description: 'Học từ vựng liên tục 7 ngày không gián đoạn',
        iconName: 'local_fire_department_rounded',
        progress: currentStreak,
        target: streakTarget,
      ),
      _badge(
        id: 'b-2',
        code: 'first_100',
        title: 'Bách Khoa 100 Từ',
        description: 'Học và ghi nhớ đủ 100 từ vựng',
        iconName: 'military_tech_rounded',
        progress: wordsLearned,
        target: wordsTarget,
      ),
      _badge(
        id: 'b-3',
        code: 'word_explorer',
        title: 'Nhà Thám Hiểm',
        description: 'Tạo từ 5 học phần từ vựng trở lên',
        iconName: 'explore_rounded',
        progress: collectionCount,
        target: collectionsTarget,
      ),
    ];
  }

  static BadgeModel _badge({
    required String id,
    required String code,
    required String title,
    required String description,
    required String iconName,
    required int progress,
    required int target,
  }) {
    final clamped = progress < 0 ? 0 : (progress > target ? target : progress);
    return BadgeModel(
      id: id,
      code: code,
      title: title,
      description: description,
      iconName: iconName,
      isUnlocked: progress >= target,
      currentProgress: clamped,
      maxProgress: target,
    );
  }
}
