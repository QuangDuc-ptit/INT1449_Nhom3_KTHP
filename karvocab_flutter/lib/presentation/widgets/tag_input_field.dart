import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_typography.dart';

/// Ô nhập nhiều từ dạng thẻ (Màn 09 / 24: từ đồng nghĩa, trái nghĩa).
///
/// Gõ một từ rồi nhấn dấu cách, dấu phẩy hoặc Enter thì từ đó thành một thẻ
/// có nút × để xoá. Dán "logical, consistent" cũng tách thành 2 thẻ.
/// Ô trống mà nhấn Backspace (bàn phím rời) thì xoá thẻ cuối.
/// Từ trùng (không phân biệt hoa thường) bị bỏ qua.
class TagInputField extends StatefulWidget {
  final List<String> values;
  final ValueChanged<List<String>> onChanged;

  /// Chữ còn đang gõ dở; màn cha gọi [commitPending] khi bấm Lưu để không mất chữ.
  final TextEditingController controller;
  final String hint;

  /// true: thẻ nền xanh (đồng nghĩa); false: thẻ nền trắng, chữ xám (trái nghĩa).
  final bool highlighted;
  final int maxTags;

  const TagInputField({
    super.key,
    required this.values,
    required this.onChanged,
    required this.controller,
    required this.hint,
    this.highlighted = true,
    this.maxTags = maxTagCount,
  });

  static const int maxTagCount = 10;
  static const int maxTagLength = 40;
  static final RegExp _separator = RegExp(r'[\s,]+');

  /// Gộp [raw] (có thể chứa nhiều từ cách nhau bởi dấu cách / dấu phẩy) vào [values].
  static List<String> merge(List<String> values, String raw, {int maxTags = maxTagCount}) {
    final result = List<String>.of(values);
    for (final part in raw.split(_separator)) {
      final word = part.trim();
      if (word.isEmpty || result.length >= maxTags) continue;
      final clipped = word.length > maxTagLength ? word.substring(0, maxTagLength) : word;
      if (result.any((w) => w.toLowerCase() == clipped.toLowerCase())) continue;
      result.add(clipped);
    }
    return result;
  }

  /// Đưa chữ còn trong ô vào danh sách (dùng khi bấm Lưu).
  static List<String> commitPending(List<String> values, TextEditingController controller) {
    final merged = merge(values, controller.text);
    controller.clear();
    return merged;
  }

  @override
  State<TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends State<TagInputField> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _handleChanged(String text) {
    // Chỉ tách khi đã có dấu phân cách; phần sau dấu cuối cùng là chữ đang gõ dở.
    final cut = text.lastIndexOf(TagInputField._separator);
    if (cut < 0) return;
    final complete = text.substring(0, cut + 1);
    final rest = text.substring(cut + 1);
    final merged = TagInputField.merge(widget.values, complete, maxTags: widget.maxTags);
    widget.controller.value = TextEditingValue(
      text: rest,
      selection: TextSelection.collapsed(offset: rest.length),
    );
    if (merged.length != widget.values.length) widget.onChanged(merged);
  }

  void _commit() {
    final merged = TagInputField.merge(widget.values, widget.controller.text, maxTags: widget.maxTags);
    widget.controller.clear();
    if (merged.length != widget.values.length) widget.onChanged(merged);
    _focus.requestFocus();
  }

  void _remove(String word) {
    widget.onChanged([...widget.values]..remove(word));
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        widget.controller.text.isEmpty &&
        widget.values.isNotEmpty) {
      _remove(widget.values.last);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    final full = widget.values.length >= widget.maxTags;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _focus.requestFocus,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        constraints: const BoxConstraints(minHeight: AppDimensions.wordFormFieldHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space10,
          vertical: AppDimensions.space8,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.wordFormFieldRadius),
          border: Border.all(
            color: focused ? AppColors.practicePrimary : AppColors.practiceCardBorder,
            width: focused ? AppDimensions.borderMedium : AppDimensions.borderThin,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: AppDimensions.space6,
            runSpacing: AppDimensions.space6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final word in widget.values)
                _Tag(word: word, highlighted: widget.highlighted, onRemove: () => _remove(word)),
              if (!full)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: AppDimensions.tagInputMinWidth,
                    maxWidth: constraints.maxWidth,
                  ),
                  child: IntrinsicWidth(
                    child: Focus(
                      onKeyEvent: _handleKey,
                      child: TextField(
                        controller: widget.controller,
                        focusNode: _focus,
                        style: AppTypography.wordFormInput,
                        cursorColor: AppColors.practicePrimary,
                        textInputAction: TextInputAction.next,
                        onChanged: _handleChanged,
                        onSubmitted: (_) => _commit(),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.space4,
                            vertical: AppDimensions.space8,
                          ),
                          hintText: widget.values.isEmpty ? widget.hint : null,
                          hintStyle: AppTypography.wordFormHint,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Một thẻ từ có nút × để xoá.
class _Tag extends StatelessWidget {
  final String word;
  final bool highlighted;
  final VoidCallback onRemove;

  const _Tag({required this.word, required this.highlighted, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final color = highlighted ? AppColors.practicePrimary : AppColors.practiceTextSecondary;
    return Container(
      height: AppDimensions.tagHeight,
      padding: const EdgeInsets.only(left: AppDimensions.space10),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.practiceSelectedFill : AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.wordDetailChipRadius),
        border: Border.all(color: highlighted ? AppColors.practiceSelectedFill : AppColors.practiceCardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              word,
              style: AppTypography.wordDetailChip.copyWith(color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Semantics(
            button: true,
            label: AppStrings.tagRemove(word),
            child: InkResponse(
              onTap: onRemove,
              radius: AppDimensions.tagHeight / 2,
              child: SizedBox(
                width: AppDimensions.tagHeight,
                height: AppDimensions.tagHeight,
                child: Icon(Icons.close_rounded, size: AppDimensions.tagCloseIcon, color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
