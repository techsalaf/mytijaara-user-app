import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/api/response_parser.dart';
import 'package:sixam_mart/features/brands/domain/models/brands_model.dart';

/// Cover for the top-brands section on the grocery and shop home screens.
///
/// `BrandsRepository.getBrandList` is cache-first: the client branch parses the
/// network response and writes it to the Drift cache, then the local branch
/// re-reads and re-parses that cache on the next launch. The two branches must
/// agree on the stored shape.
///
/// They did not. The client branch extracted the list out of `{data, pagination}`
/// but cached the **whole body**, while the local branch iterated the decoded
/// cache as a bare list — so the first launch worked off the network and every
/// launch afterwards iterated a Map and threw. These tests pin the round trip.
void main() {
  final Directory fixtures = Directory('test/fixtures/live');
  final bool has = fixtures.existsSync();

  dynamic payload(String name) => ApiClient.unwrapEnvelope(
        jsonDecode(File('${fixtures.path}/$name.json').readAsStringSync()),
        200,
      );

  List<BrandModel> toBrands(dynamic body) =>
      ResponseParser.listOrEmpty(body).map((dynamic e) => BrandModel.fromJson(e)).toList();

  test('the live entry shape matches what docs/New-api-responses.md documents', () {
    // docs/New-api-responses.md, GET api/v1/brand:
    //   content.data[] = {id, name, slug, image_full_url, items_count}
    // Pinned here so a backend change to the entry shape fails a test rather
    // than silently emptying the top-brands row.
    const Set<String> documented = <String>{'id', 'name', 'slug', 'image_full_url', 'items_count'};
    final Map<String, dynamic> body = payload('brand') as Map<String, dynamic>;
    expect(body.keys, containsAll(<String>['data', 'pagination']));
    final Map<String, dynamic> entry = (body['data'] as List<dynamic>).first as Map<String, dynamic>;
    expect(entry.keys.toSet(), documented,
        reason: 'live entry keys drifted from the documented brand shape');
  }, skip: !has);

  test('the fields BrandModel reads but the API no longer sends stay null', () {
    // status / created_at / updated_at / translations were dropped from the
    // payload. Nothing reads them off BrandModel, and they must not throw.
    final BrandModel brand = BrandModel.fromJson(<String, dynamic>{
      'id': 9, 'name': 'Urban Threads', 'slug': 'urban-threads',
      'image_full_url': null, 'items_count': 0,
    });
    expect(brand.status, isNull);
    expect(brand.createdAt, isNull);
    expect(brand.updatedAt, isNull);
    expect(brand.translations, isNull);
    expect(brand.id, 9);
  });

  test('the live payload parses into brands', () {
    final List<BrandModel> brands = toBrands(payload('brand'));
    expect(brands, isNotEmpty);
    expect(brands.first.id, isNotNull);
    expect(brands.first.name, isNotNull);
    // image_full_url is null on this environment; itemsCount defaults rather than
    // throwing when the key is absent.
    expect(brands.first.itemsCount, isNotNull);
  }, skip: !has);

  test('the cache round trip yields the same brands as the network parse', () {
    // Exactly what the repository does: extract, cache the extracted list, then
    // decode and re-extract on the next launch.
    final dynamic networkBody = payload('brand');
    final List<dynamic> extracted = ResponseParser.listOrEmpty(networkBody);

    final String cached = jsonEncode(extracted);
    final List<BrandModel> fromCache = toBrands(jsonDecode(cached));
    final List<BrandModel> fromNetwork = toBrands(networkBody);

    expect(fromCache.length, fromNetwork.length);
    expect(fromCache.map((BrandModel b) => b.id), fromNetwork.map((BrandModel b) => b.id));
    expect(fromCache.map((BrandModel b) => b.name), fromNetwork.map((BrandModel b) => b.name));
  }, skip: !has);

  test('a cache entry written as the raw wrapper still reads back', () {
    // Defensive: an entry cached by an older build holds `{data, pagination}`.
    // The schema version retires those, but reading one must not throw.
    final String staleCache = jsonEncode(payload('brand'));
    expect(toBrands(jsonDecode(staleCache)), isNotEmpty);
  }, skip: !has);

  test('a legacy bare-array payload still parses', () {
    final List<BrandModel> brands = toBrands(<dynamic>[
      <String, dynamic>{'id': 9, 'name': 'Urban Threads', 'slug': 'urban-threads'},
    ]);
    expect(brands, hasLength(1));
    expect(brands.single.name, 'Urban Threads');
    expect(brands.single.itemsCount, 0, reason: 'items_count absent defaults to 0');
  });

  test('an empty brand list stays empty rather than throwing', () {
    expect(toBrands(<String, dynamic>{'data': <dynamic>[], 'pagination': <String, dynamic>{}}), isEmpty);
    expect(toBrands(<String, dynamic>{'message': 'none'}), isEmpty);
  });
}
