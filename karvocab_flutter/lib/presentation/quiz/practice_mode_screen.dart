import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/collection_model.dart';
import '../../data/models/quiz_models.dart';
import '../../data/models/vocabulary_model.dart';
import '../../data/repositories/collection_store.dart';
import '../../data/repositories/quiz_question_factory.dart';
import 'quiz_session_screen.dart';
import 'widgets/practice_widgets.dart';
import '../widgets/tab_header.dart';

/// Trạng thái từ dùng để lọc nguồn luyện tập.
enum PracticeWordStatus { unmastered, mastered, all }

/// Thứ tự hiển thị câu hỏi.
enum PracticeOrder { alphabet, random }

/// Màn 10 — Luyện tập (tab "Luyện tập"): thiết lập nguồn từ + danh sách trò chơi.
///
/// Đọc từ vựng qua [CollectionStore] (truyền [store] khi kiểm thử), nên từ vừa
/// lưu từ AI hay thêm thủ công đều luyện được ngay.
class PracticeModeScreen extends StatefulWidget {
  final CollectionStore? store;

  const PracticeModeScreen({super.key, this.store});

  /// Các lựa chọn "Số lượng từ".
  static const List<int> countOptions = [10, 20, 30, 50];

  @override
  State<PracticeModeScreen> createState() => _PracticeModeScreenState();
}

class _PracticeModeScreenState extends State<PracticeModeScreen> {
  CollectionStore get _store => widget.store ?? CollectionStore.instance;

  List<String>? _selectedIds; // null = chưa khởi tạo, lấy mặc định từ store
  PracticeWordStatus _status = PracticeWordStatus.unmastered;
  int _count = 20;
  PracticeOrder _order = PracticeOrder.alphabet;

  static const List<_Game> _games = [
    _Game(AppStrings.gamePronunciation, Icons.mic_rounded, QuizMode.pronunciation, filledIcon: true),
    _Game(AppStrings.gameListenType, Icons.headphones_rounded, QuizMode.listenType),
    _Game(AppStrings.gameListenChoose, Icons.headphones_rounded, QuizMode.listenChoose),
    _Game(AppStrings.gameChooseMeaning, Icons.menu_book_rounded, QuizMode.meaningChoose),
    _Game(AppStrings.gameSynonymAntonym, Icons.compare_arrows_rounded, QuizMode.synonymAntonym),
    _Game(AppStrings.gameRecallType, Icons.edit_note_rounded, QuizMode.recallType),
  ];

  // ---------------------------------------------------------------------------
  // Dữ liệu
  // ---------------------------------------------------------------------------

  /// Mặc định chọn bộ "hằng ngày" như ảnh thiết kế, không có thì lấy bộ đầu tiên.
  List<String> _defaultSelection(List<CollectionModel> collections) {
    if (collections.isEmpty) return [];
    final daily = collections.where((c) => c.title.toLowerCase().contains('hằng ngày'));
    return [(daily.isNotEmpty ? daily.first : collections.first).id];
  }

  /// Bỏ các học phần đã bị xoá khỏi lựa chọn.
  List<String> _validSelection(List<CollectionModel> collections) {
    final ids = collections.map((c) => c.id).toSet();
    _selectedIds ??= _defaultSelection(collections);
    return _selectedIds!.where(ids.contains).toList();
  }

  List<VocabularyModel> _pool(List<String> selected) {
    final words = [for (final id in selected) ..._store.wordsOf(id)].where((w) {
      switch (_status) {
        case PracticeWordStatus.unmastered:
          return !w.isMastered;
        case PracticeWordStatus.mastered:
          return w.isMastered;
        case PracticeWordStatus.all:
          return true;
      }
    }).toList();
    if (_order == PracticeOrder.alphabet) {
      words.sort((a, b) => a.term.toLowerCase().compareTo(b.term.toLowerCase()));
    }
    return words;
  }

  String _statusLabel(PracticeWordStatus s) {
    switch (s) {
      case PracticeWordStatus.unmastered:
        return AppStrings.practiceStatusUnmastered;
      case PracticeWordStatus.mastered:
        return AppStrings.practiceStatusMastered;
      case PracticeWordStatus.all:
        return AppStrings.practiceStatusAll;
    }
  }

  String _sourceLabel(List<CollectionModel> collections, List<String> selected) {
    if (selected.isEmpty) return AppStrings.practiceSourceEmpty;
    final titles = {for (final c in collections) c.id: c.title};
    return selected.map((id) => titles[id] ?? '').join(', ');
  }

