import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_durations.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/state_widgets.dart';
import '../../data/repositories/collection_store.dart';
import '../library/library_controller.dart';
import '../library/library_sample_data.dart';
import '../library/library_ui_state.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/collection_form_sheet.dart';
import '../widgets/course_progress_ring.dart';
import 'word_list_screen.dart';

/// Màn 05 · Thư viện — nối [LibraryController] (dữ liệu) với [LibraryView]
/// (giao diện) và xử lý điều hướng: mở học phần, tạo học phần (Màn 22).
class LibraryScreen extends StatefulWidget {
  final CollectionStore? store;

  /// Chủ đề lọc sẵn ('all' = Tất cả) — dùng lại màn này cho các màn
  /// Phân loại theo chủ đề (17, 18, 27).
  final String initialCategory;

  const LibraryScreen({super.key, this.store, this.initialCategory = 'all'});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  CollectionStore get _store => widget.store ?? CollectionStore.instance;

  late final LibraryController _controller = LibraryController(
    store: _store,
    initialCategoryId: widget.initialCategory == 'all' ? null : widget.initialCategory,
  );

  @override
  void initState() {
    super.initState();
    // Gọi sau frame đầu để không notify listener khác (vd tab Hồ sơ) khi cây widget đang build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.ensureLoaded());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openCourse(String id) {
    final collection = _store.findCollection(id);
    if (collection == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WordListScreen(collection: collection, store: widget.store)),
    );
  }

  Future<void> _createCourse() async {
    final created = await showCollectionFormSheet(context, store: _store);
    if (created == null || !mounted) return;
    AppToast.success(context, AppStrings.libraryCourseCreated(created.title));
    _openCourse(created.id);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => LibraryView(
        state: _controller.state,
        onQueryChange: _controller.onQueryChange,
        onCategorySelect: _controller.onCategorySelect,
        onCourseClick: _openCourse,
        onCreateCourseClick: _createCourse,
        onRetry: _controller.retry,
        onRefresh: _controller.refresh,
      ),
    );
  }
}

/// Giao diện Màn 05 · Thư viện: chỉ đọc [state], mọi thao tác đưa ra callback.
///
/// Thanh điều hướng dưới do `MainShellScreen` vẽ chung cho các tab
/// (`AppBottomNavBar`), nên màn này không tự vẽ.
class LibraryView extends StatefulWidget {
  final LibraryUiState state;
  final ValueChanged<String> onQueryChange;

  /// `null` = chip "Tất cả".
  final ValueChanged<String?> onCategorySelect;
  final ValueChanged<String> onCourseClick;
  final VoidCallback onCreateCourseClick;
  final VoidCallback onRetry;

  /// Kéo xuống để tải lại; `null` = tắt.
  final Future<void> Function()? onRefresh;

  const LibraryView({
    super.key,
    required this.state,
    required this.onQueryChange,
    required this.onCategorySelect,
    required this.onCourseClick,
    required this.onCreateCourseClick,
    required this.onRetry,
    this.onRefresh,
  });

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  /// Nút "+" có vùng chạm 48dp, icon 28dp: lùi sang phải phần đệm này để icon thẳng lề 20dp.
  static const double _createButtonInset = (AppDimensions.minTouchTarget - AppDimensions.iconLarge) / 2;

  late final TextEditingController _searchController = TextEditingController(text: widget.state.query);

