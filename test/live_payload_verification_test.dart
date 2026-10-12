import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/api/response_parser.dart';
import 'package:sixam_mart/common/models/config_model.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/banner/domain/models/banner_model.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/features/home/domain/models/top_offer_model.dart';
import 'package:sixam_mart/features/item/domain/models/common_condition_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_model.dart';
import 'package:sixam_mart/features/smart_banner/domain/models/smart_banner_model.dart';

/// Runs the real startup payloads captured from the live backend through the
/// exact parsing path a repository uses.
///
/// Fixtures live in `test/fixtures/live/` and were captured with
/// `curl <baseUrl>/api/v1/<endpoint>`. Refresh them by re-running that curl if the
/// backend's shape changes. Skipped automatically when the fixtures are absent so
/// the suite still runs on a checkout without them.
void main() {
  final Directory fixtures = Directory('test/fixtures/live');

  dynamic payload(String name) {
    final File f = File('${fixtures.path}/$name.json');
    return ApiClient.unwrapEnvelope(jsonDecode(f.readAsStringSync()), 200);
  }

  setUpAll(() {
    if (!fixtures.existsSync()) {
      markTestSkipped('live fixtures not present — skipping');
    }
  });

  test('GET /config parses into ConfigModel with the fields home depends on', () {
    final ConfigModel config = ConfigModel.fromJson(payload('config') as Map<String, dynamic>);
    expect(config.businessName, isNotNull);
    expect(config.currencySymbol, isNotNull);
    expect(config.moduleConfig, isNotNull);
    // repeatOrderOption gates the last-orders strip on home.
    expect(config.repeatOrderOption, isNotNull);
  }, skip: !fixtures.existsSync());

  test('GET /module yields the dashboard module tabs', () {
    final List<ModuleModel> modules =
        ResponseParser.listOrEmpty(payload('module')).map((dynamic e) => ModuleModel.fromJson(e)).toList();
    expect(modules, isNotEmpty);
    expect(modules.first.id, isNotNull);
    expect(modules.first.moduleType, isNotNull);
  }, skip: !fixtures.existsSync());

  test('GET /categories yields the category row', () {
    final List<CategoryModel> categories =
        ResponseParser.listOrEmpty(payload('categories')).map((dynamic e) => CategoryModel.fromJson(e)).toList();
    expect(categories, isNotEmpty);
    expect(categories.first.name, isNotNull);
  }, skip: !fixtures.existsSync());

  test('GET /banners yields campaigns and banners without any list extraction', () {
    // content is {campaigns, banners} — BannerModel reads both keys directly, so
    // unwrapping the envelope is the whole fix for this endpoint.
    final BannerModel banner = BannerModel.fromJson(payload('banners') as Map<String, dynamic>);
    expect(banner.campaigns, isNotNull);
    expect(banner.banners, isNotNull);
  }, skip: !fixtures.existsSync());

  test('GET /smart-banners yields banners from the data key', () {
    final SmartBannerModel model =
        SmartBannerModel.fromJson(payload('smart-banners') as Map<String, dynamic>);
    expect(model.smartBanners, isNotEmpty);
    expect(model.smartBanners!.first.title, isNotNull);
  }, skip: !fixtures.existsSync());

  test('GET /common-condition yields the pharmacy shop-by-condition row', () {
    final List<CommonConditionModel> conditions = ResponseParser.listOrEmpty(payload('common-condition'))
        .map((dynamic e) => CommonConditionModel.fromJson(e))
        .toList();
    expect(conditions, isNotEmpty);
  }, skip: !fixtures.existsSync());

  test('GET /module/top-offer parses into TopOfferModel', () {
    final TopOfferModel offer = TopOfferModel.fromJson(payload('module-top-offer') as Map<String, dynamic>);
    expect(offer.discount, isNotNull);
  }, skip: !fixtures.existsSync());

  test('GET /config/get-zone-id resolves the zone the whole app is scoped by', () {
    final ZoneModel zone = ZoneModel.fromJson(payload('config-get-zone-id') as Map<String, dynamic>);
    expect(zone.zoneIds, isNotEmpty);
  }, skip: !fixtures.existsSync());

  test('GET /stores/get-stores/all?featured=1 yields the featured store list', () {
    final List<dynamic> stores = ResponseParser.listOrEmpty(payload('stores-featured'), legacyKey: 'stores');
    expect(stores, isNotEmpty);
    expect(stores.first['id'], isNotNull);
    expect(stores.first['name'], isNotNull);
  }, skip: !fixtures.existsSync());
}
