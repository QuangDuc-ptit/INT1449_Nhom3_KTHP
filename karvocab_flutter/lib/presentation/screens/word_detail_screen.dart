import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_durations.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/part_of_speech.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/review_schedule.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/cefr_badge.dart';
import '../../core/widgets/sound_wave_indicator.dart';
import '../../data/models/vocabulary_model.dart';
import '../../data/repositories/collection_store.dart';
import '../../data/repositories/dashboard_store.dart';
import '../../data/services/pronunciation_service.dart';
import '../widgets/delete_word_dialog.dart';
import '../widgets/word_screen_header.dart';
import 'word_form_screen.dart';

/// Màn 07 · Chi tiết từ vựng.
/// Thẻ từ (trình độ, từ loại, từ, IPA, nút phát âm), nghĩa tiếng Việt, ví dụ,
/// tiến độ học (cấp SM-2, lịch ôn lại), ghi chú, từ đồng nghĩa / trái nghĩa
/// và nút xoá (Màn 28 xác nhận).
/// Bút chì mở Màn 09 (Sửa) với dữ liệu hiện tại; màn này luôn đọc bản mới nhất
/// từ [CollectionStore] nên lưu xong quay về là thấy nội dung mới.
class WordDetailScreen extends StatefulWidget {
  final VocabularyModel vocabulary;
  final CollectionStore? store;
  final PronunciationService? pronunciation;

  /// Tiến độ ôn tập (mặc định [DashboardStore.instance]).
  final DashboardStore? dashboard;

  const WordDetailScreen({super.key, required this.vocabulary, this.store, this.pronunciation, this.dashboard});

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  CollectionStore get _store => widget.store ?? CollectionStore.instance;
  PronunciationService get _audio => widget.pronunciation ?? PronunciationService.instance;
  DashboardStore get _dashboard => widget.dashboard ?? DashboardStore.instance;

  Future<void> _openEdit(VocabularyModel vocab) async {
    final saved = await Navigator.of(context).push<VocabularyModel>(
      MaterialPageRoute(
        builder: (_) => WordFormScreen(collectionId: vocab.collectionId, initialWord: vocab, store: widget.store),
      ),
    );
    if (saved != null && mounted) {
      AppToast.success(context, AppStrings.wordDetailUpdated(saved.term));
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
          content: Text(AppStrings.wordDetailDeleted(removed.term)),
          backgroundColor: AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: AppStrings.wordDetailUndo,
            textColor: AppColors.lightBlue,
            onPressed: () => _store.restoreWord(removed),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_store, _audio, _dashboard]),
      builder: (context, _) {
        // Đọc bản mới nhất từ store để phản ánh ngay thay đổi sau khi sửa.
        final vocab = _store.findWord(widget.vocabulary.id) ?? widget.vocabulary;

        return Scaffold(
          backgroundColor: AppColors.practiceBackground,
          body: WordScreenBody(
            header: WordScreenHeader(
              title: AppStrings.wordDetailTitle,
              trailing: IconButton(
                key: const Key('word_detail_edit'),
                tooltip: AppStrings.wordDetailEdit,
                constraints: const BoxConstraints(
                  minWidth: AppDimensions.minTouchTarget,
                  minHeight: AppDimensions.minTouchTarget,
                ),
                icon: const Icon(Icons.edit_outlined, color: AppColors.practicePrimary),
                onPressed: () => _openEdit(vocab),
              ),
            ),
            children: [
              _WordCard(vocab: vocab, audio: _audio),
              const SizedBox(height: AppDimensions.wordDetailSectionGap),
              const _Label(AppStrings.wordDetailMeaning),
              const SizedBox(height: AppDimensions.space8),
              Text(vocab.definitionVi, style: AppTypography.wordDetailMeaning),
              if (vocab.definitionEn.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.space6),
                Text(
                  vocab.definitionEn,
                  style: AppTypography.wordDetailBody.copyWith(color: AppColors.practiceTextSecondary),
                ),
              ],
              if (vocab.exampleSentence.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.wordDetailBlockGap),
                _TintBlock(
                  label: AppStrings.wordDetailExample,
                  child: HighlightedSentence(sentence: vocab.exampleSentence, keyword: vocab.term),
                ),
              ],
              const SizedBox(height: AppDimensions.wordDetailBlockGap),
              _ProgressBlock(progress: _dashboard.progressOf(vocab.id)),
              if (vocab.note.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.space12),
                _TintBlock(
                  label: AppStrings.wordDetailNoteLabel,
                  child: Text(vocab.note, style: AppTypography.wordDetailBody),
                ),
              ],
              if (vocab.synonyms.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.wordDetailBlockGap),
                _WordGroup(title: AppStrings.wordDetailSynonyms, words: vocab.synonyms, highlighted: true),
              ],
              if (vocab.antonyms.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.wordDetailBlockGap),
                _WordGroup(title: AppStrings.wordDetailAntonyms, words: vocab.antonyms, highlighted: false),
              ],
              const SizedBox(height: AppDimensions.wordDetailSectionGap),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('word_detail_delete'),
                  onPressed: () => _confirmDelete(vocab),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.errorRed,
                    minimumSize: const Size(0, AppDimensions.minTouchTarget),
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space4),
                    textStyle: AppTypography.wordDetailGroupTitle,
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: AppDimensions.iconSmall),
                  label: const Text(AppStrings.wordDetailDelete),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Tiến độ học của từ: trạng thái (Chưa học / Đang học cấp n/5 / Đã thuộc) và lịch ôn lại.
