import 'package:sixam_mart/api/json_reader.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';

/// The payload of an enveloped response — `content` when the envelope is there,
/// the body itself on an endpoint that still answers bare.
Map<String, dynamic> bundleContentOf(Map<String, dynamic> json) {
  final dynamic content = json['content'];
  if(content is Map<String, dynamic>) {
    return content;
  }
  if(content is Map) {
    return Map<String, dynamic>.from(content);
  }
  return json;
}

class BundleListModel {
  final List<Bundle> bundles;
  final int? totalSize;
  final int? currentPage;
  final int? lastPage;

  const BundleListModel({required this.bundles, this.totalSize, this.currentPage, this.lastPage});

  factory BundleListModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> content = bundleContentOf(json);
    final dynamic rows = content['data'] ?? content['bundles'];
    final dynamic pagination = content['pagination'];
    final Map<String, dynamic>? page = pagination is Map ? Map<String, dynamic>.from(pagination) : null;

    return BundleListModel(
      bundles: rows is List
          ? rows.whereType<Map>().map((row) => Bundle.fromJson(Map<String, dynamic>.from(row))).toList()
          : const [],
      totalSize: JsonReader.toInt(page?['total']),
      currentPage: JsonReader.toInt(page?['current_page']),
      lastPage: JsonReader.toInt(page?['last_page']),
    );
  }
}

class Bundle {
  final int? id;
  final String? name;
  final String? description;
  final String? slug;
  final String? imageFullUrl;
  final int? storeId;
  final String? storeLogoFullUrl;
  final String? storeName;
  final int? moduleId;
  final String? startDate;
  final String? endDate;
  final int? itemCount;
  final double basePrice;
  final double bundlePrice;
  final double discountPercentage;
  final double discountAmount;
  final double finalPrice;
  final bool isHappyHour;
  final bool isAvailable;
  final String? unavailableReason;
  final List<BundleMemberItem>? items;

  const Bundle({
    this.id, this.name, this.description, this.slug, this.imageFullUrl,
    this.storeId, this.storeName, this.storeLogoFullUrl, this.moduleId, this.startDate, this.endDate,
    this.itemCount, this.basePrice = 0, this.bundlePrice = 0, this.discountPercentage = 0, this.discountAmount = 0,
    this.finalPrice = 0, this.isHappyHour = false, this.isAvailable = true, this.unavailableReason, this.items,
  });

  factory Bundle.fromJson(Map<String, dynamic> json) {
    final dynamic rows = json['items'];
    return Bundle(
      id: JsonReader.toInt(json['id']),
      name: JsonReader.toStr(json['name']),
      description: JsonReader.toStr(json['description']),
      slug: JsonReader.toStr(json['slug']),
      imageFullUrl: JsonReader.toStr(json['image_full_url']),
      storeId: JsonReader.toInt(json['store_id']),
      storeName: JsonReader.toStr(json['store_name']),
      storeLogoFullUrl: JsonReader.toStr(json['store_logo_full_url']),
      moduleId: JsonReader.toInt(json['module_id']),
      startDate: JsonReader.toStr(json['start_date']),
      endDate: JsonReader.toStr(json['end_date']),
      itemCount: JsonReader.toInt(json['item_count']),
      basePrice: JsonReader.toDouble(json['base_price']) ?? 0,
      bundlePrice: JsonReader.toDouble(json['bundle_price']) ?? 0,
      discountPercentage: JsonReader.toDouble(json['discount_percentage']) ?? 0,
      discountAmount: JsonReader.toDouble(json['discount_amount']) ?? 0,
      finalPrice: JsonReader.toDouble(json['final_price']) ?? 0,
      isHappyHour: json['is_happy_hour'] == true,
      isAvailable: json['is_available'] != false,
      unavailableReason: JsonReader.toStr(json['unavailable_reason']),
      items: rows is List
          ? rows.whereType<Map>().map((row) => BundleMemberItem.fromJson(Map<String, dynamic>.from(row))).toList()
          : null,
    );
  }

  factory Bundle.fromResponse(Map<String, dynamic> json) => Bundle.fromJson(bundleContentOf(json));

