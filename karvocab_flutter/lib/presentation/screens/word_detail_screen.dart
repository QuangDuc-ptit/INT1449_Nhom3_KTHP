import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/cefr_badge.dart';
import '../../data/models/vocabulary_model.dart';

/// Màn 07 · Chi tiết từ vựng (Word Detail Screen)
/// Xem phát âm, định nghĩa song ngữ, ví dụ câu ngữ cảnh
class WordDetailScreen extends StatefulWidget {
  final VocabularyModel vocabulary;
  final VoidCallback? onDelete;

  const WordDetailScreen({
    super.key,
    required this.vocabulary,
    this.onDelete,
  });

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  bool _isPlayingAudio = false;

  void _handlePlayAudio() {
    setState(() => _isPlayingAudio = true);

    // Giả lập phát âm thanh từ vựng
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.volume_up_rounded, color: AppColors.white, size: 20),
            const SizedBox(width: AppDimensions.space8),
            Text('Đang phát âm: "${widget.vocabulary.term}" (${widget.vocabulary.ipa})'),
          ],
        ),
        backgroundColor: AppColors.primaryBlue,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _isPlayingAudio = false);
    });
  }

  // Màn 28: Hộp thoại xác nhận xoá từ vựng
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.errorRed, size: 26),
            const SizedBox(width: AppDimensions.space8),
            Text('Xác nhận xoá?', style: AppTypography.headingMedium),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xoá từ "${widget.vocabulary.term}" khỏi học phần này không?',
          style: AppTypography.bodyMedium,
        ),
        actionsPadding: const EdgeInsets.all(AppDimensions.space16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Hủy',
              style: AppTypography.bodyBold.copyWith(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              if (widget.onDelete != null) widget.onDelete!();
              Navigator.of(context).pop(); // Quay lại danh sách từ
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã xoá từ "${widget.vocabulary.term}"'),
                  backgroundColor: AppColors.errorRed,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text('Xoá từ', style: AppTypography.buttonText),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vocab = widget.vocabulary;

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: Text('Chi tiết từ vựng', style: AppTypography.headingMedium),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed),
            onPressed: _confirmDelete,
            tooltip: 'Xoá từ',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.screenMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thẻ từ vựng chính
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.space24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Loại từ & Badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryBackground,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                            ),
                            child: Text(
                              vocab.partOfSpeech.toUpperCase(),
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.navyBlue,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space8),
                          CefrBadge(level: vocab.cefrLevel),
                        ],
                      ),

                      // Nút phát âm tròn to chuẩn Figma
                      GestureDetector(
                        onTap: _handlePlayAudio,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: _isPlayingAudio
                                ? AppColors.navyBlue
                                : AppColors.softBlueSurface,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isPlayingAudio ? Icons.volume_up : Icons.volume_up_outlined,
                            color: _isPlayingAudio ? AppColors.white : AppColors.primaryBlue,
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDimensions.space16),

                  // Từ gốc
                  Text(
                    vocab.term,
                    style: AppTypography.displayLarge.copyWith(
                      color: AppColors.navyBlue,
                      fontSize: 32,
                    ),
                  ),

                  const SizedBox(height: AppDimensions.space4),

                  // Phiên âm IPA
                  Text(
                    vocab.ipa,
                    style: AppTypography.headingMedium.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space20),

            // Nghĩa tiếng Việt
            _buildSection(
              title: 'Nghĩa tiếng Việt',
              icon: Icons.translate_rounded,
              child: Text(
                vocab.definitionVi,
                style: AppTypography.bodyBold.copyWith(
                  fontSize: 17,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            const SizedBox(height: AppDimensions.space16),

            // Định nghĩa tiếng Anh
            _buildSection(
              title: 'Định nghĩa (English)',
              icon: Icons.menu_book_rounded,
              child: Text(
                vocab.definitionEn,
                style: AppTypography.bodyMedium.copyWith(fontSize: 15),
              ),
            ),

            const SizedBox(height: AppDimensions.space16),

            // Câu ví dụ
            _buildSection(
              title: 'Ví dụ câu ngữ cảnh',
              icon: Icons.format_quote_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vocab.exampleSentence,
                    style: AppTypography.bodyLarge.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppColors.navyBlue,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space32),

            // Nút nghe phát âm lớn ở chân trang
            AppButton(
              text: 'Nghe phát âm chuẩn',
              icon: const Icon(Icons.volume_up_rounded, color: AppColors.white),
              onPressed: _handlePlayAudio,
            ),

            const SizedBox(height: AppDimensions.space16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryBlue),
              const SizedBox(width: AppDimensions.space8),
              Text(
                title,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space12),
          child,
        ],
      ),
    );
  }
}
