import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_typography.dart';

/// Một mục nội dung: tiêu đề + các đoạn văn.
class InfoSection {
  final String title;
  final List<String> paragraphs;

  const InfoSection(this.title, this.paragraphs);
}

/// Màn đọc thông tin tĩnh: Hướng dẫn & Trợ giúp (Màn 15) và
/// Điều khoản & Quyền riêng tư (Màn 23, Màn 02).
class InfoScreen extends StatelessWidget {
  final String title;
  final List<InfoSection> sections;

  const InfoScreen({super.key, required this.title, required this.sections});

  /// Hướng dẫn sử dụng app.
  const InfoScreen.help({super.key})
      : title = AppStrings.profileHelp,
        sections = helpSections;

  /// Điều khoản sử dụng & quyền riêng tư.
  const InfoScreen.terms({super.key})
      : title = AppStrings.termsTitle,
        sections = termsSections;

  static const List<InfoSection> helpSections = [
    InfoSection('1. Tạo học phần và thêm từ', [
      'Vào tab Thư viện, bấm "Tạo mới" để tạo học phần theo chủ đề (Học thuật, Sự nghiệp, Đời sống, Du lịch...).',
      'Mở học phần rồi bấm "Thêm từ": nhập từ tiếng Anh, nghĩa tiếng Việt, từ loại, trình độ CEFR; '
          'có thể thêm phiên âm, câu ví dụ, từ đồng nghĩa / trái nghĩa và ghi chú.',
      'Khi app được nối máy chủ, chọn "Tạo bằng AI" để AI gợi ý từ theo chủ đề, xem trước rồi lưu vào học phần.',
    ]),
    InfoSection('2. Luyện tập với 6 trò chơi', [
      'Tab Luyện tập: chọn học phần, trạng thái từ (Chưa thuộc / Đã thuộc / Tất cả), số câu và thứ tự.',
      'Các trò: Chọn nghĩa đúng, Nghe và chọn từ, Nghe và điền từ, Nhớ từ qua nghĩa, '
          'Đồng nghĩa và trái nghĩa, Luyện phát âm (cần micro).',
      'Gõ sai một chữ cái vẫn được tính "Suýt đúng". Hết giờ một câu thì câu đó tính là sai. '
          'Thời gian mỗi câu và âm lượng chỉnh ở mục "Thời gian mỗi câu" trong tab Luyện tập.',
      'Sau mỗi phiên, bấm "Luyện lại câu sai" để ôn ngay những từ vừa làm sai.',
    ]),
    InfoSection('3. Ôn tập ngắt quãng (SM-2)', [
      'Trả lời đúng một từ đã đến hạn thì từ lên cấp và hẹn ôn lại sau 1, 3, 7, 16 rồi 35 ngày. '
          'Lên cấp 5 là "Đã thuộc".',
      'Trả lời sai thì từ về cấp 0 và được hẹn ôn lại vào ngày mai.',
      'Trang chủ hiện số từ cần ôn; bấm "Bắt đầu ôn tập" để ôn các từ đến hạn hôm nay.',
    ]),
    InfoSection('4. Mục tiêu, chuỗi ngày và huy hiệu', [
      'Đặt số từ cần học mỗi ngày (5–30) trong Cài đặt. Mỗi ngày học ít nhất một phiên thì chuỗi ngày tăng thêm 1; '
          'bỏ trọn một ngày thì chuỗi về 0.',
      'Huy hiệu ở Hồ sơ: Chuỗi 7 ngày, 100 từ đầu tiên và Nhà thám hiểm (tạo từ 6 học phần trở lên).',
    ]),
  ];

  static const List<InfoSection> termsSections = [
    InfoSection('Dữ liệu được lưu ở đâu', [
      'Học phần, từ vựng, tiến độ học và cài đặt được lưu ngay trên thiết bị này, tách riêng theo từng tài khoản. '
          'Gỡ app hoặc xoá dữ liệu app sẽ xoá các dữ liệu này.',
      'Khi app được nối với máy chủ KarVocab, việc đăng nhập, đăng ký, đổi / đặt lại mật khẩu và tạo từ bằng AI '
          'được gửi tới máy chủ đó.',
    ]),
    InfoSection('Mật khẩu', [
      'Mật khẩu không được lưu ở dạng chữ thường: trên thiết bị chỉ lưu bản băm SHA-256 kèm chuỗi muối riêng của từng tài khoản.',
    ]),
    InfoSection('Micro và âm thanh', [
      'Micro chỉ được dùng trong trò "Luyện phát âm", sau khi bạn cho phép. Giọng nói được nhận dạng bằng '
          'dịch vụ nhận dạng giọng nói có sẵn của hệ điều hành.',
      'Phát âm từ vựng dùng bộ đọc văn bản (TTS) của thiết bị.',
    ]),
    InfoSection('Điều khoản sử dụng', [
      'KarVocab là sản phẩm học tập của Nhóm 03, môn INT1449 - Học viện Công nghệ Bưu chính Viễn thông, '
          'dùng cho mục đích học tập, không thu phí và không có quảng cáo.',
      'Nội dung từ vựng do người dùng tự nhập hoặc do AI gợi ý; hãy kiểm tra lại trước khi dùng cho mục đích quan trọng.',
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        backgroundColor: AppColors.mainBackground,
        title: Text(title, style: AppTypography.headingMedium),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppDimensions.quizMaxContentWidth),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppDimensions.screenMargin),
              itemCount: sections.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppDimensions.space12),
              itemBuilder: (context, i) => _SectionCard(section: sections[i]),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final InfoSection section;

  const _SectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.title, style: AppTypography.bodyBold.copyWith(color: AppColors.primaryBlue)),
          for (final p in section.paragraphs) ...[
            const SizedBox(height: AppDimensions.space8),
            Text(p, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
          ],
        ],
      ),
    );
  }
}
