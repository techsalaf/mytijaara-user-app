import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/language/domain/models/language_model.dart';
import 'package:sixam_mart/helper/json_parse_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';

/// Isolate entry point for [LanguageLoader]. Must stay top-level and pure — it
/// runs on a worker isolate, where there is no GetX container and no plugins.
Map<String, String> languageMapFromRawJson(String rawJson) {
  final Map<String, dynamic> mapped = jsonDecode(rawJson) as Map<String, dynamic>;
  final Map<String, String> values = <String, String>{};
  mapped.forEach((key, value) => values[key] = value.toString());
  return values;
}

/// Loads translation files on demand instead of all at once during startup.
///
/// `di.init()` used to load and decode **every** locale before `runApp` — around
/// 822 KB of JSON (`bn.json` alone is 292 KB), roughly 3000 keys each, one after
/// another on the main isolate. Three of the four were for languages the user
/// had not selected and might never open.
///
/// Now only the locales the first frame can actually render are loaded up front
/// (see [loadInitial]); the rest are appended to GetX's live translation map
/// after startup by [loadRemaining]. Because `Get.appendTranslations` mutates the
/// map `.tr` reads from, a locale appended later is picked up with no rebuild
/// plumbing of its own.
///
/// [ensureLoaded] closes the only gap this opens: switching to a locale that has
/// not finished loading would show raw key names, so `LocalizationController`
/// awaits it before calling `Get.updateLocale`.
class LanguageLoader {
  const LanguageLoader._();

  /// The key GetX stores translations under — must match what `Messages` returns.
  static String localeKeyOf(LanguageModel language) => '${language.languageCode}_${language.countryCode}';

  static final Set<String> _loaded = <String>{};

  /// In-flight loads, so a locale requested twice at once (post-frame warm-up
  /// racing a user tapping that language) is only read and parsed once.
  static final Map<String, Future<void>> _inFlight = <String, Future<void>>{};

  static Future<Map<String, String>?> _read(LanguageModel language) async {
    try {
      final String raw = await rootBundle.loadString('assets/language/${language.languageCode}.json');
      return await JsonParseHelper.parse(raw, languageMapFromRawJson, debugLabel: 'language.${language.languageCode}');
    } catch (e) {
      debugPrint('Failed to load language "${language.languageCode}": $e');
      return null;
    }
  }

  /// The locales that must be in place before the first frame: the one the user
  /// last selected, plus [AppConstants.languages]`[0]` as the fallback GetX drops
  /// to for any key the active locale is missing.
  ///
  /// A file that fails to load is skipped rather than thrown, so a corrupt or
  /// missing asset degrades to untranslated keys instead of blocking startup.
  static Future<Map<String, Map<String, String>>> loadInitial(String? savedLanguageCode) async {
    final LanguageModel fallback = AppConstants.languages[0];
    final LanguageModel active = AppConstants.languages.firstWhere(
      (LanguageModel language) => language.languageCode == savedLanguageCode,
      orElse: () => fallback,
    );

    final Map<String, Map<String, String>> languages = <String, Map<String, String>>{};
    // A Set so 'en' is not read twice when it is also the active locale — these
    // are the same instances out of AppConstants.languages, so identity dedupes.
    for (final LanguageModel language in <LanguageModel>{active, fallback}) {
      final Map<String, String>? values = await _read(language);
      if (values != null) {
        languages[localeKeyOf(language)] = values;
        _loaded.add(localeKeyOf(language));
      }
    }
    return languages;
  }

  /// Appends every locale not covered by [loadInitial]. Call after the first
  /// frame — it is idempotent, so a repeat call is a no-op.
  static Future<void> loadRemaining() async {
    for (final LanguageModel language in AppConstants.languages) {
      await ensureLoaded(language);
    }
  }

  /// Guarantees [language] is available to `.tr` before the caller switches to it.
  static Future<void> ensureLoaded(LanguageModel language) {
    final String key = localeKeyOf(language);
    if (_loaded.contains(key)) return Future<void>.value();

    final Future<void>? pending = _inFlight[key];
    if (pending != null) return pending;

    final Future<void> load = _read(language).then((Map<String, String>? values) {
      if (values != null) {
        Get.appendTranslations(<String, Map<String, String>>{key: values});
        _loaded.add(key);
      }
    }).whenComplete(() => _inFlight.remove(key));

    _inFlight[key] = load;
    return load;
  }

  /// [ensureLoaded] for a [Locale], matching on language code so a locale built
  /// with a different country code than [AppConstants.languages] still resolves.
  static Future<void> ensureLocaleLoaded(Locale locale) {
    for (final LanguageModel language in AppConstants.languages) {
      if (language.languageCode == locale.languageCode) {
        return ensureLoaded(language);
      }
    }
    return Future<void>.value();
  }
}
