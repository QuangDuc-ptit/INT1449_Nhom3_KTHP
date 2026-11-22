import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/cefr_badge.dart';
import '../../core/widgets/sound_wave_indicator.dart';
import '../../core/widgets/state_widgets.dart';
import '../../data/models/collection_model.dart';
import '../../data/models/vocabulary_model.dart';
import '../../data/repositories/collection_store.dart';
import '../../data/services/pronunciation_service.dart';
import '../ai_vocab/ai_generate_screen.dart';
import 'word_detail_screen.dart';
import 'word_form_screen.dart';

enum _AddWordChoice { manual, ai }

/// Màn 06 · Danh sách từ vựng theo học phần
/// Hỗ trợ tìm kiếm, nghe nhanh phát âm (kèm sóng âm), mở chi tiết, thêm từ mới.
class WordListScreen extends StatefulWidget {
  final CollectionModel collection;
  final CollectionStore? store;
  final PronunciationService? pronunciation;

  const WordListScreen({
    super.key,
    required this.collection,
    this.store,
    this.pronunciation,
  });

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  CollectionStore get _store => widget.store ?? CollectionStore.instance;
  PronunciationService get _audio => widget.pronunciation ?? PronunciationService.instance;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAddWord() async {
    final saved = await Navigator.of(context).push<VocabularyModel>(
      MaterialPageRoute(
        builder: (_) => WordFormScreen(collectionId: widget.collection.id, store: widget.store),
      ),
    );
    if (saved != null && mounted) {
      AppToast.success(context, 'Đã thêm từ "${saved.term}" vào học phần');
    }
  }

  /// Màn 13 (FE2): sinh từ bằng AI, học phần đích chọn sẵn là học phần đang xem.
  /// Lưu xong Màn 14 quay về đây (luồng §3.2: kết thúc ở Màn 06).
  Future<void> _openAiGenerate() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AiGenerateScreen(initialCollectionId: widget.collection.id),
      ),
    );
  }

  /// Nút "Thêm từ": chọn thêm thủ công (Màn 24) hoặc tạo bằng AI (Màn 13).
  Future<void> _openAddMenu() async {
    final choice = await showModalBottomSheet<_AddWordChoice>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusCard)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.space12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                key: const Key('add_word_manual'),
                minTileHeight: AppDimensions.minTouchTarget,
                leading: const Icon(Icons.edit_note_rounded, color: AppColors.primaryBlue),
                title: Text('Thêm thủ công', style: AppTypography.bodyBold),
                onTap: () => Navigator.of(sheetContext).pop(_AddWordChoice.manual),
              ),
              ListTile(
                key: const Key('add_word_ai'),
                minTileHeight: AppDimensions.minTouchTarget,
                leading: const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryBlue),
                title: Text('Tạo bằng AI', style: AppTypography.bodyBold),
                onTap: () => Navigator.of(sheetContext).pop(_AddWordChoice.ai),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case _AddWordChoice.manual:
        await _openAddWord();
      case _AddWordChoice.ai:
        await _openAiGenerate();
      case null:
        break;
    }
  }

  void _openDetail(VocabularyModel vocab) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WordDetailScreen(
          vocabulary: vocab,
          store: widget.store,
          pronunciation: widget.pronunciation,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_store, _audio]),
      builder: (context, _) {
        final collection = _store.findCollection(widget.collection.id) ?? widget.collection;
        final allWords = _store.wordsOf(collection.id);
        final filtered = _store.wordsOf(collection.id, query: _searchQuery);

        return Scaffold(
          backgroundColor: AppColors.mainBackground,
          appBar: AppBar(
            title: Column(
              children: [
                Text(
                  collection.title,
                  style: AppTypography.headingMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${allWords.length} từ vựng',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              if (allWords.isNotEmpty) _buildSearchBar(),
              Expanded(child: _buildList(allWords, filtered)),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openAddMenu,
            backgroundColor: AppColors.primaryBlue,
            icon: const Icon(Icons.add_rounded, color: AppColors.white),
            label: Text('Thêm từ', style: AppTypography.buttonText),
          ),
        );
      },
    );
  }

  Widget _buildList(List<VocabularyModel> allWords, List<VocabularyModel> filtered) {
    if (allWords.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.pets_rounded,
        title: 'Chưa có từ vựng',
        message: 'Hãy thêm từ đầu tiên vào học phần này nhé!',
        actionText: 'Thêm từ mới ngay',
        onAction: _openAddMenu,
      );
    }
    if (filtered.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.search_off_rounded,
        title: 'Không tìm thấy từ nào',
        message: 'Không có từ nào khớp với "$_searchQuery".',
        actionText: 'Xoá tìm kiếm',
        onAction: () {
          _searchController.clear();
          setState(() => _searchQuery = '');
        },
      );
    }
    return ListView.separated(
      // Chừa khoảng trống phía dưới để FAB không che từ cuối cùng
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.screenMargin,
        AppDimensions.space4,
        AppDimensions.screenMargin,
        96,
      ),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.space12),
      itemBuilder: (context, index) => _buildVocabRow(filtered[index]),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenMargin,
        vertical: AppDimensions.space12,
      ),
      child: Container(
        height: AppDimensions.minTouchTarget,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val.trim()),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm từ trong học phần...',
            hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: AppDimensions.iconCompact),
                    tooltip: 'Xoá tìm kiếm',
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: AppDimensions.space12),
          ),
        ),
      ),
    );
  }

  Widget _buildVocabRow(VocabularyModel vocab) {
    final isPlaying = _audio.isPlaying(vocab.id);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(
          color: isPlaying ? AppColors.lightBlue : AppColors.borderLight,
        ),
        boxShadow: AppShadows.cardSoft,
      ),
      child: Material(
        color: AppColors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          onTap: () => _openDetail(vocab),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              vocab.term,
                              style: AppTypography.headingMedium.copyWith(fontSize: AppTypography.fontSize17),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space8),
                          Text(
                            '[${vocab.partOfSpeech}.]',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      if (vocab.ipa.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.space4),
                        Text(
                          vocab.ipa,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppDimensions.space4),
                      Text(
                        vocab.definitionVi,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: AppTypography.fontSize14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.space8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CefrBadge(level: vocab.cefrLevel),
                    const SizedBox(height: AppDimensions.space4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isPlaying) const SoundWaveIndicator(isActive: true, height: AppDimensions.soundWaveInlineHeight),
                        IconButton(
                          icon: Icon(
                            isPlaying ? Icons.volume_up_rounded : Icons.volume_up_outlined,
                            color: AppColors.primaryBlue,
                          ),
                          onPressed: () => _audio.play(vocab),
                          tooltip: 'Phát âm "${vocab.term}"',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
