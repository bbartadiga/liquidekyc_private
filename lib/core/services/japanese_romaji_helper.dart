import 'package:jp_transliterate/jp_transliterate.dart';
import 'package:kana_kit/kana_kit.dart';
import 'app_logger.dart';

/// Japanese → Romaji (latin) transliteration helper.
///
/// Provides dual API:
/// - **Sync** (kana_kit only): instant, handles katakana/hiragana. Pure
///   kanji pass-through unchanged.
/// - **Async** (jp_transliterate → kana_kit fallback): full kanji support
///   via platform channel that has Japanese dictionary built-in. ~50-100ms
///   per call.
///
/// Caching: in-process Map<String, String> untuk instant look-up
/// saat field yang sama di-render ulang.
class JapaneseRomajiHelper {
  static final KanaKit _kanaKit = KanaKit();
  static final Map<String, String> _cache = {};

  /// Hit cache synchronously. Returns null kalau cache miss.
  static String? cacheLookup(String? input) {
    if (input == null || input.isEmpty) return null;
    return _cache[input];
  }

  /// Sync transliteration (kana_kit only, instant).
  ///
  /// Handles katakana/hiragana fields perfectly. Pure kanji fields will
  /// pass through unchanged (call [toRomajiAsync] later if needed).
  static String? toRomajiSync(String? input) {
    if (input == null || input.isEmpty) return null;
    final cached = _cache[input];
    if (cached != null) {
      return cached == _noConversionMarker ? null : cached;
    }
    final result = _kanaKit.toRomaji(input);
    if (result.isEmpty || result == input) {
      _cache[input] = _noConversionMarker; // mark as no-op
      return null;
    }
    _cache[input] = result;
    return result;
  }

  /// Async full transliteration (jp_transliterate for kanji → kana_kit fallback).
  ///
  /// Returns null kalau pure kanji dict tidak tersedia di platform.
  /// Cache semua result biar next render instant.
  static Future<String?> toRomajiAsync(String? input) async {
    if (input == null || input.isEmpty) return null;
    final cached = _cache[input];
    if (cached != null) {
      return cached == _noConversionMarker ? null : cached;
    }

    String? result;
    try {
      final hasKanji = await JpTransliterate.isKanji(input: input);
      if (hasKanji) {
        final data = await JpTransliterate.transliterate(kanji: input);
        result = data.romaji;
        appLogger.d('[Romaji/jp_transliterate] "$input" → "${result ?? 'null'}"');
      } else {
        final sync = _kanaKit.toRomaji(input);
        result = (sync.isNotEmpty && sync != input) ? sync : null;
        appLogger.d('[Romaji/kana_kit] "$input" → "${result ?? 'null'}"');
      }
    } catch (e) {
      appLogger.w('[Romaji] failed for "$input": $e');
      result = null;
    }

    if (result == null) {
      _cache[input] = _noConversionMarker;
    } else {
      _cache[input] = result;
    }
    return result;
  }

  /// Title-case helpers (untuk nama orang / kota)
  static String _titleCase(String input) {
    return input.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  static String? toTitleCaseRomajiSync(String? input) {
    final r = toRomajiSync(input);
    if (r == null) return null;
    return _titleCase(r);
  }

  static Future<String?> toTitleCaseRomajiAsync(String? input) async {
    final r = await toRomajiAsync(input);
    if (r == null) return null;
    return _titleCase(r);
  }

  /// Pre-warm cache dengan list of text (background-friendly).
  /// Skip kalau sudah ada di cache.
  static Future<void> warmCache(Iterable<String?> texts) async {
    for (final t in texts) {
      if (t == null || t.isEmpty) continue;
      if (_cache.containsKey(t)) continue;
      await toRomajiAsync(t);
    }
  }

  /// Clear cache (untuk debug/test).
  static void clearCache() => _cache.clear();

  /// Sentinel value untuk cache yang artinya input ga bisa di-convert
  static const String _noConversionMarker = '__LIQUID_NO_CONVERSION__';
}
