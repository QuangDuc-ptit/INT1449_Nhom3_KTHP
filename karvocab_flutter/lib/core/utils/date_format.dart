/// Định dạng ngày `DD/MM/YYYY` (vd ngày sinh 20/09/2005).
String formatDmy(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year}';
}
