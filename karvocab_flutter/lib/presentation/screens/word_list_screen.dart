import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/cefr_badge.dart';
import '../../core/widgets/state_widgets.dart';
import '../../data/models/collection_model.dart';
import '../../data/models/vocabulary_model.dart';
import '../../data/mock/mock_vocab_data.dart';
import 'word_detail_screen.dart';

/// Màn 06 · Từ vựng hằng ngày / Danh sách từ vựng theo học phần
/// Hỗ trợ tìm kiếm, nghe nhanh phát âm, mở chi tiết và thêm từ mới
class WordListScreen extends StatefulWidget {
  final CollectionModel collection;

  const WordListScreen({super.key, required this.collection});

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  final TextEditingController _searchController = TextEditingController();
  late List<VocabularyModel> _words;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Lấy các từ thuộc collection này từ MockVocabData
    _words = MockVocabData.initialVocabularies
        .where((w) => w.collectionId == widget.collection.id)
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<VocabularyModel> get _filteredWords {
    if (_searchQuery.isEmpty) return _words;
    return _words.where((w) {
      final q = _searchQuery.toLowerCase();
      return w.term.toLowerCase().contains(q) ||
          w.definitionVi.toLowerCase().contains(q) ||
          w.definitionEn.toLowerCase().contains(q);
    }).toList();
  }

  void _handleQuickPlayAudio(VocabularyModel vocab) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.volume_up_rounded, color: AppColors.white, size: 20),
            const SizedBox(width: AppDimensions.space8),
            Text('Phát âm: ${vocab.term} ${vocab.ipa}'),
          ],
        ),
        backgroundColor: AppColors.primaryBlue,
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Màn 24: Modal thêm từ vựng mới
  void _openAddWordDialog() {
    final termController = TextEditingController();
    final defViController = TextEditingController();
    final ipaController = TextEditingController();
    String selectedCefr = 'B1';
    String selectedPos = 'noun';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            left: AppDimensions.screenMargin,
            right: AppDimensions.screenMargin,
            top: AppDimensions.space24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppDimensions.space24,
          ),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusCard)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Thêm từ vựng mới', style: AppTypography.headingMedium),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space16),

                // Từ tiếng Anh
                TextField(
                  controller: termController,
                  decoration: const InputDecoration(
                    labelText: 'Từ tiếng Anh *',
                    hintText: 'ví dụ: resilient',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppDimensions.space12),

                // Phiên âm IPA
                TextField(
                  controller: ipaController,
                  decoration: const InputDecoration(
                    labelText: 'Phiên âm IPA',
                    hintText: 'ví dụ: /rɪˈzɪliənt/',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppDimensions.space12),

                // Nghĩa tiếng Việt
                TextField(
                  controller: defViController,
                  decoration: const InputDecoration(
                    labelText: 'Nghĩa tiếng Việt *',
                    hintText: 'ví dụ: kiên cường, mau phục hồi',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppDimensions.space16),

                // Chọn CEFR Level
                Row(
                  children: [
                    Text('Cấp độ:', style: AppTypography.bodyBold),
                    const SizedBox(width: AppDimensions.space12),
                    Wrap(
                      spacing: 8,
                      children: ['A1', 'A2', 'B1', 'B2', 'C1'].map((level) {
                        final isSel = selectedCefr == level;
                        return ChoiceChip(
                          label: Text(level),
                          selected: isSel,
                          onSelected: (val) => setModalState(() => selectedCefr = level),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space24),

                // Nút Lưu
                SizedBox(
                  width: double.infinity,
                  height: AppDimensions.buttonHeight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                      ),
                    ),
                    onPressed: () {
                      final term = termController.text.trim();
                      final defVi = defViController.text.trim();
                      if (term.isEmpty || defVi.isEmpty) return;

                      final newVocab = VocabularyModel(
                        id: 'voc-${DateTime.now().millisecondsSinceEpoch}',
                        collectionId: widget.collection.id,
                        term: term,
                        partOfSpeech: selectedPos,
                        ipa: ipaController.text.trim().isEmpty ? '/.../' : ipaController.text.trim(),
                        definitionVi: defVi,
                        definitionEn: 'Custom user defined vocabulary.',
                        exampleSentence: 'Example sentence with $term.',
                        cefrLevel: selectedCefr,
                      );

                      setState(() {
                        _words.insert(0, newVocab);
                      });

                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã thêm từ "$term" thành công!'),
                          backgroundColor: AppColors.successGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Text('Lưu vào học phần', style: AppTypography.buttonText),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredWords;

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.collection.title, style: AppTypography.headingMedium),
            Text(
              '${_words.length} từ vựng',
              style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm trong học phần
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenMargin,
              vertical: AppDimensions.space12,
            ),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm từ trong học phần...',
                  hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Danh sách từ vựng (ListView cuộn mượt)
          Expanded(
            child: filtered.isEmpty
                ? EmptyStateWidget(
                    title: _searchQuery.isEmpty ? 'Chưa có từ vựng' : 'Không tìm thấy từ nào',
                    message: _searchQuery.isEmpty
                        ? 'Hãy thêm từ đầu tiên vào học phần này nhé!'
                        : 'Thử tìm với từ khóa khác xem sao.',
                    actionText: _searchQuery.isEmpty ? 'Thêm từ mới ngay' : null,
                    onAction: _searchQuery.isEmpty ? _openAddWordDialog : null,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppDimensions.screenMargin),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.space12),
                    itemBuilder: (context, index) {
                      final vocab = filtered[index];
                      return _buildVocabRow(vocab);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddWordDialog,
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add_rounded, color: AppColors.white),
        label: Text('Thêm từ', style: AppTypography.buttonText),
      ),
    );
  }

  Widget _buildVocabRow(VocabularyModel vocab) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WordDetailScreen(
                  vocabulary: vocab,
                  onDelete: () {
                    setState(() {
                      _words.removeWhere((w) => w.id == vocab.id);
                    });
                  },
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Row(
              children: [
                // Thông tin từ vựng bên trái
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            vocab.term,
                            style: AppTypography.headingMedium.copyWith(fontSize: 17),
                          ),
                          const SizedBox(width: AppDimensions.space8),
                          Text(
                            '[${vocab.partOfSpeech}]',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.space4),
                      Text(
                        vocab.ipa,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space4),
                      Text(
                        vocab.definitionVi,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AppDimensions.space8),

                // Badge CEFR & Nút Loa bên phải
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CefrBadge(level: vocab.cefrLevel),
                    const SizedBox(height: AppDimensions.space8),
                    IconButton(
                      icon: const Icon(Icons.volume_up_outlined, color: AppColors.primaryBlue),
                      onPressed: () => _handleQuickPlayAudio(vocab),
                      tooltip: 'Phát âm',
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
