import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Hangul font bundled with the app (Noto Sans KR, cut to the 2,350 common
/// syllables + jamo, OFL licence in assets/fonts).
///
/// Nunito and DM Sans have no Korean letters. Without a bundled font, Flutter
/// web downloads a fallback font the first time it meets Hangul and draws
/// boxes until it arrives (HRHTA-112).
const koreanFontFamily = 'NotoSansKR';

const koreanFontFiles = [
  'assets/fonts/NotoSansKR-Regular.ttf',
  'assets/fonts/NotoSansKR-Bold.ttf',
];

Future<void>? _loading;

@visibleForTesting
void resetKoreanFontForTest() => _loading = null;

/// Registers the Korean font. Safe to call more than once.
///
/// web/index.html starts downloading the files while the app code is still
/// loading, so this is usually instant. It never throws and never waits
/// longer than [timeout]: on a very slow network the app starts anyway and
/// the font is used as soon as it arrives.
Future<void> loadKoreanFont({
  Duration timeout = const Duration(seconds: 4),
  AssetBundle? bundle,
}) {
  _loading ??= () async {
    // Fetch both files together first, so a failed one is always handled.
    final files = await Future.wait(
        [for (final f in koreanFontFiles) (bundle ?? rootBundle).load(f)]);
    final loader = FontLoader(koreanFontFamily);
    for (final data in files) {
      loader.addFont(Future.value(data));
    }
    await loader.load();
  }()
      .catchError((Object _) {});
  return _loading!.timeout(timeout, onTimeout: () {});
}
