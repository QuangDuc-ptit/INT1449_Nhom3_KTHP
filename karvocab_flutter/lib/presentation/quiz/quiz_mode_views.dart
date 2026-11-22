import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/vocab_display.dart';
import '../../core/widgets/cefr_badge.dart';
import '../../data/models/quiz_models.dart';
import '../../data/services/speech_service.dart';
import 'widgets/audio_play_button.dart';
import 'widgets/quiz_option_tile.dart';
import 'widgets/typing_answer_field.dart';

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
          QuizOptionTile(
            letter: letters[i],
            text: question.options[i],
            state: _stateOf(question.options[i], answered),
            onTap: answered ? null : () => onSelect(question.options[i]),
          ),
          if (i < question.options.length - 1)
            const SizedBox(height: AppDimensions.space12),
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

class _Prompt extends StatelessWidget {
  final String text;
  const _Prompt(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTypography.bodyMedium, textAlign: TextAlign.center);
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
        const _Prompt(AppStrings.quizPromptListenChoose),
        const SizedBox(height: AppDimensions.space24),
        AudioPlayButton(text: question.vocab.term),
        const SizedBox(height: AppDimensions.space32),
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
        const _Prompt(AppStrings.quizPromptMeaningChoose),
        const SizedBox(height: AppDimensions.space16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.space20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              CefrBadge(level: v.cefrLevel),
              const SizedBox(height: AppDimensions.space8),
              Text(v.term, style: AppTypography.displayLarge, textAlign: TextAlign.center),
              const SizedBox(height: AppDimensions.space4),
              Text(v.ipaText, style: AppTypography.bodyMedium),
              const SizedBox(height: AppDimensions.space8),
              IconButton(
                tooltip: AppStrings.quizListenTooltip,
                constraints: const BoxConstraints(
                  minWidth: AppDimensions.minTouchTarget,
                  minHeight: AppDimensions.minTouchTarget,
                ),
                icon: const Icon(Icons.volume_up_rounded, color: AppColors.primaryBlue),
                onPressed: () => SpeechService.instance.speak(v.term),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.space24),
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
        const _Prompt(AppStrings.quizPromptListenType),
        const SizedBox(height: AppDimensions.space24),
        AudioPlayButton(text: question.vocab.term),
        const SizedBox(height: AppDimensions.space32),
        TypingAnswerField(
          locked: record != null,
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
        const _Prompt(AppStrings.quizPromptRecallType),
        const SizedBox(height: AppDimensions.space16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.space20),
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
                  CefrBadge(level: v.cefrLevel),
                  const SizedBox(width: AppDimensions.space8),
                  Text(AppStrings.partOfSpeech(v.partOfSpeech), style: AppTypography.labelSmall),
                ],
              ),
              const SizedBox(height: AppDimensions.space12),
              Text(v.definitionVi, style: AppTypography.headingMedium),
              const SizedBox(height: AppDimensions.space12),
              Text(
                _blank(v.exampleSentence, v.term),
                style: AppTypography.bodyMedium.copyWith(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: AppDimensions.space12),
              Text(
                AppStrings.quizRecallHint(v.term[0], v.term.length),
                style: AppTypography.labelSmall.copyWith(color: AppColors.infoBlue),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.space24),
        TypingAnswerField(locked: record != null, onSubmit: onSubmit),
      ],
    );
  }
}