  @override
  void didUpdateWidget(covariant LibraryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_searchController.text != widget.state.query) {
      _searchController.value = TextEditingValue(
        text: widget.state.query,
        selection: TextSelection.collapsed(offset: widget.state.query.length),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scrollView = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverToBoxAdapter(child: _buildSearchField()),
        SliverToBoxAdapter(child: _buildCategoryChips()),
        ..._buildContent(),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: widget.onRefresh == null
            ? scrollView
            : RefreshIndicator(onRefresh: widget.onRefresh!, child: scrollView),
      ),
    );
  }

  // 1. Tiêu đề "Thư viện" + nút "+" tạo học phần.
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppDimensions.libraryHorizontalPadding,
        right: AppDimensions.libraryHorizontalPadding - _createButtonInset,
        top: AppDimensions.space12,
      ),
      child: Row(
        children: [
          const Expanded(child: Text(AppStrings.libraryTitle, style: AppTypography.libraryTitle)),
          IconButton(
            key: const Key('library_create_course'),
            onPressed: widget.onCreateCourseClick,
            tooltip: AppStrings.libraryCreateCourse,
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.navyBlue,
              size: AppDimensions.iconLarge,
            ),
          ),
        ],
      ),
    );
  }

  // 2. Ô tìm kiếm.
  Widget _buildSearchField() {
    final hasText = widget.state.query.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.libraryHorizontalPadding,
        AppDimensions.space16,
        AppDimensions.libraryHorizontalPadding,
        0,
      ),
      child: Container(
        height: AppDimensions.searchFieldHeight,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.searchFieldRadius),
          border: Border.all(color: AppColors.divider, width: AppDimensions.borderThin),
        ),
        child: Row(
          children: [
            const SizedBox(width: AppDimensions.space12),
            const Icon(Icons.search_rounded, size: AppDimensions.iconSmall, color: AppColors.authTextSecondary),
            Expanded(
              child: TextField(
                key: const Key('library_search'),
                controller: _searchController,
                onChanged: widget.onQueryChange,
                // Nút Search trên bàn phím: Flutter tự đóng bàn phím khi bấm.
                textInputAction: TextInputAction.search,
                style: AppTypography.searchInput,
                decoration: const InputDecoration(
                  hintText: AppStrings.librarySearchHint,
                  hintStyle: AppTypography.authBody,
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: AppDimensions.space8),
                ),
              ),
            ),
            if (hasText)
              IconButton(
                key: const Key('library_search_clear'),
                onPressed: () => widget.onQueryChange(''),
                tooltip: AppStrings.libraryClearSearch,
                icon: const Icon(Icons.close_rounded, size: AppDimensions.iconSmall, color: AppColors.authTextSecondary),
              ),
          ],
        ),
      ),
    );
  }

  // 3. Hàng chip lọc: "Tất cả" + các nhóm trong categories.
  Widget _buildCategoryChips() {
    final categories = widget.state.categories;
    return Padding(
      // Chip cao 36dp nhưng vùng chạm 48dp → trừ phần đệm để khoảng cách nhìn thấy đúng 12dp / 20dp.
      padding: const EdgeInsets.only(top: AppDimensions.space12 - AppDimensions.filterChipTouchInset),
      child: SizedBox(
        height: AppDimensions.minTouchTarget,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.libraryHorizontalPadding),
          itemCount: categories.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: AppDimensions.space8),
          itemBuilder: (context, index) {
            final id = index == 0 ? null : categories[index - 1].id;
            final label = index == 0 ? AppStrings.libraryAllCategories : categories[index - 1].name;
            return _FilterChip(
              label: label,
              selected: widget.state.selectedCategoryId == id,
              onTap: () => widget.onCategorySelect(id),
            );
          },
        ),
      ),
    );
  }

  // 4–5. Danh sách học phần / trạng thái tải, lỗi, trống.
  List<Widget> _buildContent() {
    const listPadding = EdgeInsets.fromLTRB(
      AppDimensions.libraryHorizontalPadding,
      AppDimensions.space20 - AppDimensions.filterChipTouchInset,
      AppDimensions.libraryHorizontalPadding,
      AppDimensions.space24,
    );
    final state = widget.state;

    switch (state.status) {
      case LibraryLoadStatus.loading:
        return [
          SliverPadding(
            padding: listPadding,
            sliver: SliverList.separated(
              itemCount: AppDimensions.skeletonCardCount,
              separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.space12),
              itemBuilder: (_, _) => const SkeletonCard(),
            ),
          ),
        ];
      case LibraryLoadStatus.error:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorStateWidget(
              title: AppStrings.libraryLoadErrorTitle,
              errorMessage: state.errorMessage ?? AppStrings.libraryLoadErrorFallback,
              onRetry: widget.onRetry,
            ),
          ),
        ];
      case LibraryLoadStatus.ready:
        break;
    }

    if (state.courses.isEmpty) {
      final noResults = state.isFiltering;
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyMessage(
            icon: noResults ? Icons.search_rounded : Icons.menu_book_rounded,
            message: noResults ? AppStrings.libraryNoResults : AppStrings.libraryEmpty,
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: listPadding,
        sliver: SliverList.separated(
          itemCount: state.courses.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.space12),
          itemBuilder: (context, index) {
            final course = state.courses[index];
            return CourseCard(course: course, onTap: () => widget.onCourseClick(course.id));
          },
        ),
      ),
    ];
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      side: selected
          ? BorderSide.none
          : const BorderSide(color: AppColors.divider, width: AppDimensions.borderThin),
    );
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        // Vùng chạm phủ cả phần đệm trên/dưới (đủ 48dp).
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Material(
            color: selected ? AppColors.navyBlue : AppColors.white,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Container(
                height: AppDimensions.filterChipHeight,
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: AppTypography.filterChip.copyWith(
                    color: selected ? AppColors.white : AppColors.authTextSecondary,
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

/// Thẻ học phần: ô icon sách · tên + trình độ + số từ · vòng tiến độ.
class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;

  const CourseCard({super.key, required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppDimensions.courseCardRadius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: radius,
        boxShadow: AppShadows.cardSoft,
      ),
      child: Material(
        color: AppColors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Row(
              children: [
                Container(
                  width: AppDimensions.libraryCourseIconBoxSize,
                  height: AppDimensions.libraryCourseIconBoxSize,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceTint,
                    borderRadius: BorderRadius.circular(AppDimensions.courseCardIconRadius),
                  ),
                  child: const Icon(Icons.menu_book_rounded, size: AppDimensions.iconMedium, color: AppColors.primaryBlue),
                ),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        course.name,
                        style: AppTypography.courseTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDimensions.space6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.levelBadgePaddingH,
                              vertical: AppDimensions.levelBadgePaddingV,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceTint,
                              borderRadius: BorderRadius.circular(AppDimensions.levelBadgeRadius),
                            ),
                            child: Text(course.level, style: AppTypography.levelBadge),
                          ),
                          const SizedBox(width: AppDimensions.space8),
                          Flexible(
                            child: Text(
                              AppStrings.libraryWordCount(course.wordCount),
                              style: AppTypography.courseMeta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.space12),
                CourseProgressRing(percent: course.progressPercent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyMessage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.libraryHorizontalPadding),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppDimensions.libraryEmptyIconSize, color: AppColors.authTextSecondary),
            const SizedBox(height: AppDimensions.space12),
            Text(message, style: AppTypography.authBody, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Thẻ khung xương nhấp nháy nhẹ — Loading State của danh sách học phần
/// (đặc tả §6: không dùng spinner đơn điệu). Cùng khung với [CourseCard].
class SkeletonCard extends StatefulWidget {
  const SkeletonCard({super.key});

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.pulse,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.libraryLoading,
      child: FadeTransition(
        opacity: Tween<double>(begin: AppDimensions.skeletonMinOpacity, end: 1).animate(_controller),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.space16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.courseCardRadius),
          ),
          child: Row(
            children: [
              _block(AppDimensions.libraryCourseIconBoxSize, AppDimensions.libraryCourseIconBoxSize, AppDimensions.courseCardIconRadius),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FractionallySizedBox(
                      widthFactor: AppDimensions.skeletonTitleWidthFactor,
                      child: _block(double.infinity, AppDimensions.space16, AppDimensions.levelBadgeRadius),
                    ),
                    const SizedBox(height: AppDimensions.space8),
                    FractionallySizedBox(
                      widthFactor: AppDimensions.skeletonMetaWidthFactor,
                      child: _block(double.infinity, AppDimensions.space12, AppDimensions.levelBadgeRadius),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Container(
                width: AppDimensions.progressRingSize,
                height: AppDimensions.progressRingSize,
                decoration: const BoxDecoration(color: AppColors.surfaceTint, shape: BoxShape.circle),
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
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Preview (Flutter Widget Previewer)
// -----------------------------------------------------------------------------

Widget _previewFrame(LibraryUiState state) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: LibraryView(
        state: state,
        onQueryChange: (_) {},
        onCategorySelect: (_) {},
        onCourseClick: (_) {},
        onCreateCourseClick: () {},
        onRetry: () {},
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 1, onTabSelected: (_) {}),
    ),
  );
}

@Preview(name: 'Thư viện · có dữ liệu', size: Size(390, 844))
Widget libraryFullPreview() => _previewFrame(LibrarySampleData.full);

@Preview(name: 'Thư viện · đang lọc theo nhóm', size: Size(390, 844))
Widget libraryFilteredPreview() => _previewFrame(LibrarySampleData.filtered);

@Preview(name: 'Thư viện · trống', size: Size(390, 844))
Widget libraryEmptyPreview() => _previewFrame(LibrarySampleData.empty);
