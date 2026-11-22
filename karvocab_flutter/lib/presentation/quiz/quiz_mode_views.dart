import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_durations.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/vocab_display.dart';
import '../../core/widgets/cefr_badge.dart';
import '../../data/models/quiz_models.dart';
import '../../data/services/speech_recognition_service.dart';
import '../../data/services/speech_service.dart';
import 'widgets/audio_play_button.dart';
import 'widgets/quiz_card.dart';
import 'widgets/quiz_option_tile.dart';
import 'widgets/typing_answer_field.dart';

/// Icon của từng chế độ, khớp với thẻ trò chơi ở Màn 10.
extension QuizModeIcon on QuizMode {
  IconData get icon {
    switch (this) {
      case QuizMode.listenChoose:
      case QuizMode.listenType:
        return Icons.headphones_rounded;
      case QuizMode.meaningChoose:
        return Icons.menu_book_rounded;
      case QuizMode.recallType:
        return Icons.edit_note_rounded;
      case QuizMode.pronunciation:
        return Icons.mic_rounded;
      case QuizMode.synonymAntonym:
        return Icons.compare_arrows_rounded;
    }
  }
}

/// Danh sách 4 thẻ đáp án A/B/C/D dùng chung cho Màn 08 và Màn 25.
class _OptionsList extends StatelessWidget {
  final QuizQuestion question;
  final QuizAnswerRecord? record;
  final ValueChanged<String> onSelect;

  const _OptionsList({
    required this.question,
    required this.record,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    const letters = AppStrings.quizOptionLetters;
    final answered = record != null;

    return Column(
      children: [
        for (var i = 0; i < question.options.length; i++) ...[
          if (i > 0) const SizedBox(height: AppDimensions.quizOptionGap),
          QuizOptionTile(
            letter: letters[i],
            text: question.options[i],
            state: _stateOf(question.options[i], answered),
            onTap: answered ? null : () => onSelect(question.options[i]),
          ),
        ],
      ],
    );
  }

  OptionVisualState _stateOf(String option, bool answered) {
    if (!answered) return OptionVisualState.idle;
    if (option == question.correctAnswer) return OptionVisualState.correct;
    if (option == record!.userAnswer) return OptionVisualState.wrong;
    return OptionVisualState.dimmed;
  }
}

/// Màn 08 — Luyện nghe chọn từ
class ListenChooseView extends StatelessWidget {
  final QuizQuestion question;
  final QuizAnswerRecord? record;
  final ValueChanged<String> onSubmit;

  const ListenChooseView({
    super.key,
    required this.question,
    required this.record,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        QuizCard(
          prompt: AppStrings.quizPromptListenChoose,
          child: AudioPlayButton(text: question.vocab.term),
        ),
        const SizedBox(height: AppDimensions.space20),
        _OptionsList(question: question, record: record, onSelect: onSubmit),
      ],
    );
  }
}

/// Màn 25 — Chọn nghĩa đúng
class MeaningChooseView extends StatelessWidget {
  final QuizQuestion question;
  final QuizAnswerRecord? record;
  final ValueChanged<String> onSubmit;

