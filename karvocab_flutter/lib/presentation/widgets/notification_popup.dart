import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_durations.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_typography.dart';
import '../notifications/notification_ui_state.dart';
import '../notifications/relative_time.dart';

/// Các thao tác của popup thông báo. Popup không tự xử lý dữ liệu —
/// bên giữ state (hiện là `MainShellScreen`) quyết định làm gì.
class NotificationPopupCallbacks {
  final ValueChanged<String>? onNotificationClick;
  final VoidCallback? onMarkAllRead;
  final VoidCallback? onRefresh;
  final VoidCallback? onLoadMore;

  /// Gọi mỗi khi popup đóng (bấm ra ngoài, bấm lại chuông, Back, bấm thông báo).
  final VoidCallback? onDismiss;

  const NotificationPopupCallbacks({
    this.onNotificationClick,
    this.onMarkAllRead,
    this.onRefresh,
    this.onLoadMore,
    this.onDismiss,
  });
}

/// Mở popup thông báo ngay dưới [anchor] (vị trí nút chuông trên màn hình).
///
/// Popup theo dõi [state] nên tự cập nhật khi dữ liệu đổi (đang làm mới,
/// đã đọc, tải thêm...). Đóng khi bấm ra ngoài — kể cả bấm lại chuông, vì
/// vùng bấm-ra-ngoài phủ cả chuông — hoặc bấm Back.
Future<void> showNotificationPopup({
  required BuildContext context,
  required Rect anchor,
  required ValueListenable<NotificationUiState> state,
  NotificationPopupCallbacks callbacks = const NotificationPopupCallbacks(),
}) async {
  await Navigator.of(context).push(_NotificationPopupRoute(
    anchor: anchor,
    state: state,
    callbacks: callbacks,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  ));
  callbacks.onDismiss?.call();
}

class _NotificationPopupRoute extends PopupRoute<void> {
  final Rect anchor;
  final ValueListenable<NotificationUiState> state;
  final NotificationPopupCallbacks callbacks;

  _NotificationPopupRoute({
    required this.anchor,
    required this.state,
    required this.callbacks,
    required this.barrierLabel,
  });

  static const Duration _animationDuration = AppDurations.fast;

  @override
  final String barrierLabel;

