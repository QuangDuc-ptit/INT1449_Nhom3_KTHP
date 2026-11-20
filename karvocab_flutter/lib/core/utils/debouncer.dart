import 'dart:async';
import 'dart:ui' show VoidCallback;

/// Trì hoãn hành động cho tới khi người dùng ngừng gõ một khoảng [delay].
/// Dùng cho thanh tìm kiếm Thư viện (đặc tả Màn 05: debounce 300ms).
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 300)});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() => _timer?.cancel();

  void dispose() => cancel();
}
