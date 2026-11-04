import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppyong/theme/app_theme.dart';
import 'package:ppyong/theme/korean_font.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every theme text style falls back to the bundled Korean font', () {
    // google_fonts tries to download Nunito/DM Sans here; tests have no
    // network, and that's not what this test is about.
    late TextTheme theme;
    runZonedGuarded(() => theme = AppTheme.light.textTheme, (e, _) {
      if (!'$e'.contains('google_fonts') && !'$e'.contains('Failed to load font')) throw e;
    });
    final styles = {
      'displayLarge': theme.displayLarge,
      'displayMedium': theme.displayMedium,
      'headlineMedium': theme.headlineMedium,
      'titleMedium': theme.titleMedium,
      'titleLarge': theme.titleLarge,
      'bodyLarge': theme.bodyLarge,
      'bodyMedium': theme.bodyMedium,
      'bodySmall': theme.bodySmall,
      'labelLarge': theme.labelLarge,
      'labelSmall': theme.labelSmall,
    };
    for (final e in styles.entries) {
      expect(e.value?.fontFamilyFallback, contains(koreanFontFamily), reason: e.key);
    }
  });

  test('withKorean keeps the style\'s own fallback first and adds Korean once', () {
    const base = TextStyle(fontFamily: 'Nunito_700', fontFamilyFallback: ['Nunito']);
    final once = AppTheme.withKorean(base);
    expect(once.fontFamilyFallback, ['Nunito', koreanFontFamily]);
    expect(AppTheme.withKorean(once).fontFamilyFallback, ['Nunito', koreanFontFamily]);
  });

  test('the font files are bundled, stay a small subset and register', () async {
    for (final file in koreanFontFiles) {
      final data = await rootBundle.load(file);
      expect(data.lengthInBytes, greaterThan(500000), reason: file);
      expect(data.lengthInBytes, lessThan(1200000), reason: '$file stays a subset');
    }
    resetKoreanFontForTest();
    await loadKoreanFont(); // registers without throwing
  });

  test('a font that never arrives does not hold up the app start', () async {
    resetKoreanFontForTest();
    addTearDown(resetKoreanFontForTest);
    final sw = Stopwatch()..start();
    await loadKoreanFont(
        bundle: _NeverBundle(), timeout: const Duration(milliseconds: 50));
    expect(sw.elapsedMilliseconds, lessThan(1000));
  });

  test('a missing font file does not crash the app start', () async {
    resetKoreanFontForTest();
    addTearDown(resetKoreanFontForTest);
    await expectLater(loadKoreanFont(bundle: _BrokenBundle()), completes);
  });
}

class _NeverBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) => Completer<ByteData>().future;
}

class _BrokenBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) => Future.error(FlutterError('no $key'));
}
