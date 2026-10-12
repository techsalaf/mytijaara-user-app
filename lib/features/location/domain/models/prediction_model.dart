/// The parsed body of `GET /api/v1/config/place-api-autocomplete`.
///
/// The endpoint proxies Google Places and answers **HTTP 200 even when Places
/// itself failed** — the failure arrives inside the envelope's `content`:
///
/// ```json
/// {"error": {"code": 400, "message": "API key not valid. Please pass a valid
///            API key.", "status": "INVALID_ARGUMENT", "details": [...]}}
/// ```
///
/// so there is no `suggestions` key to read and no non-2xx status to branch on.
/// This wrapper makes the two outcomes explicit instead of letting a failure
/// masquerade as "no results found".
class PlaceAutocompleteResult {
  final List<PredictionModel> predictions;

  /// Set when Places (or the proxy) reported a failure. `predictions` is then
  /// empty, and the caller must tell the user rather than showing an empty list.
  final String? errorMessage;
  final bool hasError;

  const PlaceAutocompleteResult({required this.predictions, this.errorMessage, this.hasError = false});

  const PlaceAutocompleteResult.failure(this.errorMessage)
      : predictions = const <PredictionModel>[], hasError = true;

  factory PlaceAutocompleteResult.fromBody(dynamic body) {
    // A non-JSON body, or the empty Response ApiChecker returns after handling
    // an error itself — nothing to read, and nothing new to tell the user.
    if (body is! Map) return const PlaceAutocompleteResult(predictions: <PredictionModel>[]);

    // Places (New) reports failure as a nested `error` object...
    final dynamic error = body['error'];
    if (error is Map) {
      final dynamic message = error['message'];
      return PlaceAutocompleteResult.failure(message is String && message.isNotEmpty ? message : null);
    }
    // ...the legacy Places API used a flat `error_message` beside `status`.
    final dynamic legacyMessage = body['error_message'];
    if (legacyMessage is String && legacyMessage.isNotEmpty) {
      return PlaceAutocompleteResult.failure(legacyMessage);
    }

    final dynamic suggestions = body['suggestions'];
    if (suggestions is! List) return const PlaceAutocompleteResult(predictions: <PredictionModel>[]);

    // Parsed one entry at a time: `suggestions` also carries `queryPrediction`
    // entries, which have no `placePrediction` to read. Letting one of those
    // throw past the loop discarded every other suggestion with it.
    final List<PredictionModel> predictions = <PredictionModel>[];
    for (final dynamic suggestion in suggestions) {
      final PredictionModel? prediction = PredictionModel.tryFromJson(suggestion);
      if (prediction != null) predictions.add(prediction);
    }
    return PlaceAutocompleteResult(predictions: predictions);
  }
}

class PredictionModel {
  String? description;
  String? id;
  int? distanceMeters;
  String? placeId;
  String? reference;
  String? place;
  TextModel? text;
  StructuredFormat? structuredFormat;
  List<String>? types;

  PredictionModel({
    this.description,
    this.id,
    this.distanceMeters,
    this.placeId,
    this.reference,
    this.place,
    this.text,
    this.structuredFormat,
    this.types,
  });

  /// One `suggestions[]` entry, or null when it isn't a place suggestion —
  /// a `queryPrediction` entry, or anything missing the fields below.
  static PredictionModel? tryFromJson(dynamic suggestion) {
    if (suggestion is! Map) return null;
    final dynamic prediction = suggestion['placePrediction'];
    if (prediction is! Map) return null;
    return PredictionModel.fromJson(Map<String, dynamic>.from(suggestion));
  }

  PredictionModel.fromJson(Map<String, dynamic> json) {
    // Guarded rather than chained: `text` and `types` are optional on a place
    // prediction, and the previous chained reads threw on the first entry that
    // omitted one — taking the whole suggestion list down with it.
    final Map<String, dynamic> prediction = json['placePrediction'] is Map
        ? Map<String, dynamic>.from(json['placePrediction'] as Map)
        : <String, dynamic>{};
    final dynamic textJson = prediction['text'];
    final String? textValue = textJson is Map ? textJson['text']?.toString() : null;

    description = textValue;
    id = prediction['placeId']?.toString();
    placeId = prediction['placeId']?.toString();
    place = prediction['place']?.toString();
    reference = textValue;
    types = prediction['types'] is List
        ? List<String>.from((prediction['types'] as List).map((dynamic e) => e.toString()))
        : <String>[];
    text = textJson is Map ? TextModel.fromJson(Map<String, dynamic>.from(textJson)) : null;
    structuredFormat = prediction['structuredFormat'] is Map
        ? StructuredFormat.fromJson(Map<String, dynamic>.from(prediction['structuredFormat'] as Map))
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['placePrediction'] = {
      'text': text?.toJson(),
      'placeId': placeId,
      'place': place,
      'types': types,
      'structuredFormat': structuredFormat?.toJson(),
    };
    return data;
  }
}

class TextModel {
  String? text;
  List<Match>? matches;

  TextModel({this.text, this.matches});

  TextModel.fromJson(Map<String, dynamic> json) {
    text = json['text'];
    if (json['matches'] != null) {
      matches = <Match>[];
      json['matches'].forEach((v) {
        matches!.add(Match.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['text'] = text;
    if (matches != null) {
      data['matches'] = matches!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Match {
  int? endOffset;

  Match({this.endOffset});

  Match.fromJson(Map<String, dynamic> json) {
    endOffset = json['endOffset'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['endOffset'] = endOffset;
    return data;
  }
}

class StructuredFormat {
  MainText? mainText;
  SecondaryText? secondaryText;

  StructuredFormat({this.mainText, this.secondaryText});

  StructuredFormat.fromJson(Map<String, dynamic> json) {
    mainText = json['mainText'] != null ? MainText.fromJson(json['mainText']) : null;
    secondaryText = json['secondaryText'] != null ? SecondaryText.fromJson(json['secondaryText']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (mainText != null) {
      data['mainText'] = mainText!.toJson();
    }
    if (secondaryText != null) {
      data['secondaryText'] = secondaryText!.toJson();
    }
    return data;
  }
}

class MainText {
  String? text;
  List<Match>? matches;

  MainText({this.text, this.matches});

  MainText.fromJson(Map<String, dynamic> json) {
    text = json['text'];
    if (json['matches'] != null) {
      matches = <Match>[];
      json['matches'].forEach((v) {
        matches!.add(Match.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['text'] = text;
    if (matches != null) {
      data['matches'] = matches!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class SecondaryText {
  String? text;

  SecondaryText({this.text});

  SecondaryText.fromJson(Map<String, dynamic> json) {
    text = json['text'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['text'] = text;
    return data;
  }
}