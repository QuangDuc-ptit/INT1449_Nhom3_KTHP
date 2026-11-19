import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/cefr_badge.dart';
import '../../core/widgets/state_widgets.dart';
import '../../data/models/ai_vocab_draft.dart';
import '../../data/repositories/collection_bridge.dart';

/// Màn 14 — Xem trước & lưu từ vựng AI (checkbox, sửa inline, chọn học phần đích).
class AiPreviewScreen extends StatefulWidget {
  final List<AiVocabDraft> drafts;
  final String topic;

  const AiPreviewScreen({super.key, required this.drafts, required this.topic});

  @override
  State<AiPreviewScreen> createState() => _AiPreviewScreenState();
}

class _AiPreviewScreenState extends State<AiPreviewScreen> {
  late final List<AiVocabDraft> _drafts;

  /// `null` = tạo học phần mới tên [_newCollectionName]
  String? _destinationId;
  late String _newCollectionName;

  @override
  void initState() {
    super.initState();
    _drafts = List.of(widget.drafts);
    final base = 'AI · ${widget.topic}';
    _newCollectionName = base.length > 50 ? base.substring(0, 50) : base;
  }

  int get _selectedCount => _drafts.where((d) => d.selected).length;
  bool get _allSelected => _drafts.isNotEmpty && _selectedCount == _drafts.length;

  String get _destinationLabel {
    if (_destinationId == null) return 'Tạo mới: $_newCollectionName';
    final matches = CollectionBridge.collections.where((c) => c.id == _destinationId);
    return matches.isEmpty ? _newCollectionName : matches.first.title;
  }

