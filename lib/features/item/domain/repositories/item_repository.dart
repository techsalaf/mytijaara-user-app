import 'dart:convert';

import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/api/local_client.dart';
import 'package:sixam_mart/api/response_parser.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/item/domain/models/basic_medicine_model.dart';
import 'package:sixam_mart/features/item/domain/models/common_condition_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_review_model.dart';
import 'package:sixam_mart/features/item/domain/repositories/item_repository_interface.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';

class ItemRepository implements ItemRepositoryInterface {
  final ApiClient apiClient;
  ItemRepository({required this.apiClient});

  @override
  Future<BasicMedicineModel?> getBasicMedicine(DataSourceEnum source) async {
    BasicMedicineModel? basicMedicineModel;
    String cacheId = '${AppConstants.basicMedicineUri}?offset=1&limit=50-${Get.find<SplashController>().module?.id??0}';

    switch(source) {

      case DataSourceEnum.client:
        Response response = await apiClient.getData('${AppConstants.basicMedicineUri}?offset=1&limit=50');
        if (response.statusCode == 200) {
          basicMedicineModel = BasicMedicineModel.fromJson(response.body);
          LocalClient.organize(DataSourceEnum.client, cacheId, response.bodyString ?? '', apiClient.getHeader());
        }

      case DataSourceEnum.local:
        String? cacheResponseData = await LocalClient.organize(DataSourceEnum.local, cacheId, null, null);
        if(cacheResponseData != null) {
          basicMedicineModel = BasicMedicineModel.fromJson(ResponseParser.payloadOf(jsonDecode(cacheResponseData)));
        }
    }
    return basicMedicineModel;
  }

  @override
  Future get(String? id, {bool isConditionWiseItem = false, bool isCampaign = false, DataSourceEnum? source}) async {
    if(isConditionWiseItem) {
      return await _getConditionsWiseItems(int.parse(id!), source ?? DataSourceEnum.client);
    } else {
      return await _getItemDetails(int.parse(id!), isCampaign);
    }
  }

  Future<Item?> _getItemDetails(int? itemID, bool isCampaign) async {
    Item? item;
    Response response = await apiClient.getData('${AppConstants.itemDetailsUri}$itemID${isCampaign ? '?campaign=1' : ''}', handleError: false);
    if (response.statusCode == 200) {
      item = Item.fromJson(response.body);
    }
    else{
      showCustomSnackBar(_errorMessage(response));
    }
    return item;
  }

  /// The envelope reports failures as `errors: [{code, message}]` — a **list**. Reading
  /// it as a map (`body['errors']['message']`) threw
  /// `type 'String' is not a subtype of type 'int' of 'index'`, turning every item-details
  /// 404 into a crash instead of a message. Falls back to the envelope's own `message`,
  /// then to the status text.
  String? _errorMessage(Response response) {
    final dynamic body = response.body;
    if(body is Map) {
      final dynamic errors = body['errors'];
      if(errors is List && errors.isNotEmpty && errors.first is Map) {
        final dynamic message = errors.first['message'];
        if(message != null) {
          return message.toString();
        }
      }
      if(errors is Map && errors['message'] != null) {
        return errors['message'].toString();
      }
      if(body['message'] != null) {
        return body['message'].toString();
      }
    }
    return response.statusText;
  }

  Future<List<Item>?> _getConditionsWiseItems(int id, DataSourceEnum source) async {
    List<Item>? conditionWiseProduct;
    final String cacheId = '${AppConstants.conditionWiseItemUri}$id?limit=15&offset=1-${Get.find<SplashController>().module?.id ?? 0}';

    switch(source) {
      case DataSourceEnum.client:
        final Response response = await apiClient.getData('${AppConstants.conditionWiseItemUri}$id?limit=15&offset=1');
        if (response.statusCode == 200) {
          conditionWiseProduct = [];
          conditionWiseProduct.addAll(ItemModel.fromJson(response.body).items!);
          LocalClient.organize(DataSourceEnum.client, cacheId, response.bodyString ?? '', apiClient.getHeader());
        }

      case DataSourceEnum.local:
        final String? cacheResponseData = await LocalClient.organize(DataSourceEnum.local, cacheId, null, null);
        if(cacheResponseData != null) {
          conditionWiseProduct = [];
          conditionWiseProduct.addAll(ItemModel.fromJson(ResponseParser.payloadOf(jsonDecode(cacheResponseData))).items!);
        }
    }
    return conditionWiseProduct;
  }

