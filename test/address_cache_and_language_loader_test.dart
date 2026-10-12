import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/language_loader.dart';
import 'package:sixam_mart/util/app_constants.dart';

/// Covers the two startup/hot-path caches added to cut main-isolate work.
///
/// [AddressHelper] memoises the parsed address because
/// `getUserAddressFromSharedPref()` has 168 call sites — 109 of them in widgets,
/// several firing more than once per `build()`. The memo is keyed on the raw
/// stored string, so these tests care about one thing above all: that it can
/// never serve an address the prefs no longer hold.
///
/// [LanguageLoader] no longer loads every locale before `runApp`. These tests
/// pin the contract the rest of the app depends on: whatever the saved language
/// is, that locale *and* the fallback are present in the map handed to GetX.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, dynamic> addressJson(String label, {int zoneId = 1}) => <String, dynamic>{
        'id': 7,
        'address_type': label,
        'address': '$label street',
        'zone_id': zoneId,
        'zone_ids': <int>[zoneId],
        'latitude': '23.80',
        'longitude': '90.41',
      };

  Future<void> seedPrefs(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    Get.reset();
    Get.put<SharedPreferences>(prefs);
    // `saveUserAddressInSharedPref` refreshes the request header as well as the
    // stored address, so it needs an ApiClient in the container.
    Get.put<ApiClient>(ApiClient(appBaseUrl: AppConstants.baseUrl, sharedPreferences: prefs));
  }

  group('AddressHelper memoisation', () {
    test('repeated reads return the same parsed address', () async {
      await seedPrefs(<String, Object>{
        AppConstants.userAddress: jsonEncode(addressJson('home')),
      });

      final AddressModel? first = AddressHelper.getUserAddressFromSharedPref();
      final AddressModel? second = AddressHelper.getUserAddressFromSharedPref();

      expect(first, isNotNull);
      expect(first!.addressType, 'home');
      // Same instance — the second read did no decoding at all.
      expect(identical(first, second), isTrue);
    });

    // `saveUserAddressInSharedPref` is not exercised directly here: it also
    // refreshes the request header via `Get.find<SplashController>()`, a
    // pre-existing dependency that would need the whole splash graph stood up.
    // The guarantee that matters is covered by the next test — the memo tracks
    // whatever the pref holds, whoever wrote it.

    test('a pref written behind the helper\'s back is still picked up', () async {
      // The memo is keyed on the raw string rather than invalidated by hand, so
      // code that writes AppConstants.userAddress directly — or removes it, as
      // AuthRepository.clearSharedAddress() does on logout — cannot go stale.
      await seedPrefs(<String, Object>{
        AppConstants.userAddress: jsonEncode(addressJson('home')),
      });
      expect(AddressHelper.getUserAddressFromSharedPref()!.addressType, 'home');

      await Get.find<SharedPreferences>()
          .setString(AppConstants.userAddress, jsonEncode(addressJson('billing')));

      expect(AddressHelper.getUserAddressFromSharedPref()!.addressType, 'billing');
    });

    test('clearing the address stops it being served from the memo', () async {
      await seedPrefs(<String, Object>{
        AppConstants.userAddress: jsonEncode(addressJson('home')),
      });
      expect(AddressHelper.getUserAddressFromSharedPref(), isNotNull);

      AddressHelper.clearAddressFromSharedPref();

      expect(AddressHelper.getUserAddressFromSharedPref(), isNull);
    });

    test('a direct removal (logout path) is picked up without an explicit invalidate', () async {
      await seedPrefs(<String, Object>{
        AppConstants.userAddress: jsonEncode(addressJson('home')),
      });
      expect(AddressHelper.getUserAddressFromSharedPref(), isNotNull);

      await Get.find<SharedPreferences>().remove(AppConstants.userAddress);

      expect(AddressHelper.getUserAddressFromSharedPref(), isNull);
    });

    test('a corrupt stored value yields null rather than throwing', () async {
      await seedPrefs(<String, Object>{AppConstants.userAddress: 'not json at all'});

      expect(AddressHelper.getUserAddressFromSharedPref(), isNull);
    });
  });

  group('LanguageLoader.loadInitial', () {
    test('loads the saved locale and keeps the fallback alongside it', () async {
      final Map<String, Map<String, String>> languages = await LanguageLoader.loadInitial('ar');

      expect(languages.keys, containsAll(<String>['ar_SA', 'en_US']));
      expect(languages['ar_SA'], isNotEmpty);
      expect(languages['en_US'], isNotEmpty);
    });

    test('an unknown saved code falls back to the default locale', () async {
      final Map<String, Map<String, String>> languages = await LanguageLoader.loadInitial('zz');

      expect(languages.keys, <String>['en_US']);
      expect(languages['en_US'], isNotEmpty);
    });

    test('a null saved code (first launch) still yields a usable map', () async {
      final Map<String, Map<String, String>> languages = await LanguageLoader.loadInitial(null);

      expect(languages['en_US'], isNotEmpty);
    });

    test('the default locale is not read twice when it is also the active one', () async {
      final Map<String, Map<String, String>> languages = await LanguageLoader.loadInitial('en');

      expect(languages, hasLength(1));
      expect(languages.keys.single, 'en_US');
    });

    test('every locale key matches the format GetX stores translations under', () async {
      for (final dynamic language in AppConstants.languages) {
        final Map<String, Map<String, String>> languages =
            await LanguageLoader.loadInitial(language.languageCode as String);
        final String key = '${language.languageCode}_${language.countryCode}';
        expect(languages.containsKey(key), isTrue, reason: 'missing $key');
      }
    });

    test('the loaded values are real translations, not raw keys', () async {
      final Map<String, Map<String, String>> languages = await LanguageLoader.loadInitial('en');
      final Map<String, String> english = languages['en_US']!;

      // Sanity: a large key set, and values that differ from their keys.
      expect(english.length, greaterThan(1000));
      expect(english.entries.where((MapEntry<String, String> e) => e.key != e.value), isNotEmpty);
    });
  });
}
