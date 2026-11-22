import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/part_of_speech.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/vocabulary_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/collection_store.dart';
import '../../data/services/speech_service.dart';
import '../widgets/tag_input_field.dart';
import '../widgets/word_screen_header.dart';

/// Màn 09 · Sửa từ vựng & Màn 24 · Thêm từ vựng (dùng chung một form).
/// - Thứ tự trường: Từ tiếng Anh, IPA, Nghĩa tiếng Việt, Từ loại, Ví dụ, Từ đồng nghĩa,
///   Từ trái nghĩa, Trình độ, Ghi chú.
/// - Bắt buộc: Từ tiếng Anh, Nghĩa tiếng Việt. Không cho trùng từ trong cùng một học phần.
/// - Lưu qua [CollectionStore] (Demo Mode giữ trong bộ nhớ, Sprint 3 gọi API),
///   xong `pop` trả về bản ghi đã lưu.
class WordFormScreen extends StatefulWidget {
  final String collectionId;
  final VocabularyModel? initialWord;
  final CollectionStore? store;

  /// Tài khoản đang dùng, để áp hạn mức tổng số từ theo loại tài khoản (Màn 15).
  final AuthRepository? authRepository;

  const WordFormScreen({super.key, required this.collectionId, this.initialWord, this.store, this.authRepository});

  bool get isEditing => initialWord != null;

  @override
  State<WordFormScreen> createState() => _WordFormScreenState();
}

class _WordFormScreenState extends State<WordFormScreen> {
  static const List<String> cefrLevels = ['A1', 'A2', 'B1', 'B2', 'C1'];
  static const String defaultCefr = 'B1';

  late final TextEditingController _termController;
  late final TextEditingController _ipaController;
  late final TextEditingController _defViController;
  late final TextEditingController _exampleController;
  late final TextEditingController _noteController;
  final TextEditingController _synonymInput = TextEditingController();
  final TextEditingController _antonymInput = TextEditingController();
  late List<String> _synonyms;
  late List<String> _antonyms;

  late String _partOfSpeech;
  late String _cefrLevel;
  String? _termError;
  String? _defViError;

  CollectionStore get _store => widget.store ?? CollectionStore.instance;

  String get _collectionId => widget.initialWord?.collectionId ?? widget.collectionId;

  @override
  void initState() {
    super.initState();
    final w = widget.initialWord;
    _termController = TextEditingController(text: w?.term ?? '');
    _ipaController = TextEditingController(text: w?.ipa ?? '');
    _defViController = TextEditingController(text: w?.definitionVi ?? '');
    _exampleController = TextEditingController(text: w?.exampleSentence ?? '');
    _noteController = TextEditingController(text: w?.note ?? '');
    _synonyms = List.of(w?.synonyms ?? const <String>[]);
    _antonyms = List.of(w?.antonyms ?? const <String>[]);
    _partOfSpeech = PartOfSpeech.of(w?.partOfSpeech ?? '') != null ? w!.partOfSpeech : PartOfSpeech.defaultKey;
    _cefrLevel = cefrLevels.contains(w?.cefrLevel) ? w!.cefrLevel : defaultCefr;
  }

  @override
  void dispose() {
    _termController.dispose();
    _ipaController.dispose();
    _defViController.dispose();
    _exampleController.dispose();
    _noteController.dispose();
    _synonymInput.dispose();
    _antonymInput.dispose();
    super.dispose();
  }

  /// Chuẩn hoá IPA về dạng `/.../`.
  String _normalizeIpa(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return '';
    final core = v.replaceAll(RegExp(r'^/+|/+$'), '');
    return '/$core/';
  }

