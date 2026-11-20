import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/vocabulary_model.dart';
import '../../data/repositories/collection_store.dart';

/// Màn 24 · Thêm từ vựng & Màn 09 · Sửa từ vựng (dùng chung một form).
/// - Bắt buộc: Từ tiếng Anh, Nghĩa tiếng Việt. Tuỳ chọn: IPA, định nghĩa EN, câu ví dụ.
/// - Không cho trùng từ trong cùng một học phần.
/// - Lưu xong `pop` trả về bản ghi đã lưu.
class WordFormScreen extends StatefulWidget {
  final String collectionId;
  final VocabularyModel? initialWord;
  final CollectionStore? store;

  const WordFormScreen({
    super.key,
    required this.collectionId,
    this.initialWord,
    this.store,
  });

  bool get isEditing => initialWord != null;

  @override
  State<WordFormScreen> createState() => _WordFormScreenState();
}

class _WordFormScreenState extends State<WordFormScreen> {
  static const List<String> partsOfSpeech = ['noun', 'verb', 'adj', 'adv'];
  static const Map<String, String> posLabels = {
    'noun': 'Danh từ (n.)',
    'verb': 'Động từ (v.)',
    'adj': 'Tính từ (adj.)',
    'adv': 'Trạng từ (adv.)',
  };
  static const List<String> cefrLevels = ['A1', 'A2', 'B1', 'B2', 'C1'];

  late final TextEditingController _termController;
  late final TextEditingController _ipaController;
  late final TextEditingController _defViController;
  late final TextEditingController _defEnController;
  late final TextEditingController _exampleController;

  late String _partOfSpeech;
  late String _cefrLevel;
  String? _termError;
  String? _defViError;

  CollectionStore get _store => widget.store ?? CollectionStore.instance;

  @override
  void initState() {
    super.initState();
    final w = widget.initialWord;
    _termController = TextEditingController(text: w?.term ?? '');
    _ipaController = TextEditingController(text: w?.ipa ?? '');
    _defViController = TextEditingController(text: w?.definitionVi ?? '');
    _defEnController = TextEditingController(text: w?.definitionEn ?? '');
    _exampleController = TextEditingController(text: w?.exampleSentence ?? '');
    _partOfSpeech = partsOfSpeech.contains(w?.partOfSpeech) ? w!.partOfSpeech : 'noun';
    _cefrLevel = cefrLevels.contains(w?.cefrLevel) ? w!.cefrLevel : 'B1';
  }

  @override
  void dispose() {
    _termController.dispose();
    _ipaController.dispose();
    _defViController.dispose();
    _defEnController.dispose();
    _exampleController.dispose();
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
    if (termError == null &&
        _store.isTermTaken(widget.collectionId, term, excludeId: widget.initialWord?.id)) {
      termError = 'Từ "$term" đã có trong học phần này';
    }
    final defViError = Validators.required(_defViController.text, 'Vui lòng nhập nghĩa tiếng Việt');
    setState(() {
      _termError = termError;
      _defViError = defViError;
    });
    if (termError != null || defViError != null) return;

    final word = VocabularyModel(
      id: widget.initialWord?.id ?? '',
      collectionId: widget.initialWord?.collectionId ?? widget.collectionId,
      term: term,
      partOfSpeech: _partOfSpeech,
      ipa: _normalizeIpa(_ipaController.text),
      definitionVi: _defViController.text.trim(),
      definitionEn: _defEnController.text.trim(),
      exampleSentence: _exampleController.text.trim(),
      cefrLevel: _cefrLevel,
      isMastered: widget.initialWord?.isMastered ?? false,
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
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Sửa từ vựng' : 'Thêm từ vựng',
          style: AppTypography.headingMedium,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Huỷ',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.screenMargin),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      label: 'Từ tiếng Anh *',
                      hintText: 'ví dụ: resilient',
                      controller: _termController,
                      maxLength: 60,
                      autofocus: !widget.isEditing,
                      errorText: _termError,
                      onChanged: (_) {
                        if (_termError != null) setState(() => _termError = null);
                      },
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    AppTextField(
                      label: 'Phiên âm IPA',
                      hintText: 'ví dụ: /rɪˈzɪliənt/',
                      controller: _ipaController,
                      maxLength: 60,
                    ),
                    const SizedBox(height: AppDimensions.space16),

                    _buildLabel('Loại từ'),
                    _buildChoiceWrap(
                      options: partsOfSpeech,
                      labelOf: (pos) => posLabels[pos]!,
                      selected: _partOfSpeech,
                      onSelected: (pos) => setState(() => _partOfSpeech = pos),
                    ),
                    const SizedBox(height: AppDimensions.space16),

                    AppTextField(
                      label: 'Nghĩa tiếng Việt *',
                      hintText: 'ví dụ: kiên cường, mau phục hồi',
                      controller: _defViController,
                      maxLines: 2,
                      maxLength: 200,
                      errorText: _defViError,
                      onChanged: (_) {
                        if (_defViError != null) setState(() => _defViError = null);
                      },
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    AppTextField(
                      label: 'Định nghĩa tiếng Anh',
                      hintText: 'ví dụ: Able to recover quickly from difficulties.',
                      controller: _defEnController,
                      maxLines: 3,
                      maxLength: 300,
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    AppTextField(
                      label: 'Câu ví dụ',
                      hintText: 'ví dụ: Children are often very resilient.',
                      controller: _exampleController,
                      maxLines: 3,
                      maxLength: 300,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: AppDimensions.space16),

                    _buildLabel('Cấp độ CEFR'),
                    _buildChoiceWrap(
                      options: cefrLevels,
                      labelOf: (level) => level,
                      selected: _cefrLevel,
                      onSelected: (level) => setState(() => _cefrLevel = level),
                    ),
                  ],
                ),
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
                text: widget.isEditing ? 'Lưu thay đổi' : 'Lưu vào học phần',
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: AppDimensions.space8),
        child: Text(text, style: AppTypography.bodyBold.copyWith(fontSize: AppTypography.fontSize14)),
      );

  Widget _buildChoiceWrap({
    required List<String> options,
    required String Function(String) labelOf,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: AppDimensions.space8,
      runSpacing: AppDimensions.space8,
      children: options.map((option) {
        final isSelected = option == selected;
        return ChoiceChip(
          label: Text(labelOf(option)),
          labelStyle: AppTypography.labelSmall.copyWith(
            color: isSelected ? AppColors.white : AppColors.textSecondary,
          ),
          selected: isSelected,
          selectedColor: AppColors.primaryBlue,
          backgroundColor: AppColors.white,
          showCheckmark: false,
          side: BorderSide(color: isSelected ? AppColors.primaryBlue : AppColors.borderLight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          ),
          materialTapTargetSize: MaterialTapTargetSize.padded,
          onSelected: (_) => onSelected(option),
        );
      }).toList(),
    );
  }
}
