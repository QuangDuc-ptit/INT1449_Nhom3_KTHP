import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/debouncer.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/state_widgets.dart';
import '../../data/models/collection_model.dart';
import '../../data/repositories/collection_store.dart';
import '../widgets/collection_form_sheet.dart';
import 'word_list_screen.dart';

/// Màn 05 · Thư viện học phần (Collections Library Screen)
/// - Tìm kiếm theo tên & mô tả với debounce 300ms.
/// - Lọc theo chủ đề bằng Filter Chips (lọc offline trên danh sách local).
/// - Đủ 3 trạng thái Loading / Error (có Thử lại) / Empty (có lối ra).
class LibraryScreen extends StatefulWidget {
  final CollectionStore? store;

  /// Chủ đề lọc sẵn — dùng lại màn này cho các màn Phân loại theo chủ đề (17, 18, 27).
  final String initialCategory;

  const LibraryScreen({super.key, this.store, this.initialCategory = 'all'});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 300));

  late String _selectedCategory;
  String _searchQuery = '';

  CollectionStore get _store => widget.store ?? CollectionStore.instance;

  static const Map<String, String> _filters = {
    'all': 'Tất cả',
    ...CollectionCategories.labels,
  };

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    // Gọi sau frame đầu để không notify listener khác (vd tab Hồ sơ) khi cây widget đang build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _store.ensureLoaded());
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {}); // cập nhật nút xoá (x) ngay lập tức
    _searchDebouncer.run(() {
      if (mounted) setState(() => _searchQuery = value.trim());
    });
  }

  void _clearSearch() {
    _searchDebouncer.cancel();
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  Future<void> _openCreateCollection() async {
    final created = await showCollectionFormSheet(context, store: _store);
    if (created == null || !mounted) return;
    AppToast.success(context, 'Đã tạo học phần "${created.title}"');
    _openCollection(created);
  }

  void _openCollection(CollectionModel col) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WordListScreen(collection: col, store: widget.store)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: Text('Thư viện học phần', style: AppTypography.headingLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryBlue, size: 28),
            onPressed: _openCreateCollection,
            tooltip: 'Tạo học phần mới',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              const SizedBox(height: AppDimensions.space12),
              _buildFilterChips(),
              const SizedBox(height: AppDimensions.space16),
              Expanded(child: _buildBody()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    switch (_store.status) {
      case LoadStatus.initial:
      case LoadStatus.loading:
        return const _CollectionSkeletonList();
      case LoadStatus.error:
        return ErrorStateWidget(
          title: 'Không tải được thư viện',
          errorMessage: _store.errorMessage ?? 'Đã có lỗi xảy ra.',
          onRetry: _store.load,
        );
      case LoadStatus.ready:
        break;
    }

    if (_store.collections.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.pets_rounded,
        title: 'Thư viện của bạn còn trống',
        message: 'Tạo học phần đầu tiên để bắt đầu lưu và ôn luyện từ vựng nhé!',
        actionText: 'Tạo học phần đầu tiên',
        onAction: _openCreateCollection,
      );
    }

    final filtered = _store.search(query: _searchQuery, category: _selectedCategory);
    if (filtered.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.search_off_rounded,
        title: 'Không tìm thấy học phần nào',
        message: _searchQuery.isNotEmpty
            ? 'Không có học phần khớp với "$_searchQuery". Thử từ khoá khác nhé.'
            : 'Chưa có học phần nào thuộc chủ đề này.',
        actionText: 'Xoá bộ lọc',
        onAction: () {
          _clearSearch();
          setState(() => _selectedCategory = 'all');
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () => _store.load(silent: true),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.screenMargin,
          0,
          AppDimensions.screenMargin,
          AppDimensions.space24,
        ),
        itemCount: filtered.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.space16),
        itemBuilder: (context, index) => _buildCollectionCard(filtered[index]),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenMargin),
      child: Container(
        height: AppDimensions.minTouchTarget,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm bộ từ vựng...',
            hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    tooltip: 'Xoá tìm kiếm',
                    onPressed: _clearSearch,
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final entries = _filters.entries.toList();
    return SizedBox(
      height: AppDimensions.minTouchTarget,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenMargin),
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppDimensions.space8),
        itemBuilder: (context, index) {
          final entry = entries[index];
          final isSelected = _selectedCategory == entry.key;
          return Center(
            child: ChoiceChip(
              label: Text(entry.value),
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
              onSelected: (_) => setState(() => _selectedCategory = entry.key),
            ),
          );
        },
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
          onTap: () => _openCollection(col),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.softBlueSurface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  child: Icon(
                    CollectionCategories.icon(col.iconName),
                    color: AppColors.primaryBlue,
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppDimensions.space16),
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
                      Wrap(
                        spacing: AppDimensions.space8,
                        runSpacing: AppDimensions.space4,
                        children: [
                          _pill('${col.totalWords} từ vựng', AppColors.secondaryBackground, AppColors.navyBlue),
                          if (CollectionCategories.labels[col.category] != null)
                            _pill(
                              CollectionCategories.labels[col.category]!,
                              AppColors.softBlueSurface,
                              AppColors.primaryBlue,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Skeleton loader cho danh sách học phần (đặc tả §6: không dùng spinner đơn điệu).
class _CollectionSkeletonList extends StatelessWidget {
  const _CollectionSkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenMargin),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.space16),
      itemBuilder: (_, _) => const SkeletonCard(),
    );
  }
}

/// Thẻ khung xương nhấp nháy nhẹ — dùng cho Loading State của các danh sách Track A.
class SkeletonCard extends StatefulWidget {
  final double height;

  const SkeletonCard({super.key, this.height = 112});

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Đang tải dữ liệu',
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.45, end: 1).animate(_controller),
        child: Container(
          height: widget.height,
          padding: const EdgeInsets.all(AppDimensions.space20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _block(50, 50, AppDimensions.radiusMedium),
              const SizedBox(width: AppDimensions.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _block(160, 16, 6),
                    const SizedBox(height: AppDimensions.space8),
                    _block(double.infinity, 12, 6),
                    const SizedBox(height: AppDimensions.space8),
                    _block(80, 12, 6),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _block(double width, double height, double radius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
