import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karvocab_flutter/data/services/feedback_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Âm thanh đúng / sai / tích tắc được đóng gói trong assets và là file WAV', () async {
    for (final asset in [FeedbackService.correctSound, FeedbackService.incorrectSound, FeedbackService.tickSound]) {
      final data = await rootBundle.load('assets/$asset');
      final header = ascii.decode(data.buffer.asUint8List(0, 4));
      expect(header, 'RIFF', reason: asset);
      expect(data.lengthInBytes, greaterThan(1000), reason: asset);
    }
  });
}
