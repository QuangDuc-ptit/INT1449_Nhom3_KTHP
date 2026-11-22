import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/state_widgets.dart';
import '../../data/models/ai_vocab_draft.dart';
import '../../data/repositories/ai_vocab_repository.dart';
import 'ai_preview_screen.dart';

enum _GenState { idle, loading, error }

/// Màn 13 — Tạo từ vựng bằng AI (nhập chủ đề, chọn CEFR, chọn số lượng 3–20).
class AiGenerateScreen extends StatefulWidget {
  /// Cho phép tiêm repository khác (ví dụ bản gọi BE thật hoặc bản test).
  final AiVocabRepository? repository;

  /// Học phần đích chọn sẵn ở Màn 14 (mở từ Màn 06 của FE1). `null` = tạo học phần mới.
  final String? initialCollectionId;

  const AiGenerateScreen({super.key, this.repository, this.initialCollectionId});

  /// Chuyển `errorCode` của BE thành thông báo tiếng Việt cho Màn 13.
  @visibleForTesting
  static String aiErrorMessage(AiVocabException e) {
    switch (e.errorCode) {
      case 'RATE_LIMITED':
        final s = e.retryAfterSeconds;
        return s == null ? AppStrings.aiErrorRateLimited : AppStrings.aiErrorRateLimitedSeconds(s);
      case 'AI_TIMEOUT':
        return AppStrings.aiErrorTimeout;
      case 'AI_BAD_RESPONSE':
        return AppStrings.aiErrorBadResponse;
      case 'AI_UNAVAILABLE':
        return AppStrings.aiErrorUnavailable;
      case 'UNAUTHORIZED':
        return AppStrings.aiErrorUnauthorized;
      default:
        return e.message ?? AppStrings.aiErrorDefault;
    }
  }

  @override
  State<AiGenerateScreen> createState() => _AiGenerateScreenState();
}

class _AiGenerateScreenState extends State<AiGenerateScreen> with SingleTickerProviderStateMixin {
  static const int _maxTopicLength = 100;
  static const int _minWords = 3;
  static const int _maxWords = 20;
  static const List<String> _levels = ['A1', 'A2', 'B1', 'B2', 'C1'];

  final TextEditingController _topicController = TextEditingController();
  late final AnimationController _shimmer;
  late final AiVocabRepository _repo;

