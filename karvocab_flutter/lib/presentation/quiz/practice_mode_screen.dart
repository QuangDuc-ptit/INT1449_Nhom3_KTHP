import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/state_widgets.dart';
import '../../data/mock/mock_vocab_data.dart';
import '../../data/models/quiz_models.dart';
import '../../data/models/vocabulary_model.dart';
import '../../data/repositories/quiz_question_factory.dart';
import 'quiz_session_screen.dart';

/// Màn 10 — Chọn chế độ luyện tập (tab "Luyện tập").
class PracticeModeScreen extends StatefulWidget {
  const PracticeModeScreen({super.key});

  @override
  State<PracticeModeScreen> createState() => _PracticeModeScreenState();
}

class _PracticeModeScreenState extends State<PracticeModeScreen> {
  String? _collectionId; // null = tất cả học phần
  int _questionCount = 10;

  static const List<int> _countOptions = [5, 10, 20];

  List<VocabularyModel> get _pool {
    final all = MockVocabData.initialVocabularies;
    if (_collectionId == null) return all;
    return all.where((v) => v.collectionId == _collectionId).toList();
  }

  IconData _iconOf(QuizMode mode) {
    switch (mode) {
      case QuizMode.listenChoose:
        return Icons.headphones_rounded;
      case QuizMode.listenType:
        return Icons.keyboard_voice_rounded;
      case QuizMode.meaningChoose:
        return Icons.translate_rounded;
      case QuizMode.recallType:
        return Icons.psychology_alt_rounded;
    }
  }

  void _start(QuizMode mode) {
    final questions = QuizQuestionFactory.build(
      mode: mode,
      pool: _pool,
      count: _questionCount,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizSessionScreen(questions: questions),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final collections = MockVocabData.initialCollections;
    final pool = _pool;

    return Scaffold(
      appBar: AppBar(
        title: Text('Luyện tập', style: AppTypography.headingLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.screenMargin,
          AppDimensions.space8,
          AppDimensions.screenMargin,
          AppDimensions.space24,
        ),
        children: [
          Text('Học phần', style: AppTypography.bodyBold),
          const SizedBox(height: AppDimensions.space8),
          SizedBox(
            height: AppDimensions.minTouchTarget,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterPill(
                  label: 'Tất cả',
                  selected: _collectionId == null,
                  onTap: () => setState(() => _collectionId = null),
                ),
                for (final c in collections)
                  _FilterPill(
                    label: c.title,
                    selected: _collectionId == c.id,
                    onTap: () => setState(() => _collectionId = c.id),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space16),
          Text('Số câu hỏi', style: AppTypography.bodyBold),
          const SizedBox(height: AppDimensions.space8),
          // Wrap thay Row: màn hẹp thì các nút tự xuống dòng thay vì tràn.
          Wrap(
            runSpacing: AppDimensions.space8,
            children: [
              for (final n in _countOptions)
                _FilterPill(
                  label: '$n câu',
                  selected: _questionCount == n,
                  onTap: () => setState(() => _questionCount = n),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.space24),
          if (pool.isEmpty)
            const SizedBox(
              height: 280,
              child: EmptyStateWidget(
                title: 'Học phần chưa có từ vựng',
                message: 'Thêm từ vào học phần này để bắt đầu luyện tập nhé.',
                icon: Icons.menu_book_outlined,
              ),
            )
          else ...[
            Text('${pool.length} từ sẵn sàng • chọn chế độ bên dưới',
                style: AppTypography.bodyMedium),
            const SizedBox(height: AppDimensions.space12),
            for (final mode in QuizMode.values) ...[
              _ModeCard(
                icon: _iconOf(mode),
                title: mode.title,
                description: mode.description,
                onTap: () => _start(mode),
              ),
              const SizedBox(height: AppDimensions.space12),
            ],
          ],
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppDimensions.space8),
      child: Material(
        color: selected ? AppColors.softBlueSurface : AppColors.white,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.primaryBlue : AppColors.borderLight,
            width: 1.5,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppDimensions.minTouchTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
              child: Center(
                child: Text(
                  label,
                  style: AppTypography.bodyBold.copyWith(
                    color: selected ? AppColors.primaryBlue : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        ),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.softBlueSurface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                ),
                child: Icon(icon, color: AppColors.primaryBlue, size: 28),
              ),
              const SizedBox(width: AppDimensions.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.headingMedium),
                    const SizedBox(height: AppDimensions.space4),
                    Text(description, style: AppTypography.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
