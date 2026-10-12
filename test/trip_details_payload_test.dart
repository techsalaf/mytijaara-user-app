import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/api/json_reader.dart';
import 'package:sixam_mart/features/rental_module/common/models/trip_details_model.dart';

/// `GET /api/v1/rental/user/trip/get-trip-details` — the screen the rental
/// booking flow navigates to after "Confirm booking".
///
/// `vehicle_details` stopped carrying `images_full_url` / `documents_full_url`,
/// and the model read them with `json[...].cast<String>()`. On the missing key
/// that threw `NoSuchMethodError: The method 'cast' was called on null`, which
/// aborted the whole TripDetailsModel parse — so a trip that booked fine landed
/// on an empty details screen.
void main() {
  // Trimmed from a real 200 response (trip 100262), keeping the shape intact.
  // Note `images` / `documents` arrive as JSON-encoded *strings*, not arrays —
  // which is why the model declares them `String?` — and no `*_full_url` key
  // appears anywhere on vehicle_details.
  const String liveBody = '''
  {"id":100262,"trip_amount":1841.3035,"discount_on_trip":135.652,
   "coupon_discount_amount":0,"pro_discount":0,"trip_status":"pending",
   "payment_status":"unpaid","tax_amount":610.4345,"tax_status":"excluded",
   "trip_type":"distance_wise","additional_charge":10,"distance":13.56520502,
   "estimated_hours":0,"quantity":1,
   "pickup_location":{"lat":23.73,"lng":90.37,"location_name":"Unknown Location Found","location_type":null},
   "destination_location":{"lat":23.78,"lng":90.25,"location_name":"Savar","location_type":"office"},
   "trip_details":[{"id":297,"trip_id":100262,"vehicle_id":23,"quantity":1,
     "price":1356.521,"original_price":1356.521,"calculated_price":1356.521,
     "discount_on_trip":135.652,"tax_amount":610.4345,"discount_type":"percent",
     "vehicle_details":{"id":23,"name":"Veda Albert","description":"Neque eum doloremque",
       "thumbnail":"2025-07-02-68654009994ff.png",
       "images":"[{\\"img\\":\\"2025-07-02-686540099b316.png\\",\\"storage\\":\\"public\\"}]",
       "documents":"[{\\"img\\":\\"2025-07-02-686540099d8ea.jpg\\",\\"storage\\":\\"public\\"}]",
       "zone_id":1,"provider_id":66,"brand_id":1,"category_id":9,"model":"180",
       "type":"luxury","engine_capacity":"806","engine_power":"355",
       "seating_capacity":"540","fuel_type":"CNG","hourly_price":300,
       "distance_price":100,"discount_type":"percent","discount_price":10,
       "status":1,"total_trip":30,"avg_rating":3,"total_reviews":2,"slug":"veda-albert"},
     "rental_type":"distance_wise","distance":13.56520502,"scheduled":0,
     "license_plate_number":[]}],
   "vehicle_identity":[],
   "provider":{"id":66,"name":"RideMaster Taxis","rating":[3,2,0,1,0],
     "phone":"+8801621720023","avg_rating":4.17,"rating_count":6,"verified_seller":1}}
  ''';

  test('the live payload parses instead of throwing on the missing full urls', () {
    // Before the fix this threw NoSuchMethodError on `null.cast<String>()`.
    final TripDetailsModel model =
        TripDetailsModel.fromJson(jsonDecode(liveBody) as Map<String, dynamic>);

    expect(model.id, 100262);
    expect(model.tripStatus, 'pending');
    expect(model.tripDetails, isNotNull);
    expect(model.tripDetails!.length, 1);

    final VehicleDetails vehicle = model.tripDetails!.first.vehicleDetails!;
    expect(vehicle.id, 23);
    expect(vehicle.name, 'Veda Albert');
    // Absent in the payload — null, not a crash, and not an empty-list lie.
    expect(vehicle.imagesFullUrl, isNull);
    expect(vehicle.documentsFullUrl, isNull);
    expect(vehicle.thumbnailFullUrl, isNull);
    // Still present, still read.
    expect(vehicle.thumbnail, '2025-07-02-68654009994ff.png');
  });

  test('license_plate_number survives being absent as well as empty', () {
    final Map<String, dynamic> body = jsonDecode(liveBody) as Map<String, dynamic>;
    expect(TripDetailsModel.fromJson(body).tripDetails!.first.licensePlateNumber, isEmpty);

    (body['trip_details'] as List).first.remove('license_plate_number');
    expect(TripDetailsModel.fromJson(body).tripDetails!.first.licensePlateNumber, isNull);
  });

  test('a backend that still sends the full urls parses them unchanged', () {
    final Map<String, dynamic> body = jsonDecode(liveBody) as Map<String, dynamic>;
    final Map<String, dynamic> vehicle =
        (body['trip_details'] as List).first['vehicle_details'] as Map<String, dynamic>;
    vehicle['images_full_url'] = <String>['https://host/a.png', 'https://host/b.png'];
    vehicle['documents_full_url'] = <String>['https://host/d.jpg'];
    vehicle['thumbnail_full_url'] = 'https://host/t.png';

    final VehicleDetails parsed =
        TripDetailsModel.fromJson(body).tripDetails!.first.vehicleDetails!;
    expect(parsed.imagesFullUrl, <String>['https://host/a.png', 'https://host/b.png']);
    expect(parsed.documentsFullUrl, <String>['https://host/d.jpg']);
    expect(parsed.thumbnailFullUrl, 'https://host/t.png');
  });

  test('numeric spec fields do not crash when sent as numbers', () {
    // engine_capacity / engine_power / seating_capacity / model are declared
    // `String?` but have been seen arriving as ints; assigning one straight
    // through throws a TypeError and aborts the whole parse.
    final Map<String, dynamic> body = jsonDecode(liveBody) as Map<String, dynamic>;
    final Map<String, dynamic> vehicle =
        (body['trip_details'] as List).first['vehicle_details'] as Map<String, dynamic>;
    vehicle['model'] = 180;
    vehicle['engine_capacity'] = 806;
    vehicle['engine_power'] = 355;
    vehicle['seating_capacity'] = 540;

    final VehicleDetails parsed =
        TripDetailsModel.fromJson(body).tripDetails!.first.vehicleDetails!;
    expect(parsed.model, '180');
    expect(parsed.engineCapacity, '806');
    expect(parsed.enginePower, '355');
    expect(parsed.seatingCapacity, '540');
  });

  group('JsonReader.toStringList', () {
    test('reads a list, coercing non-string entries', () {
      expect(JsonReader.toStringList(<dynamic>['a', 'b']), <String>['a', 'b']);
      expect(JsonReader.toStringList(<dynamic>[1, 2]), <String>['1', '2']);
      expect(JsonReader.toStringList(<dynamic>[null]), <String>['']);
      expect(JsonReader.toStringList(<dynamic>[]), isEmpty);
    });

    test('returns null for anything that is not a list', () {
      expect(JsonReader.toStringList(null), isNull);
      expect(JsonReader.toStringList('abc'), isNull);
      expect(JsonReader.toStringList(<String, dynamic>{}), isNull);
    });
  });
}