  @override
  Future getList({int? offset, String? type, bool isPopularItem = false, bool isReviewedItem = false, bool isFeaturedCategoryItems = false, bool isRecommendedItems = false,
    bool isCommonConditions = false, bool isDiscountedItems = false, DataSourceEnum? source,
    String? search, List<int>? categoryIds, List<String>? filter, int? rating, double? minPrice, double? maxPrice,
  }) async {
    if(isPopularItem) {
      return await _getPopularItemList(type: type!, source: source ?? DataSourceEnum.client, offset: offset!, search: search, categoryIds: categoryIds, filter: filter, rating: rating, minPrice: minPrice, maxPrice: maxPrice);
    } else if(isReviewedItem) {
      return await _getReviewedItemList(type: type!, source: source ?? DataSourceEnum.client, offset: offset!, search: search, categoryIds: categoryIds, filter: filter, rating: rating, minPrice: minPrice, maxPrice: maxPrice);
    } else if(isFeaturedCategoryItems) {
      return await _getFeaturedCategoriesItemList(source: source ?? DataSourceEnum.client);
    } else if(isRecommendedItems) {
      return await _getRecommendedItemList(type!, source: source ?? DataSourceEnum.client);
    } else if(isCommonConditions) {
      return await _getCommonConditions(source ?? DataSourceEnum.client);
    } else if(isDiscountedItems) {
      return await _getDiscountedItemList(type: type!, source: source ?? DataSourceEnum.client, offset: offset!, search: search, categoryIds: categoryIds, filter: filter, rating: rating, minPrice: minPrice, maxPrice: maxPrice);
    }
  }

  Future<ItemModel?> _getPopularItemList({required String type, required DataSourceEnum source, required int offset, String? search, List<int>? categoryIds, List<String>? filter, int? rating, double? minPrice, double? maxPrice}) async {
    ItemModel? popularItemList;
    String cacheId = '${AppConstants.popularItemUri}?type=$type-${Get.find<SplashController>().module!.id!}';

    final filterString = filter != null ? jsonEncode(filter) : [];
    final categoryIdsString = categoryIds != null ? jsonEncode(categoryIds) : [];

    Map<String, dynamic>? query = {
      'type': type,
      'offset': offset.toString(),
      'limit': '25',
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryIds != null && categoryIds.isNotEmpty) 'category_ids': categoryIdsString,
      if (filter != null && filter.isNotEmpty) 'filter': filterString,
      if (rating != null) 'rating_count': rating.toString(),
      if (minPrice != null) 'min_price': minPrice.toString(),
      if (maxPrice != null) 'max_price': maxPrice.toString(),
    };

    String uri = Uri.parse(AppConstants.popularItemUri).replace(queryParameters: query).toString();

    switch(source) {

      case DataSourceEnum.client:
        Response response = await apiClient.getData(uri, moduleScoped: true);
        if (response.statusCode == 200) {
          popularItemList = ItemModel.fromJson(response.body);
          LocalClient.organize(DataSourceEnum.client, cacheId, response.bodyString ?? '', apiClient.getHeader());
        }
        break;

      case DataSourceEnum.local:
        String? cacheResponseData = await LocalClient.organize(DataSourceEnum.local, cacheId, null, null);
        if(cacheResponseData != null) {
          popularItemList = ItemModel.fromJson(ResponseParser.payloadOf(jsonDecode(cacheResponseData)));
        }
        break;
    }