  /// Worth striking through only when the bundle actually saves the customer
  /// something; an undiscounted one would print the same figure twice.
  bool get hasSaving => basePrice > finalPrice;

  /// The badge on a card — `-10%`.
  String get discountLabel => '-${discountPercentage % 1 == 0 ? discountPercentage.toInt() : discountPercentage}%';

  /// One entry per member, empty string where a member has no picture. Empty
  /// entries are kept rather than dropped: removing them made a bundle look
  /// shorter than it is. Null on the list endpoints, where [itemCount] is all
  /// the card has to go on.
  List<String> get itemThumbnails =>
      (items ?? const <BundleMemberItem>[]).map((item) => item.imageFullUrl ?? '').toList();

  /// How many members the card knows about, whether or not it has their pictures.
  int get memberCount => itemCount ?? items?.length ?? 0;
}

/// One member of a bundle.
///
/// A line names exactly one target — an item, or a service in a service module —
/// with [isService] saying which. `unit_price` is the frozen snapshot the bundle
/// was priced on, so it can differ from today's menu price.
class BundleMemberItem {
  final int? itemId;
  final int? serviceId;
  final bool isService;
  final String? name;
  final String? imageFullUrl;
  final double unitPrice;
  final int quantity;

  /// A ready-to-render string — `"Large, Extra cheese"` — built from the raw
  /// `variations` rows. Render this for display; [variations] is the same
  /// data structured, for matching against the live item's own option lists.
  final String? variationSummary;

  final String? unitType;

  /// The variation groups this member was locked to — `{name, values:
  /// {label: [...]}}` per group, the same shape [OrderVariation] already
  /// parses for a normal order. Empty for a member built with no variation.
  final List<OrderVariation> variations;

  /// The add-ons this member was built with, id-and-quantity, parallel arrays
  /// straight off the wire (`add_on_ids[i]` was ordered at `add_on_qtys[i]`).
  /// Always empty for a service line — a service carries no add-ons.
  final List<int> addOnIds;
  final List<int> addOnQtys;

  /// A ready-to-render string — `"Extra Meat (2)"` — built server-side from
  /// [addOnIds]/[addOnQtys]. Render this for display, the same way
  /// [variationSummary] stands in for [variations].
  final String? addOnSummary;

  const BundleMemberItem({
    this.itemId, this.serviceId, this.isService = false, this.name, this.imageFullUrl,
    this.unitPrice = 0, this.quantity = 1, this.variationSummary, this.unitType,
    this.variations = const <OrderVariation>[],
    this.addOnIds = const <int>[], this.addOnQtys = const <int>[], this.addOnSummary,
  });

  factory BundleMemberItem.fromJson(Map<String, dynamic> json) {
    final int? itemId = JsonReader.toInt(json['item_id']);
    final int? serviceId = JsonReader.toInt(json['service_id']);
    final dynamic rawVariations = json['variations'];
    return BundleMemberItem(
      itemId: itemId,
      serviceId: serviceId,
      isService: json['is_service'] == true || (itemId == null && serviceId != null),
      name: JsonReader.toStr(json['name']),
      imageFullUrl: JsonReader.toStr(json['image_full_url']),
      unitPrice: JsonReader.toDouble(json['unit_price']) ?? 0,
      quantity: JsonReader.toInt(json['quantity']) ?? 1,
      variationSummary: JsonReader.toStr(json['variation_summary']),
      unitType: JsonReader.toStr(json['unit_type']),
      variations: rawVariations is List
          ? rawVariations.whereType<Map>().map((row) => OrderVariation.fromJson(Map<String, dynamic>.from(row))).toList()
          : const <OrderVariation>[],
      addOnIds: JsonReader.toIntList(json['add_on_ids']),
      addOnQtys: JsonReader.toIntList(json['add_on_qtys']),
      addOnSummary: JsonReader.toStr(json['add_on_summary']),
    );
  }

  /// Whichever of the two ids this member actually names — what the item-detail
  /// sheet is opened with.
  int? get targetId => isService ? serviceId : itemId;
}