  const MeaningChooseView({
    super.key,
    required this.question,
    required this.record,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final v = question.vocab;
    return Column(
      children: [
        QuizCard(
          prompt: AppStrings.quizPromptMeaningChoose,
          child: Column(
            children: [
              Text(v.term, style: AppTypography.quizTerm, textAlign: TextAlign.center),
              const SizedBox(height: AppDimensions.space6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(child: Text(v.ipaText, style: AppTypography.quizIpa)),
                  IconButton(
                    tooltip: AppStrings.quizListenTooltip,
                    constraints: const BoxConstraints(
                      minWidth: AppDimensions.minTouchTarget,
                      minHeight: AppDimensions.minTouchTarget,
                    ),
                    icon: const Icon(Icons.volume_up_rounded, color: AppColors.practicePrimary),
                    onPressed: () => SpeechService.instance.speak(v.term),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space4),
              _WordTags(cefrLevel: v.cefrLevel, partOfSpeech: v.partOfSpeech),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.space20),
        _OptionsList(question: question, record: record, onSelect: onSubmit),
      ],
    );
  }
}

/// Màn 19 — Nghe và điền từ
class ListenTypeView extends StatelessWidget {
  final QuizQuestion question;
  final QuizAnswerRecord? record;
  final ValueChanged<String> onSubmit;

  const ListenTypeView({
    super.key,
    required this.question,
    required this.record,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        QuizCard(
          prompt: AppStrings.quizPromptListenType,
          child: AudioPlayButton(text: question.vocab.term),
        ),
        const SizedBox(height: AppDimensions.space20),
        TypingAnswerField(
          result: record?.result,
          onSubmit: onSubmit,
          hint: AppStrings.quizListenTypeHint,
        ),
      ],
    );
  }
}

/// Màn 20 — Nhớ từ qua nghĩa
class RecallTypeView extends StatelessWidget {
  final QuizQuestion question;
  final QuizAnswerRecord? record;
  final ValueChanged<String> onSubmit;

  const RecallTypeView({
    super.key,
    required this.question,
    required this.record,
    required this.onSubmit,
  });

  /// Che từ khoá trong câu ví dụ → "_____"
  String _blank(String sentence, String term) {
    return sentence.replaceAll(RegExp(RegExp.escape(term), caseSensitive: false), AppStrings.quizBlank);
  }

  @override
  Widget build(BuildContext context) {
    final v = question.vocab;
    return Column(
      children: [
        QuizCard(
          prompt: AppStrings.quizPromptRecallType,
          alignment: CrossAxisAlignment.start,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WordTags(cefrLevel: v.cefrLevel, partOfSpeech: v.partOfSpeech),
              const SizedBox(height: AppDimensions.space16),
              Text(AppStrings.quizMeaningLabel, style: AppTypography.quizCaption),
              const SizedBox(height: AppDimensions.space4),
              Text(v.definitionVi, style: AppTypography.quizDefinition),
              if (v.exampleSentence.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppDimensions.space16),
                  child: Divider(height: 1, color: AppColors.practiceCardBorder),
                ),
                Text(AppStrings.quizExampleLabel, style: AppTypography.quizCaption),
                const SizedBox(height: AppDimensions.space4),
                Text(_blank(v.exampleSentence, v.term), style: AppTypography.quizExample),
              ],
              const SizedBox(height: AppDimensions.space16),
              QuizChip(
                icon: Icons.lightbulb_outline_rounded,
                label: AppStrings.quizRecallHint(v.term[0], v.term.length),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.space20),
        TypingAnswerField(result: record?.result, onSubmit: onSubmit),
      ],
    );
  }
}

/// Game "Luyện phát âm": đọc to từ, máy nhận dạng giọng rồi chấm như câu gõ chữ.
class PronunciationView extends StatefulWidget {
  final QuizQuestion question;
  final QuizAnswerRecord? record;
  final ValueChanged<List<String>> onSubmit;
  final VoidCallback onSkip;

  const PronunciationView({
    super.key,
    required this.question,
    required this.record,
    required this.onSubmit,
    required this.onSkip,
  });

  @override
  State<PronunciationView> createState() => _PronunciationViewState();
}

class _PronunciationViewState extends State<PronunciationView> {
  bool _listening = false;
  String _heard = '';
  RecognitionFailure? _failure;

  SpeechRecognitionService get _recognizer => SpeechRecognitionService.instance;

  @override
  void dispose() {
    if (_listening) _recognizer.stop();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (widget.record != null) return;
    if (_listening) {
      await _recognizer.stop();
      return;
    }
    setState(() {
      _listening = true;
      _heard = '';
      _failure = null;
    });
    try {
      final alternatives = await _recognizer.listenOnce(
        onPartial: (text) {
          if (mounted) setState(() => _heard = text);
        },
      );
      if (!mounted) return;
      setState(() {
        _listening = false;
        _heard = alternatives.first;
      });
      widget.onSubmit(alternatives);
    } on RecognitionException catch (e) {
      if (mounted) {
        setState(() {
          _listening = false;
          _failure = e.failure;
        });
      }
    }
  }

  String? get _failureMessage {
    switch (_failure) {
      case RecognitionFailure.unavailable:
        return AppStrings.speakUnavailable;
      case RecognitionFailure.permissionDenied:
        return AppStrings.speakPermissionDenied;
      case RecognitionFailure.noSpeech:
        return AppStrings.speakNoSpeech;
      case null:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.question.vocab;
    final answered = widget.record != null;
    final message = _failureMessage;
    // Máy không nhận dạng được thì cho bỏ qua; còn "chưa nghe rõ" thì nói lại.
    final canSkip = !answered &&
        (_failure == RecognitionFailure.unavailable || _failure == RecognitionFailure.permissionDenied);

    return Column(
      children: [
        QuizCard(
          prompt: AppStrings.quizPromptPronunciation,
          child: Column(
            children: [
              Text(v.term, style: AppTypography.quizTerm, textAlign: TextAlign.center),
              const SizedBox(height: AppDimensions.space6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(child: Text(v.ipaText, style: AppTypography.quizIpa)),
                  IconButton(
                    tooltip: AppStrings.quizListenTooltip,
                    constraints: const BoxConstraints(
                      minWidth: AppDimensions.minTouchTarget,
                      minHeight: AppDimensions.minTouchTarget,
                    ),
                    icon: const Icon(Icons.volume_up_rounded, color: AppColors.practicePrimary),
                    onPressed: () => SpeechService.instance.speak(v.term),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space4),
              _WordTags(cefrLevel: v.cefrLevel, partOfSpeech: v.partOfSpeech),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.space24),
        _MicButton(listening: _listening, enabled: !answered, onTap: _toggle),
        const SizedBox(height: AppDimensions.space8),
        Text(
          _listening ? AppStrings.speakListening : AppStrings.speakTapToStart,
          style: AppTypography.quizCaption,
        ),
        if (_heard.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.space12),
          Text(AppStrings.speakHeard(_heard), style: AppTypography.quizOption, textAlign: TextAlign.center),
        ],
        if (message != null) ...[
          const SizedBox(height: AppDimensions.space12),
          Text(
            message,
            style: AppTypography.quizCaption.copyWith(color: AppColors.errorRed),
            textAlign: TextAlign.center,
          ),
        ],
        if (canSkip) ...[
          const SizedBox(height: AppDimensions.space8),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.practicePrimary,
              minimumSize: const Size(AppDimensions.dialogTextButtonMinWidth, AppDimensions.minTouchTarget),
            ),
            onPressed: widget.onSkip,
            child: const Text(AppStrings.speakSkip),
          ),
        ],
      ],
    );
  }
}

/// Nút micro tròn lớn: xanh khi chờ, đỏ kèm vòng sáng khi đang nghe.
class _MicButton extends StatelessWidget {
  final bool listening;
  final bool enabled;
  final VoidCallback onTap;

  const _MicButton({required this.listening, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = listening ? AppColors.errorRed : AppColors.practicePrimary;
    final halo = listening ? AppDimensions.quizAudioHaloSize : AppDimensions.quizAudioButtonSize;
    return SizedBox(
      width: AppDimensions.quizAudioHaloSize,
      height: AppDimensions.quizAudioHaloSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: AppDurations.fast,
            width: halo,
            height: halo,
            decoration: const BoxDecoration(color: AppColors.quizWrongTint, shape: BoxShape.circle),
          ),
          Semantics(
            button: true,
            label: AppStrings.speakMicSemantics,
            child: Material(
              color: enabled ? color : AppColors.practiceTextSecondary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: enabled ? onTap : null,
                child: SizedBox(
                  width: AppDimensions.quizAudioButtonSize,
                  height: AppDimensions.quizAudioButtonSize,
                  child: Icon(
                    listening ? Icons.stop_rounded : Icons.mic_rounded,
                    color: AppColors.white,
                    size: AppDimensions.quizAudioButtonSize * AppDimensions.quizAudioIconFactor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Game "Đồng nghĩa và trái nghĩa": cho 2 từ, chọn quan hệ giữa chúng.
class SynonymAntonymView extends StatelessWidget {
  final QuizQuestion question;
  final QuizAnswerRecord? record;
  final ValueChanged<String> onSubmit;

  const SynonymAntonymView({
    super.key,
    required this.question,
    required this.record,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final v = question.vocab;
    final pair = question.pairWord ?? '';
    return Column(
      children: [
        QuizCard(
          prompt: AppStrings.quizPromptSynonymAntonym,
          child: Column(
            children: [
              Text(v.term, style: AppTypography.quizTerm, textAlign: TextAlign.center),
              const SizedBox(height: AppDimensions.space12),
              Container(
                width: AppDimensions.quizFeedbackIconBox,
                height: AppDimensions.quizFeedbackIconBox,
                decoration: const BoxDecoration(color: AppColors.practiceSelectedFill, shape: BoxShape.circle),
                child: const Icon(
                  Icons.compare_arrows_rounded,
                  color: AppColors.practicePrimary,
                  size: AppDimensions.iconSmall,
                ),
              ),
              const SizedBox(height: AppDimensions.space12),
              Text(pair, style: AppTypography.quizTerm, textAlign: TextAlign.center),
              if (record != null) ...[
                const SizedBox(height: AppDimensions.space12),
                Text(
                  AppStrings.relationExplain(v.term, question.correctAnswer, pair),
                  style: AppTypography.quizCaption,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.space20),
        _OptionsList(question: question, record: record, onSelect: onSubmit),
      ],
    );
  }
}

/// Cấp CEFR + loại từ, đặt cạnh nhau.
class _WordTags extends StatelessWidget {
  final String cefrLevel;
  final String partOfSpeech;

  const _WordTags({required this.cefrLevel, required this.partOfSpeech});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.space8,
      runSpacing: AppDimensions.space8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        CefrBadge(level: cefrLevel),
        QuizChip(
          label: AppStrings.partOfSpeech(partOfSpeech),
          foreground: AppColors.practiceTextSecondary,
          background: AppColors.practiceBackground,
        ),
      ],
    );
  }
}