  void _save() {
    FocusScope.of(context).unfocus();
    final term = _termController.text.trim();
    var termError = Validators.term(term);
    if (termError == null && _store.isTermTaken(_collectionId, term, excludeId: widget.initialWord?.id)) {
      termError = AppStrings.wordFormDuplicate(term);
    }
    final defViError = Validators.required(_defViController.text, AppStrings.wordFormMeaningRequired);
    setState(() {
      _termError = termError;
      _defViError = defViError;
    });
    if (termError != null || defViError != null) return;

    if (!widget.isEditing) {
      final auth = widget.authRepository ?? AuthRepository.instance;
      final limitError = auth.wordLimitError(currentTotal: _store.totalWordCount, adding: 1);
      if (limitError != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(limitError)));
        return;
      }
    }

    // Chữ còn gõ dở trong ô đồng nghĩa / trái nghĩa vẫn được lưu thành thẻ.
    _synonyms = TagInputField.commitPending(_synonyms, _synonymInput);
    _antonyms = TagInputField.commitPending(_antonyms, _antonymInput);

    // Sửa từ: giữ nguyên các trường form không hiển thị (định nghĩa tiếng Anh...).
    final base =
        widget.initialWord ??
        VocabularyModel(
          id: '',
          collectionId: widget.collectionId,
          term: term,
          partOfSpeech: _partOfSpeech,
          ipa: '',
          definitionVi: '',
          definitionEn: '',
          exampleSentence: '',
          cefrLevel: _cefrLevel,
        );
    final word = base.copyWith(
      term: term,
      partOfSpeech: _partOfSpeech,
      ipa: _normalizeIpa(_ipaController.text),
      definitionVi: _defViController.text.trim(),
      exampleSentence: _exampleController.text.trim(),
      cefrLevel: _cefrLevel,
      note: _noteController.text.trim(),
      synonyms: List.unmodifiable(_synonyms),
      antonyms: List.unmodifiable(_antonyms),
    );

    final VocabularyModel saved;
    if (widget.isEditing) {
      _store.updateWord(word);
      saved = word;
    } else {
      saved = _store.addWord(word);
    }
    Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.isEditing;
    // Màn sửa hiện dữ liệu đã điền; màn thêm mới hiện gợi ý mẫu trong ô trống.
    String? hint(String text) => editing ? null : text;

    return Scaffold(
      backgroundColor: AppColors.practiceBackground,
      body: WordScreenBody(
        header: WordScreenHeader(title: editing ? AppStrings.wordFormEditTitle : AppStrings.wordFormAddTitle),
        children: [
          _FormGroup(
            label: AppStrings.wordFormTerm,
            child: _FormTextField(
              controller: _termController,
              hint: hint(AppStrings.wordFormTermHint),
              maxLength: 60,
              autofocus: !editing,
              errorText: _termError,
              onChanged: (_) {
                if (_termError != null) setState(() => _termError = null);
              },
              suffix: _buildListenButton(),
            ),
          ),
          _FormGroup(
            label: AppStrings.wordFormIpa,
            child: _FormTextField(controller: _ipaController, hint: hint(AppStrings.wordFormIpaHint), maxLength: 60),
          ),
          _FormGroup(
            label: AppStrings.wordFormMeaning,
            child: _FormTextField(
              controller: _defViController,
              hint: hint(AppStrings.wordFormMeaningHint),
              maxLength: 200,
              multiline: true,
              errorText: _defViError,
              onChanged: (_) {
                if (_defViError != null) setState(() => _defViError = null);
              },
            ),
          ),
          _FormGroup(
            label: AppStrings.wordFormPartOfSpeech,
            child: _FormSelect(
              fieldKey: const Key('word_form_pos'),
              value: _partOfSpeech,
              items: [for (final pos in PartOfSpeech.values) (pos.key, pos.label, pos.shortLabel)],
              onChanged: (key) => setState(() => _partOfSpeech = key),
            ),
          ),
          _FormGroup(
            label: AppStrings.wordFormExample,
            child: _FormTextField(
              controller: _exampleController,
              hint: hint(AppStrings.wordFormExampleHint),
              maxLength: 300,
              multiline: true,
            ),
          ),
          _FormGroup(
            label: AppStrings.wordFormSynonyms,
            child: TagInputField(
              key: const Key('word_form_synonyms'),
              values: _synonyms,
              controller: _synonymInput,
              hint: AppStrings.wordFormTagHint,
              onChanged: (v) => setState(() => _synonyms = v),
            ),
          ),
          _FormGroup(
            label: AppStrings.wordFormAntonyms,
            child: TagInputField(
              key: const Key('word_form_antonyms'),
              values: _antonyms,
              controller: _antonymInput,
              hint: AppStrings.wordFormTagHint,
              highlighted: false,
              onChanged: (v) => setState(() => _antonyms = v),
            ),
          ),
          _FormGroup(
            label: AppStrings.wordFormLevel,
            child: _FormSelect(
              fieldKey: const Key('word_form_level'),
              value: _cefrLevel,
              items: [
                for (final level in cefrLevels) (level, AppStrings.cefrOption(level), AppStrings.cefrOption(level)),
              ],
              onChanged: (level) => setState(() => _cefrLevel = level),
            ),
          ),
          _FormGroup(
            label: AppStrings.wordFormNote,
            last: true,
            child: _FormTextField(
              controller: _noteController,
              hint: hint(AppStrings.wordFormNoteHint),
              maxLength: 300,
              multiline: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
            ),
          ),
          const SizedBox(height: AppDimensions.wordFormSaveGap),
          AppButton(
            text: editing ? AppStrings.wordFormSaveChanges : AppStrings.aiDestinationTitle,
            onPressed: _save,
            height: AppDimensions.wordFormFieldHeight,
            borderRadius: AppDimensions.wordFormSaveRadius,
            textStyle: AppTypography.wordFormSave,
          ),
        ],
      ),
    );
  }

  /// Nghe thử phát âm từ đang nhập (TTS của máy), nằm gọn trong ô "Từ tiếng Anh".
  Widget _buildListenButton() {
    return ListenableBuilder(
      listenable: _termController,
      builder: (context, _) {
        final term = _termController.text.trim();
        return IconButton(
          key: const Key('word_form_listen'),
          tooltip: AppStrings.listenPronunciation,
          constraints: const BoxConstraints(
            minWidth: AppDimensions.minTouchTarget,
            minHeight: AppDimensions.minTouchTarget,
          ),
          icon: const Icon(Icons.volume_up_rounded, size: AppDimensions.iconSmall),
          color: AppColors.practicePrimary,
          disabledColor: AppColors.practiceTextSecondary,
          onPressed: term.isEmpty ? null : () => SpeechService.instance.speak(term),
        );
      },
    );
  }
}