class _ProgressBlock extends StatelessWidget {
  final SrsProgress? progress;

  const _ProgressBlock({required this.progress});

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final String status;
    final Color color;
    if (p == null || p.repetitionLevel == 0) {
      status = AppStrings.wordProgressNew;
      color = AppColors.practiceTextSecondary;
    } else if (p.mastered) {
      status = AppStrings.wordProgressMastered;
      color = AppColors.successGreen;
    } else {
      status = AppStrings.wordProgressLearning(p.repetitionLevel, Sm2Engine.maxLevel);
      color = AppColors.practicePrimary;
    }
    final due = p == null ? AppStrings.wordProgressNoSchedule : reviewDueText(p.nextReviewAt, DateTime.now());

    return _TintBlock(
      label: AppStrings.wordDetailProgress,
      child: Column(
        key: const Key('word_detail_progress'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(status, style: AppTypography.wordDetailBody.copyWith(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppDimensions.space4),
          Text(due, style: AppTypography.wordDetailBody.copyWith(color: AppColors.practiceTextSecondary)),
        ],
      ),
    );
  }
}

/// Thẻ trắng: trình độ + từ loại, từ, IPA; nút phát âm vuông bên phải.
class _WordCard extends StatelessWidget {
  final VocabularyModel vocab;
  final PronunciationService audio;

  const _WordCard({required this.vocab, required this.audio});

  @override
  Widget build(BuildContext context) {
    final isPlaying = audio.isPlaying(vocab.id);
    return Container(
      padding: const EdgeInsets.all(AppDimensions.wordDetailCardPadding),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.wordDetailCardRadius),
        border: Border.all(color: AppColors.practiceCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CefrBadge(level: vocab.cefrLevel),
              const SizedBox(width: AppDimensions.space8),
              Flexible(
                child: Text(
                  PartOfSpeech.shortLabelOf(vocab.partOfSpeech),
                  style: AppTypography.quizCaption,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vocab.term, style: AppTypography.wordDetailTerm),
                    if (vocab.ipa.isNotEmpty) ...[
                      const SizedBox(height: AppDimensions.space4),
                      Text(vocab.ipa, style: AppTypography.wordDetailIpa),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              _SpeakButton(term: vocab.term, isPlaying: isPlaying, onTap: () => audio.play(vocab)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpeakButton extends StatelessWidget {
  final String term;
  final bool isPlaying;
  final VoidCallback onTap;

  const _SpeakButton({required this.term, required this.isPlaying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppDimensions.wordDetailSpeakRadius);
    return Semantics(
      button: true,
      label: AppStrings.wordDetailSpeak(term),
      child: Material(
        color: isPlaying ? AppColors.practicePrimary : AppColors.practiceSelectedFill,
        borderRadius: radius,
        child: InkWell(
          key: const Key('word_detail_speak'),
          borderRadius: radius,
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppDurations.fast,
            width: AppDimensions.wordDetailSpeakSize,
            height: AppDimensions.wordDetailSpeakSize,
            alignment: Alignment.center,
            child: isPlaying
                ? const SoundWaveIndicator(isActive: true, color: AppColors.white)
                : const Icon(Icons.volume_up_rounded, color: AppColors.practicePrimary, size: AppDimensions.iconMedium),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final Color color;

  const _Label(this.text, {this.color = AppColors.practiceTextSecondary});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(text, style: AppTypography.wordDetailLabel.copyWith(color: color)),
    );
  }
}

/// Khối nền xanh nhạt có nhãn (Ví dụ sử dụng, Ghi chú).
class _TintBlock extends StatelessWidget {
  final String label;
  final Widget child;

  const _TintBlock({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.wordDetailExamplePadding),
      decoration: BoxDecoration(
        color: AppColors.practiceSelectedFill,
        borderRadius: BorderRadius.circular(AppDimensions.wordDetailCardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label(label, color: AppColors.practicePrimary),
          const SizedBox(height: AppDimensions.space8),
          child,
        ],
      ),
    );
  }
}

/// Nhóm từ đồng nghĩa (chip xanh) hoặc trái nghĩa (chip trắng, chữ xám).
class _WordGroup extends StatelessWidget {
  final String title;
  final List<String> words;
  final bool highlighted;

  const _WordGroup({required this.title, required this.words, required this.highlighted});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: Text(title, style: AppTypography.wordDetailGroupTitle)),
        const SizedBox(height: AppDimensions.space10),
        Wrap(
          spacing: AppDimensions.space8,
          runSpacing: AppDimensions.space8,
          children: [
            for (final word in words)
              Container(
                constraints: const BoxConstraints(minHeight: AppDimensions.wordDetailChipHeight),
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space12),
                decoration: BoxDecoration(
                  color: highlighted ? AppColors.practiceSelectedFill : AppColors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.wordDetailChipRadius),
                  border: highlighted ? null : Border.all(color: AppColors.practiceCardBorder),
                ),
                child: Center(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppDimensions.space8),
                    child: Text(
                      word,
                      style: AppTypography.wordDetailChip.copyWith(
                        color: highlighted ? AppColors.practicePrimary : AppColors.practiceTextSecondary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
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
    const base = AppTypography.wordDetailBody;
    final highlight = base.copyWith(fontWeight: FontWeight.w800, color: AppColors.practicePrimary);

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
