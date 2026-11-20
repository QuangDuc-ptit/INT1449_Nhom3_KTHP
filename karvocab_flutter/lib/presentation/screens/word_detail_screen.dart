import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/cefr_badge.dart';
import '../../core/widgets/sound_wave_indicator.dart';
import '../../data/models/vocabulary_model.dart';
import '../../data/repositories/collection_store.dart';
import '../../data/services/pronunciation_service.dart';
import '../widgets/delete_word_dialog.dart';
import 'word_form_screen.dart';

/// Màn 07 · Chi tiết từ vựng (Word Detail Screen)
/// Phát âm UK/US, IPA, loại từ, định nghĩa song ngữ, câu ví dụ in đậm từ khoá,
/// mở Màn 09 (Sửa) và Màn 28 (Xác nhận xoá).
class WordDetailScreen extends StatefulWidget {
  final VocabularyModel vocabulary;
  final CollectionStore? store;
  final PronunciationService? pronunciation;

  const WordDetailScreen({
    super.key,
    required this.vocabulary,
    this.store,
    this.pronunciation,
  });

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  CollectionStore get _store => widget.store ?? CollectionStore.instance;
  PronunciationService get _audio => widget.pronunciation ?? PronunciationService.instance;

  static const Map<String, String> _posLabels = {
    'noun': 'n.',
    'verb': 'v.',
    'adj': 'adj.',
    'adv': 'adv.',
  };

  Future<void> _openEdit(VocabularyModel vocab) async {
    final saved = await Navigator.of(context).push<VocabularyModel>(
      MaterialPageRoute(
        builder: (_) => WordFormScreen(
          collectionId: vocab.collectionId,
          initialWord: vocab,
          store: widget.store,
        ),
      ),
    );
    if (saved != null && mounted) {
      AppToast.success(context, 'Đã cập nhật từ "${saved.term}"');
    }
  }

  Future<void> _confirmDelete(VocabularyModel vocab) async {
    final confirmed = await showDeleteWordDialog(context, vocab.term);
    if (!confirmed || !mounted) return;

    final removed = _store.deleteWord(vocab.id);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop(); // Quay lại Màn 06
    if (removed == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Đã xoá từ "${removed.term}"'),
          backgroundColor: AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Hoàn tác',
            textColor: AppColors.lightBlue,
            onPressed: () => _store.restoreWord(removed),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_store, _audio]),
      builder: (context, _) {
        // Đọc bản mới nhất từ store để phản ánh ngay thay đổi sau khi sửa.
        final vocab = _store.findWord(widget.vocabulary.id) ?? widget.vocabulary;
        final isPlaying = _audio.isPlaying(vocab.id);

        return Scaffold(
          backgroundColor: AppColors.mainBackground,
          appBar: AppBar(
            title: Text('Chi tiết từ vựng', style: AppTypography.headingMedium),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.primaryBlue),
                onPressed: () => _openEdit(vocab),
                tooltip: 'Sửa từ',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed),
                onPressed: () => _confirmDelete(vocab),
                tooltip: 'Xoá từ',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.screenMargin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(vocab, isPlaying),
                const SizedBox(height: AppDimensions.space20),
                _buildSection(
                  title: 'Nghĩa tiếng Việt',
                  icon: Icons.translate_rounded,
                  child: Text(
                    vocab.definitionVi,
                    style: AppTypography.bodyBold.copyWith(fontSize: 17, color: AppColors.textPrimary),
                  ),
                ),
                if (vocab.definitionEn.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.space16),
                  _buildSection(
                    title: 'Định nghĩa (English)',
                    icon: Icons.menu_book_rounded,
                    child: Text(vocab.definitionEn, style: AppTypography.bodyMedium),
                  ),
                ],
                if (vocab.exampleSentence.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.space16),
                  _buildSection(
                    title: 'Ví dụ câu ngữ cảnh',
                    icon: Icons.format_quote_rounded,
                    child: HighlightedSentence(sentence: vocab.exampleSentence, keyword: vocab.term),
                  ),
                ],
                const SizedBox(height: AppDimensions.space32),
                AppButton(
                  text: isPlaying ? 'Đang phát âm...' : 'Nghe phát âm (${_audio.accent.label})',
                  icon: const Icon(Icons.volume_up_rounded, color: AppColors.white),
                  onPressed: () => _audio.play(vocab),
                  isEnabled: !isPlaying,
                ),
                const SizedBox(height: AppDimensions.space16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(VocabularyModel vocab, bool isPlaying) {
    return Container(
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
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondaryBackground,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Text(
                  '[${_posLabels[vocab.partOfSpeech] ?? vocab.partOfSpeech}]',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.navyBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.space8),
              CefrBadge(level: vocab.cefrLevel),
              const Spacer(),
              // Nút phát âm tròn to chuẩn Figma (52dp ≥ 48dp)
              Semantics(
                button: true,
                label: 'Phát âm ${vocab.term}',
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _audio.play(vocab),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isPlaying ? AppColors.navyBlue : AppColors.softBlueSurface,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isPlaying
                          ? const SoundWaveIndicator(isActive: true, color: AppColors.white)
                          : const Icon(Icons.volume_up_outlined, color: AppColors.primaryBlue, size: 26),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space16),
          Text(
            vocab.term,
            style: AppTypography.displayLarge.copyWith(color: AppColors.navyBlue, fontSize: 32),
          ),
          if (vocab.ipa.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.space4),
            Text(
              vocab.ipa,
              style: AppTypography.headingMedium.copyWith(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: AppDimensions.space16),
          // Chọn giọng UK / US
          SegmentedButton<Accent>(
            segments: Accent.values
                .map((a) => ButtonSegment<Accent>(value: a, label: Text('Giọng ${a.label}')))
                .toList(),
            selected: {_audio.accent},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => _audio.accent = selection.first,
            style: SegmentedButton.styleFrom(
              minimumSize: const Size(0, AppDimensions.minTouchTarget),
              selectedBackgroundColor: AppColors.softBlueSurface,
              selectedForegroundColor: AppColors.navyBlue,
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.borderLight),
            ),
          ),
        ],
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
              Text(title, style: AppTypography.labelSmall.copyWith(fontSize: 13)),
            ],
          ),
          const SizedBox(height: AppDimensions.space12),
          child,
        ],
      ),
    );
  }
}

/// Câu ví dụ với từ khoá được in đậm & tô màu (khớp không phân biệt hoa thường,
/// bắt cả biến thể có hậu tố như "explore" → "explored").
class HighlightedSentence extends StatelessWidget {
  final String sentence;
  final String keyword;

  const HighlightedSentence({super.key, required this.sentence, required this.keyword});

  @override
  Widget build(BuildContext context) {
    final base = AppTypography.bodyLarge.copyWith(
      fontStyle: FontStyle.italic,
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w400,
    );
    final highlight = base.copyWith(fontWeight: FontWeight.w800, color: AppColors.navyBlue);

    final key = keyword.trim();
    if (key.isEmpty) return Text(sentence, style: base);

    final pattern = RegExp('\\b${RegExp.escape(key)}\\w*', caseSensitive: false);
    final spans = <TextSpan>[];
    var cursor = 0;
    for (final match in pattern.allMatches(sentence)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: sentence.substring(cursor, match.start)));
      }
      spans.add(TextSpan(text: match.group(0), style: highlight));
      cursor = match.end;
    }
    if (cursor < sentence.length) spans.add(TextSpan(text: sentence.substring(cursor)));

    return Text.rich(TextSpan(style: base, children: spans));
  }
}
