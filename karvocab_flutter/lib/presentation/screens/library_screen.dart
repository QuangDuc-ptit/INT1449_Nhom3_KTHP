import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_durations.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/state_widgets.dart';
import '../../data/repositories/collection_store.dart';
import '../library/library_controller.dart';
import '../library/library_sample_data.dart';
import '../library/library_ui_state.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/collection_form_sheet.dart';
import '../widgets/collection_actions.dart';
import '../widgets/course_icon.dart';
import '../widgets/tab_header.dart';
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
      MaterialPageRoute(
        builder: (_) => WordListScreen(collection: collection, store: widget.store),
      ),
    );
  }

  Future<void> _openCourseMenu(String id) async {
    final collection = _store.findCollection(id);
    if (collection == null) return;
    await showCollectionActions(context, collection: collection, store: _store);
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
        onCourseMenuClick: _openCourseMenu,
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
/// (`AppBottomNavBar`), nên màn này không tự vẽ. Màn rộng: nội dung tối đa
/// 1040dp, thẻ học phần chia 2 cột từ 600dp và 3 cột từ 960dp.
class LibraryView extends StatefulWidget {
  final LibraryUiState state;
  final ValueChanged<String> onQueryChange;

  /// `null` = chip "Tất cả".
  final ValueChanged<String?> onCategorySelect;
  final ValueChanged<String> onCourseClick;

  /// Nút ⋮ trên thẻ (Sửa / Xoá học phần); `null` = ẩn nút.
  final ValueChanged<String>? onCourseMenuClick;
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
    this.onCourseMenuClick,
    this.onRefresh,
  });

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  late final TextEditingController _searchController = TextEditingController(text: widget.state.query);
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() => setState(() {}));
  }

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
    _searchFocus.dispose();
    super.dispose();
  }

  void _clearFilters() {
    widget.onQueryChange('');
    widget.onCategorySelect(null);
  }

  /// Thẻ tổng quan chỉ hiện khi đang xem toàn bộ thư viện (không tìm / lọc).
  bool get _showOverview =>
      widget.state.status == LibraryLoadStatus.ready && !widget.state.isFiltering && widget.state.courses.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.practiceBackground,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Lề hai bên: tối thiểu 20dp, màn rộng thì căn giữa khối nội dung 1040dp.
            final side = math.max(
              AppDimensions.libraryHorizontalPadding,
              (constraints.maxWidth - AppDimensions.libraryContentMaxWidth) / 2,
            );
            final contentWidth = constraints.maxWidth - side * 2;
            final columns = contentWidth >= AppDimensions.libraryThreeColumnWidth
                ? 3
                : contentWidth >= AppDimensions.libraryTwoColumnWidth
                ? 2
                : 1;
            final scrollView = CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(side)),
                if (_showOverview) SliverToBoxAdapter(child: _buildOverview(side)),
                SliverToBoxAdapter(child: _buildSearchField(side)),
                SliverToBoxAdapter(child: _buildCategoryChips(side)),
                ..._buildContent(side, columns),
              ],
            );
            return widget.onRefresh == null
                ? scrollView
                : RefreshIndicator(onRefresh: widget.onRefresh!, child: scrollView);
          },
        ),
      ),
    );
  }

  // 1. Tiêu đề "Thư viện" + nút "+" tạo học phần.
  Widget _buildHeader(double side) {
    final radius = BorderRadius.circular(AppDimensions.libraryCreateButtonRadius);
    return Padding(
      padding: EdgeInsets.fromLTRB(side, AppDimensions.space16, side, 0),
      child: TabHeader(
        title: AppStrings.libraryTitle,
        trailing: Tooltip(
          message: AppStrings.libraryCreateCourse,
          child: Material(
            color: AppColors.actionPrimary,
            borderRadius: radius,
            child: InkWell(
              key: const Key('library_create_course'),
              borderRadius: radius,
              onTap: widget.onCreateCourseClick,
              child: const SizedBox.square(
                dimension: AppDimensions.minTouchTarget,
                child: Icon(Icons.add_rounded, color: AppColors.white, size: AppDimensions.iconLarge),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 2. Thẻ tổng quan: số từ đã thuộc / tổng số từ, số học phần, thanh tiến độ.
  Widget _buildOverview(double side) {
    final courses = widget.state.courses;
    final total = courses.fold<int>(0, (sum, c) => sum + c.wordCount);
    final mastered = courses.fold<int>(0, (sum, c) => sum + c.masteredCount);
    return Padding(
      padding: EdgeInsets.fromLTRB(side, AppDimensions.space20, side, 0),
      child: Container(
        key: const Key('library_overview'),
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.space20,
          AppDimensions.space16,
          AppDimensions.space12,
          AppDimensions.space16,
        ),
        decoration: BoxDecoration(
          color: AppColors.actionPrimary,
          borderRadius: BorderRadius.circular(AppDimensions.libraryOverviewRadius),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.libraryOverviewMastered(mastered, total), style: AppTypography.libraryOverviewTitle),
                  const SizedBox(height: AppDimensions.space4),
                  Text(AppStrings.libraryOverviewCourses(courses.length), style: AppTypography.libraryOverviewMeta),
                  const SizedBox(height: AppDimensions.space12),
                  _ProgressBar(value: total == 0 ? 0 : mastered / total),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Image.asset(
              AppAssets.logo,
              width: AppDimensions.libraryOverviewLogoSize,
              height: AppDimensions.libraryOverviewLogoSize,
              excludeFromSemantics: true,
            ),
          ],
        ),
      ),
    );
  }

  // 3. Ô tìm kiếm.
  Widget _buildSearchField(double side) {
    final hasText = widget.state.query.isNotEmpty;
    final focused = _searchFocus.hasFocus;
    return Padding(
      padding: EdgeInsets.fromLTRB(side, AppDimensions.space20, side, 0),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        height: AppDimensions.searchFieldHeight,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.searchFieldRadius),
          border: Border.all(
            color: focused ? AppColors.actionPrimary : AppColors.practiceCardBorder,
            width: focused ? AppDimensions.borderMedium : AppDimensions.borderThin,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: AppDimensions.space12),
            Icon(
              Icons.search_rounded,
              size: AppDimensions.iconSmall,
              color: focused ? AppColors.actionPrimary : AppColors.practiceTextSecondary,
            ),
            Expanded(
              child: TextField(
                key: const Key('library_search'),
                controller: _searchController,
                focusNode: _searchFocus,
                onChanged: widget.onQueryChange,
                // Nút Search trên bàn phím: Flutter tự đóng bàn phím khi bấm.
                textInputAction: TextInputAction.search,
                style: AppTypography.searchInput,
                cursorColor: AppColors.actionPrimary,
                decoration: const InputDecoration(
                  hintText: AppStrings.librarySearchHint,
                  hintStyle: AppTypography.wordFormHint,
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
                icon: const Icon(
                  Icons.close_rounded,
                  size: AppDimensions.iconSmall,
                  color: AppColors.practiceTextSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 4. Hàng chip lọc: "Tất cả" + các nhóm trong categories.
  Widget _buildCategoryChips(double side) {
    final categories = widget.state.categories;
    return Padding(
      // Chip cao 36dp nhưng vùng chạm 48dp → trừ phần đệm để khoảng cách nhìn thấy đúng 12dp.
      padding: const EdgeInsets.only(top: AppDimensions.space12 - AppDimensions.filterChipTouchInset),
      child: SizedBox(
        height: AppDimensions.minTouchTarget,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: side),
          itemCount: categories.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: AppDimensions.space8),
          itemBuilder: (context, index) {
            final category = index == 0 ? null : categories[index - 1];
            return _FilterChip(
              label: category?.name ?? AppStrings.libraryAllCategories,
              icon: category == null ? null : CategoryStyle.of(category.id).icon,
              selected: widget.state.selectedCategoryId == category?.id,
              onTap: () => widget.onCategorySelect(category?.id),
            );
          },
        ),
      ),
    );
  }

  // 5. Danh sách học phần / trạng thái tải, lỗi, trống.
  List<Widget> _buildContent(double side, int columns) {
    final listPadding = EdgeInsets.fromLTRB(
      side,
      AppDimensions.space16 - AppDimensions.filterChipTouchInset,
      side,
      AppDimensions.space24,
    );
    final state = widget.state;

    switch (state.status) {
      case LibraryLoadStatus.loading:
        return [
          SliverPadding(
            padding: listPadding,
            sliver: _cards(columns, AppDimensions.skeletonCardCount, (_) => const SkeletonCard()),
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
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: state.isFiltering
              ? _EmptyState(
                  key: const Key('library_no_results'),
                  icon: Icons.search_off_rounded,
                  title: AppStrings.libraryNoResults,
                  actionText: AppStrings.libraryClearFilters,
                  onAction: _clearFilters,
                )
              : _EmptyState(
                  key: const Key('library_empty'),
                  title: AppStrings.libraryEmpty,
                  message: AppStrings.libraryEmptyMessage,
                  actionText: AppStrings.libraryCreateCourse,
                  onAction: widget.onCreateCourseClick,
                ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: listPadding,
        sliver: _cards(columns, state.courses.length, (index) {
          final course = state.courses[index];
          final onMenu = widget.onCourseMenuClick;
          return CourseCard(
            course: course,
            onTap: () => widget.onCourseClick(course.id),
            onMenu: onMenu == null ? null : () => onMenu(course.id),
          );
        }),
      ),
    ];
  }

  /// 1 cột: danh sách cao theo nội dung; nhiều cột: lưới thẻ cao bằng nhau.
  Widget _cards(int columns, int count, Widget Function(int index) builder) {
    if (columns == 1) {
      return SliverList.separated(
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.space12),
        itemBuilder: (_, index) => builder(index),
      );
    }
    return SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: AppDimensions.space12,
        crossAxisSpacing: AppDimensions.space12,
        mainAxisExtent: AppDimensions.courseCardGridHeight,
      ),
      itemCount: count,
      itemBuilder: (_, index) => builder(index),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.white : AppColors.practiceTextPrimary;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      side: selected
          ? BorderSide.none
          : const BorderSide(color: AppColors.practiceCardBorder, width: AppDimensions.borderThin),
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
            color: selected ? AppColors.actionPrimary : AppColors.white,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Container(
                height: AppDimensions.filterChipHeight,
                padding: EdgeInsets.only(
                  left: icon == null ? AppDimensions.space16 : AppDimensions.space12,
                  right: AppDimensions.space16,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: AppDimensions.iconSmall, color: foreground),
                      const SizedBox(width: AppDimensions.space6),
                    ],
                    Text(label, style: AppTypography.filterChip.copyWith(color: foreground)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Thẻ học phần: icon theo chủ đề · tên (tối đa 2 dòng) + số từ · nút ⋮ (Sửa / Xoá).
class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;

  /// Nút ⋮; `null` = ẩn.
  final VoidCallback? onMenu;

  const CourseCard({super.key, required this.course, required this.onTap, this.onMenu});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.courseCardRadius),
        side: const BorderSide(color: AppColors.practiceCardBorder, width: AppDimensions.borderThin),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.only(
            left: AppDimensions.space16,
            top: AppDimensions.space16,
            bottom: AppDimensions.space16,
            right: onMenu == null ? AppDimensions.space16 : AppDimensions.space4,
          ),
          child: Row(
            children: [
              CourseIcon(categoryId: course.categoryId),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(course.name, style: AppTypography.courseTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: AppDimensions.space4),
                    Text(AppStrings.libraryWordCount(course.wordCount), style: AppTypography.courseMeta),
                  ],
                ),
              ),
              if (onMenu != null)
                IconButton(
                  key: Key('course_menu_${course.id}'),
                  onPressed: onMenu,
                  tooltip: AppStrings.collectionMenu,
                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.practiceTextSecondary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thanh tiến độ trắng trên nền xanh của thẻ tổng quan.
class _ProgressBar extends StatelessWidget {
  /// 0 … 1.
  final double value;

  const _ProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      child: SizedBox(
        height: AppDimensions.libraryOverviewBarHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: AppColors.onPrimaryTrack),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0.0, 1.0),
              child: const ColoredBox(color: AppColors.white),
            ),
          ],
        ),
      ),
    );
  }
}