    return popularItemList;
  }

  Future<ItemModel?> _getReviewedItemList({required String type, required DataSourceEnum source, required int offset, String? search, List<int>? categoryIds, List<String>? filter, int? rating, double? minPrice, double? maxPrice}) async {
    ItemModel? itemModel;
    String cacheId = '${AppConstants.reviewedItemUri}?type=$type${Get.find<SplashController>().module!.id!}';

    final filterString = filter != null ? jsonEncode(filter) : [];
    final categoryIdsString = categoryIds != null ? jsonEncode(categoryIds) : [];

    Map<String, dynamic>? query = {
      'type': type,
      'offset': offset.toString(),
      'limit': '25',
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryIds != null && categoryIds.isNotEmpty) 'category_ids': categoryIdsString,
      if (filter != null && filter.isNotEmpty) 'filter': filterString,
      if (rating != null) 'rating_count': rating.toString(),
      if (minPrice != null) 'min_price': minPrice.toString(),
      if (maxPrice != null) 'max_price': maxPrice.toString(),
    };

    String uri = Uri.parse(AppConstants.reviewedItemUri).replace(queryParameters: query).toString();

    switch(source) {

      case DataSourceEnum.client:
        Response response = await apiClient.getData(uri, moduleScoped: true);
        if(response.statusCode == 200) {
          itemModel = ItemModel.fromJson(response.body);
          LocalClient.organize(DataSourceEnum.client, cacheId, response.bodyString ?? '', apiClient.getHeader());
        }
        break;

      case DataSourceEnum.local:
        String? cacheResponseData = await LocalClient.organize(DataSourceEnum.local, cacheId, null, null);
        if(cacheResponseData != null) {
          itemModel = ItemModel.fromJson(ResponseParser.payloadOf(jsonDecode(cacheResponseData)));
        }
        break;
    }

    return itemModel;
  }

  Future<ItemModel?> _getDiscountedItemList({required String type, required DataSourceEnum source, required int offset, String? search, List<int>? categoryIds, List<String>? filter, int? rating, double? minPrice, double? maxPrice}) async {
    ItemModel? discountedItem;
    String cacheId = '${AppConstants.discountedItemsUri}?type=$type&offset=1&limit=50${Get.find<SplashController>().module!.id!}';

    final filterString = filter != null ? jsonEncode(filter) : [];
    final categoryIdsString = categoryIds != null ? jsonEncode(categoryIds) : [];

    Map<String, dynamic>? query = {
      'type': type,
      'offset': offset.toString(),
      'limit': '25',
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryIds != null && categoryIds.isNotEmpty) 'category_ids': categoryIdsString,
      if (filter != null && filter.isNotEmpty) 'filter': filterString,
      if (rating != null) 'rating_count': rating.toString(),
      if (minPrice != null) 'min_price': minPrice.toString(),
      if (maxPrice != null) 'max_price': maxPrice.toString(),
    };

    String uri = Uri.parse(AppConstants.discountedItemsUri).replace(queryParameters: query).toString();

    switch(source) {

      case DataSourceEnum.client:
        Response response = await apiClient.getData(uri, moduleScoped: true);
        if (response.statusCode == 200) {
          discountedItem = ItemModel.fromJson(response.body);
          LocalClient.organize(DataSourceEnum.client, cacheId, response.bodyString ?? '', apiClient.getHeader());
        }
        break;

      case DataSourceEnum.local:
        String? cacheResponseData = await LocalClient.organize(DataSourceEnum.local, cacheId, null, null);
        if(cacheResponseData != null) {
          discountedItem = ItemModel.fromJson(ResponseParser.payloadOf(jsonDecode(cacheResponseData)));
        }
        break;
    }

    return discountedItem;
  }

  Future<ItemModel?> _getFeaturedCategoriesItemList({required DataSourceEnum source}) async {
    ItemModel? featuredCategoriesItem;
    String cacheId = '${AppConstants.featuredCategoriesItemsUri}?limit=30&offset=1${Get.find<SplashController>().module!.id!}';

    switch(source) {

      case DataSourceEnum.client:
        Response response = await apiClient.getData('${AppConstants.featuredCategoriesItemsUri}?limit=30&offset=1', moduleScoped: true);
        if (response.statusCode == 200) {
          featuredCategoriesItem = ItemModel.fromJson(response.body);
          LocalClient.organize(DataSourceEnum.client, cacheId, response.bodyString ?? '', apiClient.getHeader());
        }

      case DataSourceEnum.local:
        String? cacheResponseData = await LocalClient.organize(DataSourceEnum.local, cacheId, null, null);
        if(cacheResponseData != null) {
          featuredCategoriesItem = ItemModel.fromJson(ResponseParser.payloadOf(jsonDecode(cacheResponseData)));
        }
    }

    return featuredCategoriesItem;
  }

  Future<List<Item>?> _getRecommendedItemList(String type, {required DataSourceEnum source}) async {
    List<Item>? recommendedItemList;
    String cacheId = '${AppConstants.recommendedItemsUri}$type&limit=30${Get.find<SplashController>().module!.id!}';

    switch(source) {

      case DataSourceEnum.client:
        Response response = await apiClient.getData('${AppConstants.recommendedItemsUri}$type&limit=30', moduleScoped: true);
        if (response.statusCode == 200) {
          recommendedItemList = [];
          recommendedItemList.addAll(ItemModel.fromJson(response.body).items!);
          LocalClient.organize(DataSourceEnum.client, cacheId, response.bodyString ?? '', apiClient.getHeader());
        }

      case DataSourceEnum.local:
        String? cacheResponseData = await LocalClient.organize(DataSourceEnum.local, cacheId, null, null);
        if(cacheResponseData != null) {
          recommendedItemList = [];
          recommendedItemList.addAll(ItemModel.fromJson(ResponseParser.payloadOf(jsonDecode(cacheResponseData))).items!);
        }
    }

    return recommendedItemList;
  }

  Future<List<CommonConditionModel>?> _getCommonConditions(DataSourceEnum source) async {
    List<CommonConditionModel>? commonConditions;
    final String cacheId = '${AppConstants.commonConditionUri}-${Get.find<SplashController>().module?.id ?? 0}';

    switch(source) {
      case DataSourceEnum.client:
        final Response response = await apiClient.getData(AppConstants.commonConditionUri);
        if (response.statusCode == 200) {
          final List<dynamic> conditionsJson = ResponseParser.listOrEmpty(response.body);
          commonConditions = [];
          for (final dynamic condition in conditionsJson) {
            commonConditions.add(CommonConditionModel.fromJson(condition));
          }
          // Cache the extracted list, not the raw body, so the local branch below
          // decodes the same shape whichever response format the client branch saw.
          LocalClient.organize(DataSourceEnum.client, cacheId, jsonEncode(conditionsJson), apiClient.getHeader());
        }

      case DataSourceEnum.local:
        final String? cacheResponseData = await LocalClient.organize(DataSourceEnum.local, cacheId, null, null);
        if(cacheResponseData != null) {
          commonConditions = [];
          for(final dynamic condition in ResponseParser.listOrEmpty(jsonDecode(cacheResponseData))) {
            commonConditions.add(CommonConditionModel.fromJson(condition));
          }
        }
    }
    return commonConditions;
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future<ItemReviewModel?> getItemReviews({required int itemId, required int limit, required int offset}) async {
    ItemReviewModel? itemReviewModel;
    String uri = Uri.parse('${AppConstants.getReviewListUri}/$itemId')
        .replace(
      queryParameters: {
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    )
        .toString();
    Response response = await apiClient.getData(uri);
    if (response.statusCode == 200) {
      itemReviewModel = ItemReviewModel.fromJson(response.body);
    }
    return itemReviewModel;
  }

}