  @override
  Color? get barrierColor => null; // Không làm tối phần còn lại của màn hình

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration => _animationDuration;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    final screen = MediaQuery.sizeOf(context);
    final top = anchor.bottom + AppDimensions.notificationPopupGap;
    final maxHeight = screen.height * AppDimensions.notificationPopupMaxHeightFactor;
    return Stack(
      children: [
        Positioned(
          top: top,
          left: AppDimensions.notificationPopupMargin,
          right: AppDimensions.notificationPopupMargin,
          child: ConstrainedBox(
            // Không vượt quá 70% màn hình và không tràn khỏi đáy màn hình
            constraints: BoxConstraints(
              maxHeight: (screen.height - top - AppDimensions.notificationPopupMargin).clamp(0, maxHeight),
            ),
            child: ValueListenableBuilder<NotificationUiState>(
              valueListenable: state,
              builder: (context, value, _) => NotificationPopup(
                state: value,
                callbacks: callbacks,
                // Bấm thông báo → báo ra ngoài rồi đóng popup
                onItemSelected: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut, reverseCurve: Curves.easeIn);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -AppDimensions.notificationPopupSlideFactor),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

/// Nội dung popup thông báo: header cố định, danh sách cuộn, footer "Tải thêm".
class NotificationPopup extends StatefulWidget {
  final NotificationUiState state;
  final NotificationPopupCallbacks callbacks;

  /// Gọi sau `onNotificationClick` — route dùng để đóng popup.
  final VoidCallback? onItemSelected;

  /// Mốc tính thời gian tương đối; mặc định là thời điểm hiện tại.
  final DateTime? now;

  const NotificationPopup({
    super.key,
    required this.state,
    this.callbacks = const NotificationPopupCallbacks(),
    this.onItemSelected,
    this.now,
  });

  @override
  State<NotificationPopup> createState() => _NotificationPopupState();
}

class _NotificationPopupState extends State<NotificationPopup> with SingleTickerProviderStateMixin {
  static const Duration _spinDuration = Duration(seconds: 1);

  final ScrollController _scrollController = ScrollController();
  late final AnimationController _spin = AnimationController(vsync: this, duration: _spinDuration);

  @override
  void initState() {
    super.initState();
    _syncSpin();
  }

  @override
  void didUpdateWidget(covariant NotificationPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSpin();
  }

  /// Icon làm mới xoay liên tục khi đang làm mới.
  void _syncSpin() {
    if (widget.state.isRefreshing) {
      if (!_spin.isAnimating) _spin.repeat();
    } else {
      _spin.reset();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isEmpty = state.items.isEmpty;
    return Material(
      color: AppColors.white,
      elevation: AppDimensions.notificationPopupElevation,
      borderRadius: BorderRadius.circular(AppDimensions.notificationPopupRadius),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(state),
          const _ThinDivider(),
          Flexible(child: isEmpty ? const _EmptyState() : _buildList(state)),
          if (!isEmpty && state.canLoadMore) ...[
            const _ThinDivider(),
            _LoadMoreFooter(isLoading: state.isLoadingMore, onPressed: widget.callbacks.onLoadMore),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(NotificationUiState state) {
    final canMarkAll = state.unreadCount > 0;
    return Padding(
      padding: const EdgeInsets.only(left: AppDimensions.notificationRowPadding),
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppStrings.notificationTitle(state.totalCount),
              style: AppTypography.homeSectionTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            key: const Key('notification_refresh'),
            tooltip: AppStrings.notificationRefresh,
            onPressed: state.isRefreshing ? null : widget.callbacks.onRefresh,
            iconSize: AppDimensions.iconMedium,
            color: AppColors.navyBlue,
            // Khi đang làm mới vẫn giữ màu đậm (chỉ xoay, không làm mờ)
            disabledColor: AppColors.navyBlue,
            icon: RotationTransition(turns: _spin, child: const Icon(Icons.refresh_rounded)),
          ),
          IconButton(
            key: const Key('notification_mark_all_read'),
            tooltip: AppStrings.notificationMarkAllRead,
            onPressed: canMarkAll ? widget.callbacks.onMarkAllRead : null,
            iconSize: AppDimensions.iconMedium,
            color: AppColors.navyBlue,
            disabledColor: AppColors.navyBlue.withValues(alpha: AppDimensions.disabledOpacity),
            icon: const Icon(Icons.done_all_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildList(NotificationUiState state) {
    final now = widget.now ?? DateTime.now();
    return Scrollbar(
      controller: _scrollController,
      thickness: AppDimensions.scrollbarThickness,
      child: ListView.separated(
        controller: _scrollController,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: state.items.length,
        separatorBuilder: (_, _) => const _ThinDivider(),
        itemBuilder: (context, index) {
          final item = state.items[index];
          return _NotificationRow(
            item: item,
            timeText: formatRelativeTime(item.createdAt, now),
            onTap: () {
              widget.callbacks.onNotificationClick?.call(item.id);
              widget.onItemSelected?.call();
            },
          );
        },
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final NotificationItem item;
  final String timeText;
  final VoidCallback onTap;

  const _NotificationRow({required this.item, required this.timeText, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unread = !item.isRead;
    return Material(
      color: unread ? AppColors.homeSurfaceTint : AppColors.white,
      child: InkWell(
        key: Key('notification_${item.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.notificationRowPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (unread) ...[
                    // Căn chấm theo giữa dòng đầu của tiêu đề
                    Padding(
                      padding: const EdgeInsets.only(top: AppDimensions.space8),
                      child: Container(
                        key: Key('notification_unread_dot_${item.id}'),
                        width: AppDimensions.notificationUnreadDotSize,
                        height: AppDimensions.notificationUnreadDotSize,
                        decoration: const BoxDecoration(color: AppColors.primaryBlue, shape: BoxShape.circle),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space8),
                  ],
                  Expanded(
                    child: Text(
                      item.title,
                      style: unread ? AppTypography.notificationTitleUnread : AppTypography.notificationTitleRead,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space4),
              Text(
                item.preview,
                style: AppTypography.notificationPreview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppDimensions.space4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(timeText, style: AppTypography.notificationTime),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadMoreFooter extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _LoadMoreFooter({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.minTouchTarget,
      child: Center(
        child: isLoading
            ? const SizedBox(
                key: Key('notification_loading_more'),
                width: AppDimensions.notificationLoaderSize,
                height: AppDimensions.notificationLoaderSize,
                child: CircularProgressIndicator(
                  strokeWidth: AppDimensions.notificationLoaderStroke,
                  color: AppColors.primaryBlue,
                ),
              )
            : TextButton.icon(
                key: const Key('notification_load_more'),
                onPressed: onPressed,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  minimumSize: const Size(AppDimensions.minTouchTarget, AppDimensions.minTouchTarget),
                ),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: AppDimensions.iconSmall),
                label: const Text(AppStrings.notificationLoadMore, style: AppTypography.homeLink),
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.notificationRowPadding,
        vertical: AppDimensions.space32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: AppDimensions.notificationEmptyIconSize,
            color: AppColors.homeTextSecondary,
          ),
          SizedBox(height: AppDimensions.space12),
          Text(AppStrings.notificationEmpty, style: AppTypography.homeBody, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ThinDivider extends StatelessWidget {
  const _ThinDivider();

  @override
  Widget build(BuildContext context) => const Divider(
        height: AppDimensions.dividerThickness,
        thickness: AppDimensions.dividerThickness,
        color: AppColors.homeDivider,
      );
}
