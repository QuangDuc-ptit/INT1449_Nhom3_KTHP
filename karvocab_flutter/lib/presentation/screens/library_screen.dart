import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/state_widgets.dart';
import '../../data/models/collection_model.dart';
import '../../data/mock/mock_vocab_data.dart';
import 'word_list_screen.dart';

/// Màn 05 · Thư viện học phần (Collections Library Screen)
/// Quản lý danh sách các bộ từ vựng, tìm kiếm, lọc theo chủ đề và tạo học phần mới
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  late List<CollectionModel> _collections;
  String _selectedCategory = 'all'; // 'all', 'academic', 'travel', 'life'
  String _searchQuery = '';

  final List<Map<String, String>> _categories = [
    {'key': 'all', 'label': 'Tất cả'},
    {'key': 'academic', 'label': 'Học thuật & IELTS'},
    {'key': 'travel', 'label': 'Du lịch'},
    {'key': 'life', 'label': 'Đời sống'},
  ];

  @override
  void initState() {
    super.initState();
    _collections = List.from(MockVocabData.initialCollections);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CollectionModel> get _filteredCollections {
    return _collections.where((col) {
      final matchesCategory = _selectedCategory == 'all' || col.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          col.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          col.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  // Màn 22: Modal tạo học phần mới
  void _openCreateCollectionModal() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String category = 'academic';

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
                    Text('Tạo học phần mới', style: AppTypography.headingMedium),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space16),

                // Tên học phần
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Tên học phần *',
                    hintText: 'ví dụ: Từ vựng Marketing B2',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppDimensions.space16),

                // Mô tả
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả ngắn',
                    hintText: 'ví dụ: Dùng ôn thi chứng chỉ trong tháng tới',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppDimensions.space16),

                // Chọn phân loại chủ đề
                Text('Chủ đề:', style: AppTypography.bodyBold),
                const SizedBox(height: AppDimensions.space8),
                Wrap(
                  spacing: 8,
                  children: [
                    {'key': 'academic', 'label': 'Học thuật'},
                    {'key': 'travel', 'label': 'Du lịch'},
                    {'key': 'life', 'label': 'Đời sống'},
                  ].map((cat) {
                    final isSel = category == cat['key'];
                    return ChoiceChip(
                      label: Text(cat['label']!),
                      selected: isSel,
                      onSelected: (val) => setModalState(() => category = cat['key']!),
                    );
                  }).toList(),
                ),

                const SizedBox(height: AppDimensions.space24),

                // Nút tạo
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
                      final title = titleController.text.trim();
                      if (title.isEmpty) return;

                      final newCol = CollectionModel(
                        id: 'col-${DateTime.now().millisecondsSinceEpoch}',
                        title: title,
                        description: descController.text.trim().isEmpty
                            ? 'Bộ sưu tập từ vựng cá nhân'
                            : descController.text.trim(),
                        category: category,
                        iconName: 'folder_special_rounded',
                        totalWords: 0,
                      );

                      setState(() {
                        _collections.insert(0, newCol);
                      });

                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã tạo học phần "$title" thành công!'),
                          backgroundColor: AppColors.successGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Text('Tạo học phần', style: AppTypography.buttonText),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'school_rounded':
        return Icons.school_rounded;
      case 'flight_takeoff_rounded':
        return Icons.flight_takeoff_rounded;
      case 'chat_bubble_outline_rounded':
        return Icons.chat_bubble_outline_rounded;
      default:
        return Icons.folder_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCollections;

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: Text('Thư viện học phần', style: AppTypography.headingLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryBlue, size: 28),
            onPressed: _openCreateCollectionModal,
            tooltip: 'Tạo học phần mới',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenMargin),
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
                  hintText: 'Tìm kiếm bộ từ vựng...',
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

          const SizedBox(height: AppDimensions.space12),

          // Bộ lọc Filter Chips (Scroll ngang)
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenMargin),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppDimensions.space8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat['key'];
                return ChoiceChip(
                  label: Text(cat['label']!),
                  labelStyle: AppTypography.labelSmall.copyWith(
                    color: isSelected ? AppColors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primaryBlue,
                  backgroundColor: AppColors.white,
                  side: BorderSide(
                    color: isSelected ? AppColors.primaryBlue : AppColors.borderLight,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                  ),
                  showCheckmark: false,
                  onSelected: (val) {
                    setState(() => _selectedCategory = cat['key']!);
                  },
                );
              },
            ),
          ),

          const SizedBox(height: AppDimensions.space16),

          // Danh sách các học phần
          Expanded(
            child: filtered.isEmpty
                ? EmptyStateWidget(
                    title: 'Không tìm thấy học phần nào',
                    message: _searchQuery.isNotEmpty
                        ? 'Thử thay đổi từ khoá tìm kiếm của bạn.'
                        : 'Bắt đầu học bằng cách tạo một học phần mới nhé!',
                    actionText: 'Tạo học phần ngay',
                    onAction: _openCreateCollectionModal,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenMargin),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.space16),
                    itemBuilder: (context, index) {
                      final col = filtered[index];
                      return _buildCollectionCard(col);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionCard(CollectionModel col) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                builder: (_) => WordListScreen(collection: col),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon hộp thoại chủ đề
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.softBlueSurface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  child: Icon(
                    _getIconData(col.iconName),
                    color: AppColors.primaryBlue,
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppDimensions.space16),

                // Nội dung học phần
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(col.title, style: AppTypography.headingMedium),
                      const SizedBox(height: AppDimensions.space4),
                      Text(
                        col.description,
                        style: AppTypography.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDimensions.space12),

                      // Pill số lượng từ vựng
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryBackground,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                        ),
                        child: Text(
                          '${col.totalWords} từ vựng',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.navyBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