/// Trạng thái trống: linh vật Axolotl (hoặc icon khi không tìm thấy) + nút hành động.
class _EmptyState extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? message;
  final String actionText;
  final VoidCallback onAction;

  const _EmptyState({
    super.key,
    required this.title,
    required this.actionText,
    required this.onAction,
    this.icon,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.libraryHorizontalPadding),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon == null)
              Image.asset(
                AppAssets.logo,
                width: AppDimensions.libraryEmptyLogoSize,
                height: AppDimensions.libraryEmptyLogoSize,
                excludeFromSemantics: true,
              )
            else
              Icon(icon, size: AppDimensions.libraryEmptyIconSize, color: AppColors.practiceTextSecondary),
            const SizedBox(height: AppDimensions.space16),
            Text(title, style: AppTypography.headingMedium, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: AppDimensions.space8),
              Text(message!, style: AppTypography.bodyMedium, textAlign: TextAlign.center),
            ],
            const SizedBox(height: AppDimensions.space20),
            // Rộng tối thiểu 220dp, chữ dài thì nút giãn theo (không tràn).
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: AppDimensions.emptyActionWidth),
              child: IntrinsicWidth(
                child: AppButton(text: actionText, onPressed: onAction),
              ),
            ),
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
  late final AnimationController _controller = AnimationController(vsync: this, duration: AppDurations.pulse)
    ..repeat(reverse: true);

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
            border: Border.all(color: AppColors.practiceCardBorder, width: AppDimensions.borderThin),
          ),
          child: Row(
            children: [
              _block(
                AppDimensions.libraryCourseIconBoxSize,
                AppDimensions.libraryCourseIconBoxSize,
                AppDimensions.courseCardIconRadius,
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
      decoration: BoxDecoration(color: AppColors.practiceSelectedFill, borderRadius: BorderRadius.circular(radius)),
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