  Future<void> _editDraft(AiVocabDraft draft) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditDraftSheet(draft: draft),
    );
    if (changed == true && mounted) setState(() {});
  }

  Future<void> _pickDestination() async {
    final result = await showModalBottomSheet<_DestinationResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DestinationSheet(
        currentId: _destinationId,
        currentNewName: _newCollectionName,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _destinationId = result.collectionId;
      if (result.newName != null) _newCollectionName = result.newName!;
    });
  }

  void _save() {
    final chosen = _drafts.where((d) => d.selected).toList();
    if (chosen.isEmpty) return;

    final collectionId =
        _destinationId ?? CollectionBridge.createCollection(_newCollectionName);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final words = [
      for (var i = 0; i < chosen.length; i++)
        chosen[i].toVocabulary(collectionId, 'voc-ai-$stamp-$i'),
    ];
    CollectionBridge.addWords(collectionId, words);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
        content: Text('Đã thêm ${words.length} từ vào học phần'),
      ),
    );
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Xem trước từ vựng AI', style: AppTypography.headingMedium),
      ),
      body: SafeArea(
        child: _drafts.isEmpty
            ? EmptyStateWidget(
                title: 'AI chưa trả về từ nào',
                message: 'Hãy thử lại với chủ đề khác.',
                actionText: 'Quay lại',
                onAction: () => Navigator.of(context).pop(),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.screenMargin,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Đã chọn $_selectedCount/${_drafts.length} từ',
                            style: AppTypography.bodyBold,
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, AppDimensions.minTouchTarget),
                          ),
                          onPressed: () => setState(() {
                            final target = !_allSelected;
                            for (final d in _drafts) {
                              d.selected = target;
                            }
                          }),
                          child: Text(_allSelected ? 'Bỏ chọn tất cả' : 'Chọn tất cả'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimensions.screenMargin,
                        0,
                        AppDimensions.screenMargin,
                        AppDimensions.space16,
                      ),
                      itemCount: _drafts.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppDimensions.space12),
                      itemBuilder: (context, i) => _DraftCard(
                        draft: _drafts[i],
                        onToggle: (v) => setState(() => _drafts[i].selected = v),
                        onEdit: () => _editDraft(_drafts[i]),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.screenMargin,
                      AppDimensions.space12,
                      AppDimensions.screenMargin,
                      AppDimensions.space16,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      border: Border(top: BorderSide(color: AppColors.borderLight)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Material(
                          color: AppColors.secondaryBackground,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                          ),
                          child: InkWell(
                            customBorder: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                            ),
                            onTap: _pickDestination,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minHeight: AppDimensions.buttonHeight,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimensions.space16,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.folder_rounded, color: AppColors.primaryBlue),
                                    const SizedBox(width: AppDimensions.space12),
                                    Expanded(
                                      child: Text(
                                        _destinationLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.bodyBold,
                                      ),
                                    ),
                                    const Icon(Icons.expand_more_rounded,
                                        color: AppColors.textMuted),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space12),
                        AppButton(
                          text: 'Lưu $_selectedCount từ đã chọn',
                          isEnabled: _selectedCount > 0,
                          onPressed: _save,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _DraftCard extends StatelessWidget {
  final AiVocabDraft draft;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;

  const _DraftCard({
    required this.draft,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.space8,
        AppDimensions.space8,
        AppDimensions.space8,
        AppDimensions.space12,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
        border: Border.all(
          color: draft.selected ? AppColors.primaryBlue : AppColors.borderLight,
          width: draft.selected ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppDimensions.minTouchTarget,
            height: AppDimensions.minTouchTarget,
            child: Checkbox(
              value: draft.selected,
              activeColor: AppColors.primaryBlue,
              onChanged: (v) => onToggle(v ?? false),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: AppDimensions.space8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppDimensions.space8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(draft.term, style: AppTypography.headingMedium),
                      CefrBadge(level: draft.cefrLevel),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space4),
                  Text('[${draft.partOfSpeech}.]  ${draft.ipa}',
                      style: AppTypography.labelSmall),
                  const SizedBox(height: AppDimensions.space4),
                  Text(draft.definitionVi, style: AppTypography.bodyBold),
                  const SizedBox(height: AppDimensions.space4),
                  Text(
                    draft.exampleSentence,
                    style: AppTypography.bodyMedium.copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Sửa từ ${draft.term}',
            constraints: const BoxConstraints(
              minWidth: AppDimensions.minTouchTarget,
              minHeight: AppDimensions.minTouchTarget,
            ),
            icon: const Icon(Icons.edit_rounded, color: AppColors.primaryBlue),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet sửa nghĩa / câu ví dụ trước khi lưu.
class _EditDraftSheet extends StatefulWidget {
  final AiVocabDraft draft;
  const _EditDraftSheet({required this.draft});

  @override
  State<_EditDraftSheet> createState() => _EditDraftSheetState();
}

class _EditDraftSheetState extends State<_EditDraftSheet> {
  late final TextEditingController _meaning;
  late final TextEditingController _example;
  String? _error;

  @override
  void initState() {
    super.initState();
    _meaning = TextEditingController(text: widget.draft.definitionVi);
    _example = TextEditingController(text: widget.draft.exampleSentence);
  }

  @override
  void dispose() {
    _meaning.dispose();
    _example.dispose();
    super.dispose();
  }

  void _apply() {
    if (_meaning.text.trim().isEmpty) {
      setState(() => _error = 'Nghĩa tiếng Việt không được để trống');
      return;
    }
    widget.draft.definitionVi = _meaning.text.trim();
    widget.draft.exampleSentence = _example.text.trim();
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.screenMargin,
        AppDimensions.space24,
        AppDimensions.screenMargin,
        MediaQuery.of(context).viewInsets.bottom + AppDimensions.space24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Sửa "${widget.draft.term}"', style: AppTypography.headingMedium),
            const SizedBox(height: AppDimensions.space16),
            AppTextField(
              label: 'Nghĩa tiếng Việt',
              hintText: 'Nhập nghĩa...',
              controller: _meaning,
              errorText: _error,
            ),
            const SizedBox(height: AppDimensions.space16),
            AppTextField(
              label: 'Câu ví dụ',
              hintText: 'Nhập câu ví dụ...',
              controller: _example,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppDimensions.space24),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Hủy',
                    variant: AppButtonVariant.outline,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: AppDimensions.space12),
                Expanded(child: AppButton(text: 'Cập nhật', onPressed: _apply)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DestinationResult {
  final String? collectionId; // null = học phần mới
  final String? newName;
  const _DestinationResult({this.collectionId, this.newName});
}

/// Bottom sheet chọn học phần đích hoặc tạo học phần mới.
class _DestinationSheet extends StatefulWidget {
  final String? currentId;
  final String currentNewName;

  const _DestinationSheet({required this.currentId, required this.currentNewName});

  @override
  State<_DestinationSheet> createState() => _DestinationSheetState();
}

class _DestinationSheetState extends State<_DestinationSheet> {
  late final TextEditingController _name;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.currentNewName);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _createNew() {
    final name = _name.text.trim();
    if (name.length < 2 || name.length > 50) {
      setState(() => _error = 'Tên học phần phải từ 2 đến 50 ký tự');
      return;
    }
    Navigator.of(context).pop(_DestinationResult(newName: name));
  }

  @override
  Widget build(BuildContext context) {
    final collections = CollectionBridge.collections;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.screenMargin,
        AppDimensions.space24,
        AppDimensions.screenMargin,
        MediaQuery.of(context).viewInsets.bottom + AppDimensions.space24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Lưu vào học phần', style: AppTypography.headingMedium),
            const SizedBox(height: AppDimensions.space12),
            for (final c in collections)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  c.id == widget.currentId
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: AppColors.primaryBlue,
                ),
                title: Text(c.title, style: AppTypography.bodyBold),
                subtitle: Text('${c.totalWords} từ', style: AppTypography.labelSmall),
                onTap: () => Navigator.of(context).pop(_DestinationResult(collectionId: c.id)),
              ),
            const Divider(),
            const SizedBox(height: AppDimensions.space8),
            AppTextField(
              label: 'Hoặc tạo học phần mới',
              hintText: 'Tên học phần (2–50 ký tự)',
              controller: _name,
              errorText: _error,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppDimensions.space16),
            AppButton(
              text: 'Tạo học phần mới',
              variant: AppButtonVariant.secondary,
              onPressed: _createNew,
            ),
          ],
        ),
      ),
    );
  }
}
