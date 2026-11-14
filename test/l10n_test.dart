import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karo_strength_training/l10n/app_strings.dart';

void main() {
  test('Norwegian is chosen for nb, nn and no', () {
    for (final code in ['nb', 'nn', 'no']) {
      expect(AppStrings.isNorwegian(Locale(code)), isTrue);
    }
    expect(AppStrings.isNorwegian(const Locale('en')), isFalse);
    expect(AppStrings.isNorwegian(const Locale('sv')), isFalse);
  });

  test('Texts differ by language', () {
    expect(AppStrings.english.newExercise, 'New exercise');
    expect(AppStrings.norwegian.newExercise, 'Ny øvelse');
    expect(AppStrings.norwegian.lastLine('2026-11-14', 1),
        'Sist: 2026-11-14 (i går)');
  });
}
