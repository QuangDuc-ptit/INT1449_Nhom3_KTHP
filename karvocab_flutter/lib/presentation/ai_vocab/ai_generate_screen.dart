import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/config/api_config.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/state_widgets.dart';
import '../../data/models/ai_vocab_draft.dart';
import '../../data/repositories/ai_vocab_repository.dart';
import '../../data/repositories/collection_bridge.dart';
import 'ai_preview_screen.dart';

enum _GenState { idle, loading, error }

/// Màn 13 — Tạo từ vựng bằng AI: nhập chủ đề (tiếng Anh / tiếng Việt), kéo chọn số lượng 3–20.
/// Không chọn CEFR: AI chọn từ hợp chủ đề, mỗi từ ghi đúng trình độ của nó.
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
  static const int _minTopicLength = AiVocabRepository.minTopicLength;
  static const int _maxTopicLength = AiVocabRepository.maxTopicLength;

  /// Bộ đếm ký tự chỉ hiện khi sắp chạm giới hạn, để ô chủ đề gọn một dòng.
  static const int _topicCounterFrom = 80;
  static const int _minWords = AiVocabRepository.minWordCount;
  static const int _maxWords = AiVocabRepository.maxWordCount;

  final TextEditingController _topicController = TextEditingController();
  late final AnimationController _shimmer;

  /// `null` khi chưa gọi được BE: màn hiện lý do và khoá nút tạo.
  late final AiVocabRepository? _repo;
  late final AiConnection _connection;

  int _count = 5;
  _GenState _state = _GenState.idle;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? AiVocabRepository.forCurrentSession();
    _connection = widget.repository != null ? AiConnection.ready : AiVocabRepository.connection;
    _shimmer = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  }

  @override
  void dispose() {
    _topicController.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  String get _topic => _topicController.text.trim();

  /// Chủ đề 1–2 ký tự: BE trả VALIDATION_ERROR, nên báo ngay dưới ô nhập.
  bool get _topicTooShort => _topic.isNotEmpty && _topic.length < _minTopicLength;

  bool get _canGenerate => _repo != null && _topic.length >= _minTopicLength;

  Future<void> _generate() async {
    final repo = _repo;
    if (repo == null || !_canGenerate) return;
    FocusScope.of(context).unfocus();
    setState(() => _state = _GenState.loading);
    _shimmer.repeat(reverse: true);

    try {
      // ApiClient tự ngắt theo ApiConfig.aiRequestTimeout; mốc này chỉ chặn trường hợp treo ngoài dự kiến.
      final initial = widget.initialCollectionId;
      final List<AiVocabDraft> drafts = await repo
          .generate(
            topic: _topic,
            wordCount: _count,
            // Mở từ một học phần: gửi id trên BE để AI tránh sinh lại từ đã có
            collectionId: initial == null ? null : CollectionBridge.store.resolveRemoteId(initial),
          )
          .timeout(ApiConfig.aiRequestTimeout + const Duration(seconds: 5));
      if (!mounted) return;
      _shimmer.stop();
      setState(() => _state = _GenState.idle);
      // BE bỏ từ trùng / sai định dạng nên có thể trả ít hơn số đã chọn: báo rõ.
      if (drafts.length < _count) AppToast.info(context, AppStrings.aiFewerWords(drafts.length, _count));
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) =>
              AiPreviewScreen(drafts: drafts, topic: _topic, initialCollectionId: widget.initialCollectionId),
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
          Text(AppStrings.aiLoadingSubtitle(_count), style: AppTypography.bodyMedium),
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
              if (_connection != AiConnection.ready) ...[
                _ConnectionNotice(connection: _connection),
                const SizedBox(height: AppDimensions.space16),
              ],
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
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) =>
                      currentLength >= _topicCounterFrom
                      ? Text('$currentLength/$maxLength', style: AppTypography.caption)
                      : null,
                  style: AppTypography.bodyLarge,
                  decoration: InputDecoration(
                    hintText: AppStrings.aiTopicHint,
                    hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (_topicTooShort) ...[
                const SizedBox(height: AppDimensions.space4),
                Text(
                  AppStrings.aiTopicTooShort(_minTopicLength),
                  key: const Key('ai_topic_too_short'),
                  style: AppTypography.caption.copyWith(color: AppColors.errorRed),
                ),
              ],
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
              Row(
                children: [
                  const Expanded(child: Text(AppStrings.aiWordCountTitle, style: AppTypography.bodyBold)),
                  Text(
                    AppStrings.aiWordCountValue(_count),
                    key: const Key('ai_word_count_value'),
                    style: AppTypography.bodyBold.copyWith(color: AppColors.primaryBlue),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primaryBlue,
                  inactiveTrackColor: AppColors.borderLight,
                  thumbColor: AppColors.primaryBlue,
                  overlayColor: AppColors.primaryBlue.withValues(alpha: 0.12),
                  activeTickMarkColor: AppColors.transparent,
                  inactiveTickMarkColor: AppColors.transparent,
                  valueIndicatorColor: AppColors.primaryBlue,
                ),
                child: Slider(
                  key: const Key('ai_word_count_slider'),
                  value: _count.toDouble(),
                  min: _minWords.toDouble(),
                  max: _maxWords.toDouble(),
                  divisions: _maxWords - _minWords,
                  label: '$_count',
                  semanticFormatterCallback: (v) => AppStrings.aiWordCountValue(v.round()),
                  onChanged: (v) => setState(() => _count = v.round()),
                ),
              ),
              Row(
                children: [
                  Text('$_minWords', style: AppTypography.caption),
                  const Spacer(),
                  Text('$_maxWords', style: AppTypography.caption),
                ],
              ),
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
  final VoidCallback onTap;

  const _Pill({required this.label, required this.selected, required this.onTap});

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
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
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

/// Lý do chưa tạo được từ bằng AI (không có máy chủ / chưa đăng nhập tài khoản).
class _ConnectionNotice extends StatelessWidget {
  final AiConnection connection;

  const _ConnectionNotice({required this.connection});

  @override
  Widget build(BuildContext context) {
    final needsLogin = connection == AiConnection.needsLogin;
    return Container(
      key: const Key('ai_connection_notice'),
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.primaryBlue, size: AppDimensions.iconMedium),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  needsLogin ? AppStrings.aiNeedsLoginTitle : AppStrings.aiNoServerTitle,
                  style: AppTypography.bodyBold,
                ),
                const SizedBox(height: AppDimensions.space4),
                Text(
                  needsLogin ? AppStrings.aiNeedsLoginMessage : AppStrings.aiNoServerMessage,
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