  String _level = 'B1';
  int _count = 5;
  _GenState _state = _GenState.idle;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? MockAiVocabRepository();
    _shimmer = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  }

  @override
  void dispose() {
    _topicController.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  bool get _canGenerate => _topicController.text.trim().isNotEmpty;

  Future<void> _generate() async {
    if (!_canGenerate) return;
    FocusScope.of(context).unfocus();
    setState(() => _state = _GenState.loading);
    _shimmer.repeat(reverse: true);

    try {
      final List<AiVocabDraft> drafts = await _repo
          .generate(topic: _topicController.text.trim(), cefrLevel: _level, wordCount: _count)
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      _shimmer.stop();
      setState(() => _state = _GenState.idle);
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => AiPreviewScreen(
            drafts: drafts,
            topic: _topicController.text.trim(),
            initialCollectionId: widget.initialCollectionId,
          ),
        ),
      );
      // Lưu xong thì đóng luôn Màn 13, quay về màn đã mở nó (Trang chủ hoặc Màn 06).
      if (saved == true && mounted) Navigator.of(context).pop(true);
    } on TimeoutException {
      _fail(AiGenerateScreen.aiErrorMessage(const AiVocabException('AI_TIMEOUT')));
    } on AiVocabException catch (e) {
      _fail(AiGenerateScreen.aiErrorMessage(e));
    } catch (_) {
      _fail(AppStrings.aiErrorConnection);
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    _shimmer.stop();
    setState(() {
      _state = _GenState.error;
      _errorMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.aiGenerateTitle, style: AppTypography.headingMedium)),
      body: SafeArea(
        child: switch (_state) {
          _GenState.loading => _buildLoading(),
          _GenState.error => _buildError(),
          _GenState.idle => _buildForm(),
        },
      ),
    );
  }

  Widget _buildError() {
    return Column(
      children: [
        Expanded(
          child: ErrorStateWidget(title: AppStrings.aiErrorTitle, errorMessage: _errorMessage, onRetry: _generate),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.screenMargin,
            0,
            AppDimensions.screenMargin,
            AppDimensions.space16,
          ),
          child: AppButton(
            text: AppStrings.aiBackToForm,
            variant: AppButtonVariant.outline,
            onPressed: () => setState(() => _state = _GenState.idle),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.screenMargin),
      child: Column(
        children: [
          const SizedBox(height: AppDimensions.space24),
          Image.asset(
            AppAssets.logo,
            width: AppDimensions.mascotIllustrationSize,
            height: AppDimensions.mascotIllustrationSize,
            excludeFromSemantics: true,
          ),
          const SizedBox(height: AppDimensions.space12),
          Text(AppStrings.aiLoadingTitle, style: AppTypography.headingMedium),
          const SizedBox(height: AppDimensions.space4),
          Text(AppStrings.aiLoadingSubtitle(_count, _level), style: AppTypography.bodyMedium),
          const SizedBox(height: AppDimensions.space24),
          for (var i = 0; i < 4; i++) ...[
            AnimatedBuilder(
              animation: _shimmer,
              builder: (context, _) {
                return Opacity(
                  opacity: 0.45 + _shimmer.value * 0.55,
                  child: Container(
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBackground,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppDimensions.space12),
          ],
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.screenMargin),
            children: [
              Text(AppStrings.aiTopicLabel, style: AppTypography.bodyBold),
              const SizedBox(height: AppDimensions.space8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
                constraints: const BoxConstraints(minHeight: AppDimensions.inputHeight),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: TextField(
                  controller: _topicController,
                  maxLength: _maxTopicLength,
                  maxLines: 2,
                  minLines: 1,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  style: AppTypography.bodyLarge,
                  decoration: InputDecoration(
                    hintText: AppStrings.aiTopicHint,
                    hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space8),
              Wrap(
                spacing: AppDimensions.space8,
                runSpacing: AppDimensions.space8,
                children: [
                  for (final s in AppStrings.aiTopicSuggestions)
                    _Pill(
                      label: s,
                      selected: false,
                      onTap: () {
                        _topicController.text = s;
                        _topicController.selection = TextSelection.collapsed(offset: s.length);
                        setState(() {});
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppDimensions.space24),
              Text(AppStrings.aiCefrLabel, style: AppTypography.bodyBold),
              const SizedBox(height: AppDimensions.space8),
              Row(
                children: [
                  for (final l in _levels)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: AppDimensions.space8),
                        child: _Pill(
                          label: l,
                          selected: _level == l,
                          expand: true,
                          onTap: () => setState(() => _level = l),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppDimensions.space24),
              Text(AppStrings.aiWordCountLabel(_minWords, _maxWords), style: AppTypography.bodyBold),
              const SizedBox(height: AppDimensions.space8),
              Row(
                children: [
                  _StepButton(
                    icon: Icons.remove_rounded,
                    tooltip: AppStrings.aiDecrease,
                    onPressed: _count > _minWords ? () => setState(() => _count--) : null,
                  ),
                  SizedBox(
                    width: 80,
                    child: Text('$_count', textAlign: TextAlign.center, style: AppTypography.headingLarge),
                  ),
                  _StepButton(
                    icon: Icons.add_rounded,
                    tooltip: AppStrings.aiIncrease,
                    onPressed: _count < _maxWords ? () => setState(() => _count++) : null,
                  ),
                ],
              ),
              // Công cụ kiểm thử Error State: chỉ hiện ở bản debug, ẩn ở bản phát hành.
              if (kDebugMode) ...[
                const SizedBox(height: AppDimensions.space16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(AppStrings.aiSimulateFailure, style: AppTypography.bodyMedium),
                  value: MockAiVocabRepository.simulateFailure,
                  onChanged: (v) => setState(() => MockAiVocabRepository.simulateFailure = v),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.screenMargin,
            AppDimensions.space8,
            AppDimensions.screenMargin,
            AppDimensions.space16,
          ),
          child: AppButton(
            text: AppStrings.aiGenerateButton,
            icon: const Icon(Icons.auto_awesome_rounded, color: AppColors.white, size: 20),
            isEnabled: _canGenerate,
            onPressed: _generate,
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final bool expand;
  final VoidCallback onTap;

  const _Pill({required this.label, required this.selected, required this.onTap, this.expand = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.softBlueSurface : AppColors.white,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? AppColors.primaryBlue : AppColors.borderLight, width: 1.5),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppDimensions.minTouchTarget),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: expand ? 0 : AppDimensions.space16),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: AppTypography.bodyBold.copyWith(
                    color: selected ? AppColors.primaryBlue : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _StepButton({required this.icon, required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: enabled ? AppColors.white : AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
        side: BorderSide(color: enabled ? AppColors.primaryBlue : AppColors.borderLight),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusButton)),
        onTap: onPressed,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: AppDimensions.buttonHeight,
            height: AppDimensions.buttonHeight,
            child: Icon(icon, color: enabled ? AppColors.primaryBlue : AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}