/// Nhãn đặt phía trên ô nhập, kèm khoảng cách tới nhóm kế tiếp.
class _FormGroup extends StatelessWidget {
  final String label;
  final Widget child;
  final bool last;

  const _FormGroup({required this.label, required this.child, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : AppDimensions.wordFormGroupGap),
      // Gộp nhãn với ô nhập để trình đọc màn hình đọc nhãn khi focus vào ô.
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: AppTypography.wordFormLabel),
            const SizedBox(height: AppDimensions.wordFormLabelGap),
            child,
          ],
        ),
      ),
    );
  }
}

/// Viền dùng chung cho ô nhập và ô chọn: xanh rất nhạt, focus xanh đậm, lỗi đỏ.
InputDecoration _fieldDecoration({
  String? hint,
  String? errorText,
  Widget? suffix,
  double verticalPadding = AppDimensions.space16,
}) {
  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppDimensions.wordFormFieldRadius),
    borderSide: BorderSide(color: color, width: width),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: AppTypography.wordFormHint,
    errorText: errorText,
    errorStyle: AppTypography.wordFormError,
    filled: true,
    fillColor: AppColors.white,
    isDense: true,
    counterText: '',
    contentPadding: EdgeInsets.symmetric(horizontal: AppDimensions.wordFormFieldPaddingH, vertical: verticalPadding),
    suffixIcon: suffix,
    suffixIconConstraints: const BoxConstraints(
      minWidth: AppDimensions.minTouchTarget,
      minHeight: AppDimensions.minTouchTarget,
    ),
    enabledBorder: border(AppColors.practiceCardBorder, AppDimensions.borderThin),
    focusedBorder: border(AppColors.practicePrimary, AppDimensions.borderMedium),
    errorBorder: border(AppColors.errorRed, AppDimensions.borderThin),
    focusedErrorBorder: border(AppColors.errorRed, AppDimensions.borderMedium),
  );
}

class _FormTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final String? errorText;
  final int maxLength;
  final bool multiline;
  final bool autofocus;
  final Widget? suffix;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _FormTextField({
    required this.controller,
    required this.maxLength,
    this.hint,
    this.errorText,
    this.multiline = false,
    this.autofocus = false,
    this.suffix,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppDimensions.wordFormFieldHeight),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        maxLength: maxLength,
        // Câu dài thì ô tự cao thêm (tối đa 3 dòng) thay vì bị cắt chữ.
        minLines: 1,
        maxLines: multiline ? 3 : 1,
        textInputAction: textInputAction,
        style: AppTypography.wordFormInput,
        cursorColor: AppColors.practicePrimary,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: _fieldDecoration(hint: hint, errorText: errorText, suffix: suffix),
      ),
    );
  }
}

/// Ô chọn có chevron xuống. Mỗi mục là (giá trị, nhãn trong danh sách, nhãn khi đã chọn).
class _FormSelect extends StatelessWidget {
  final Key fieldKey;
  final String value;
  final List<(String, String, String)> items;
  final ValueChanged<String> onChanged;

  const _FormSelect({required this.fieldKey, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: fieldKey,
      initialValue: value,
      isExpanded: true,
      menuMaxHeight: AppDimensions.dropdownMenuMaxHeight,
      borderRadius: BorderRadius.circular(AppDimensions.wordFormFieldRadius),
      dropdownColor: AppColors.white,
      style: AppTypography.wordFormInput,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.practiceTextSecondary),
      // Dòng chữ của ô chọn cao hơn ô nhập nên dùng padding dọc riêng để cùng cao 52.
      decoration: _fieldDecoration(verticalPadding: AppDimensions.wordFormSelectPaddingV),
      selectedItemBuilder: (context) => [for (final item in items) Text(item.$3, overflow: TextOverflow.ellipsis)],
      items: [for (final item in items) DropdownMenuItem(value: item.$1, child: Text(item.$2))],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
