import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';

/// Hộp chọn ngày sinh (không cho chọn ngày trong tương lai).
Future<DateTime?> pickBirthDate(BuildContext context, {DateTime? initial}) {
  final today = DateTime.now();
  return showDatePicker(
    context: context,
    initialDate: initial ?? DateTime(today.year - 18, today.month, today.day),
    firstDate: DateTime(1900),
    lastDate: today,
    helpText: AppStrings.profileBirthDateHelp,
    initialEntryMode: DatePickerEntryMode.calendarOnly,
  );
}