  // ---------------------------------------------------------------------------
  // Hành động
  // ---------------------------------------------------------------------------

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _openGame(_Game game, List<String> selected) {
    final mode = game.mode;
    final pool = _pool(selected);
    if (pool.isEmpty) {
      _showMessage(AppStrings.practiceNoWords);
      return;
    }
    final questions = QuizQuestionFactory.build(
      mode: mode,
      pool: pool,
      count: _count,
      shuffle: _order == PracticeOrder.random,
    );
    // Game đồng nghĩa / trái nghĩa chỉ dùng được các từ đã có dữ liệu quan hệ.
    if (questions.isEmpty) {
      _showMessage(AppStrings.practiceNoRelations);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => QuizSessionScreen(questions: questions)));
  }

  Future<void> _pickSources(List<CollectionModel> collections, List<String> selected) async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.practicePanelRadius)),
      ),
      builder: (sheetContext) {
        final picked = List<String>.from(selected);
        return StatefulBuilder(
          builder: (context, setSheetState) => _PracticeSheet(
            title: AppStrings.practiceSourceLabel,
            subtitle: AppStrings.practiceSourceHint,
            onDone: () => Navigator.of(sheetContext).pop(picked),
            children: [
              for (final c in collections)
                PracticeSheetOption(
                  label: c.title,
                  multiSelect: true,
                  selected: picked.contains(c.id),
                  // Đủ 3 bộ thì các bộ chưa chọn bị làm mờ, bỏ bớt mới chọn được bộ khác.
                  enabled: picked.contains(c.id) || picked.length < AppDimensions.practiceMaxCollections,
                  onTap: () => setSheetState(() {
                    if (!picked.remove(c.id)) picked.add(c.id);
                  }),
                ),
            ],
          ),
        );
      },
    );
    if (result != null && mounted) setState(() => _selectedIds = result);
  }

  Future<T?> _pickOne<T>({
    required String title,
    required List<T> options,
    required T current,
    required String Function(T) labelOf,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.practicePanelRadius)),
      ),
      builder: (sheetContext) => _PracticeSheet(
        title: title,
        children: [
          for (final o in options)
            PracticeSheetOption(
              label: labelOf(o),
              selected: o == current,
              onTap: () => Navigator.of(sheetContext).pop(o),
            ),
        ],
      ),
    );
  }

  Future<void> _pickStatus() async {
    final result = await _pickOne<PracticeWordStatus>(
      title: AppStrings.practiceStatusLabel,
      options: PracticeWordStatus.values,
      current: _status,
      labelOf: _statusLabel,
    );
    if (result != null && mounted) setState(() => _status = result);
  }

  Future<void> _pickCount() async {
    final result = await _pickOne<int>(
      title: AppStrings.practiceCountLabel,
      options: PracticeModeScreen.countOptions,
      current: _count,
      labelOf: (n) => '$n',
    );
    if (result != null && mounted) setState(() => _count = result);
  }

  // ---------------------------------------------------------------------------
  // Giao diện
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.practiceBackground,
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: _store,
          builder: (context, _) {
            final collections = _store.collections;
            final selected = _validSelection(collections);
            return LayoutBuilder(
              builder: (context, constraints) => _buildResponsive(constraints.maxWidth, collections, selected),
            );
          },
        ),
      ),
    );
  }

  /// Chọn bố cục theo bề rộng màn hình (xem các mốc trong [AppDimensions]).
  Widget _buildResponsive(double width, List<CollectionModel> collections, List<String> selected) {
    final isTablet = width >= AppDimensions.practiceTabletBreakpoint;
    final isDesktop = width >= AppDimensions.practiceDesktopBreakpoint;
    final maxWidth = isDesktop
        ? AppDimensions.practiceMaxWidthDesktop
        : (isTablet ? AppDimensions.practiceMaxWidthTablet : double.infinity);
    final horizontal = isTablet ? AppDimensions.practiceHorizontalPaddingWide : AppDimensions.practiceHorizontalPadding;

    final settings = _buildSettingsPanel(collections, selected);
    final games = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(AppStrings.practiceGamesTitle, style: AppTypography.practiceSectionTitle),
        const SizedBox(height: AppDimensions.space12),
        // Tablet: 3 thẻ một hàng (6 trò = 2 hàng đều); điện thoại và cột phải máy tính: 2.
        _buildGameGrid(selected, columns: isTablet && !isDesktop ? 3 : 2),
      ],
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(horizontal, AppDimensions.space16, horizontal, AppDimensions.space24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TabHeader(title: AppStrings.practiceTitle),
                const SizedBox(height: AppDimensions.space16),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: AppDimensions.practiceSettingsPanelWidth, child: settings),
                      const SizedBox(width: AppDimensions.practiceColumnGap),
                      Expanded(child: games),
                    ],
                  )
                else ...[
                  settings,
                  const SizedBox(height: AppDimensions.space24),
                  games,
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsPanel(List<CollectionModel> collections, List<String> selected) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.practicePanelPadding),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.practicePanelRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(AppStrings.practiceSourceLabel, style: AppTypography.practiceLabel),
          const SizedBox(height: AppDimensions.space8),
          PracticeSelectField(
            key: const Key('practice_source'),
            value: _sourceLabel(collections, selected),
            onTap: () => _pickSources(collections, selected),
          ),
          const SizedBox(height: AppDimensions.space6),
          const Text(AppStrings.practiceSourceHint, style: AppTypography.practiceHint),
          const SizedBox(height: AppDimensions.space16),
          const Divider(
            height: AppDimensions.borderThin,
            thickness: AppDimensions.borderThin,
            color: AppColors.practiceCardBorder,
          ),
          const SizedBox(height: AppDimensions.space16),
          const Text(AppStrings.practiceStatusLabel, style: AppTypography.practiceLabel),
          const SizedBox(height: AppDimensions.space8),
          PracticeSelectField(key: const Key('practice_status'), value: _statusLabel(_status), onTap: _pickStatus),
          const SizedBox(height: AppDimensions.space16),
          const Text(AppStrings.practiceCountLabel, style: AppTypography.practiceLabel),
          const SizedBox(height: AppDimensions.space8),
          PracticeSelectField(key: const Key('practice_count'), value: '$_count', onTap: _pickCount),
          const SizedBox(height: AppDimensions.space16),
          const Text(AppStrings.practiceOrderLabel, style: AppTypography.practiceLabel),
          const SizedBox(height: AppDimensions.space4),
          Row(
            children: [
              Expanded(
                flex: AppDimensions.practiceOrderPrimaryFlex,
                child: PracticeOrderButton(
                  label: AppStrings.practiceOrderAlphabet,
                  selected: _order == PracticeOrder.alphabet,
                  onTap: () => setState(() => _order = PracticeOrder.alphabet),
                ),
              ),
              const SizedBox(width: AppDimensions.space10),
              Expanded(
                flex: AppDimensions.practiceOrderSecondaryFlex,
                child: PracticeOrderButton(
                  label: AppStrings.practiceOrderRandom,
                  selected: _order == PracticeOrder.random,
                  onTap: () => setState(() => _order = PracticeOrder.random),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Lưới [columns] cột; mỗi hàng cao bằng thẻ cao nhất để các thẻ thẳng hàng.
  Widget _buildGameGrid(List<String> selected, {required int columns}) {
    final rows = <Widget>[];
    for (var i = 0; i < _games.length; i += columns) {
      if (i > 0) rows.add(const SizedBox(height: AppDimensions.practiceGridGap));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < columns; j++) ...[
                if (j > 0) const SizedBox(width: AppDimensions.practiceGridGap),
                Expanded(child: i + j < _games.length ? _buildGameCard(_games[i + j], selected) : const SizedBox()),
              ],
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildGameCard(_Game game, List<String> selected) {
    return PracticeGameCard(
      icon: game.icon,
      title: game.title,
      filledIcon: game.filledIcon,
      onTap: () => _openGame(game, selected),
    );
  }
}

class _Game {
  final String title;
  final IconData icon;
  final QuizMode mode;
  final bool filledIcon;

  const _Game(this.title, this.icon, this.mode, {this.filledIcon = false});
}

/// Khung bottom sheet chọn giá trị: thanh kéo, tiêu đề, danh sách lựa chọn, nút "Xong" (tuỳ chọn).
class _PracticeSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final VoidCallback? onDone;

  const _PracticeSheet({required this.title, required this.children, this.subtitle, this.onDone});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppDimensions.space8),
          Center(
            child: Container(
              width: AppDimensions.practiceSheetHandleWidth,
              height: AppDimensions.space4,
              decoration: BoxDecoration(
                color: AppColors.practiceBorder,
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.practiceHorizontalPadding,
              AppDimensions.space16,
              AppDimensions.space8,
              AppDimensions.space8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.practiceSectionTitle),
                      if (subtitle != null) Text(subtitle!, style: AppTypography.practiceHint),
                    ],
                  ),
                ),
                if (onDone != null)
                  TextButton(
                    onPressed: onDone,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(AppDimensions.minTouchTarget, AppDimensions.minTouchTarget),
                    ),
                    child: Text(
                      AppStrings.practiceSheetDone,
                      style: AppTypography.practiceOrderOption.copyWith(color: AppColors.practicePrimary),
                    ),
                  ),
              ],
            ),
          ),
          Flexible(child: ListView(shrinkWrap: true, children: children)),
          const SizedBox(height: AppDimensions.space8),
        ],
      ),
    );
  }
}
