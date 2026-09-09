class AdvertisementModel {
  int? id;
  int? storeId;
  String? addType;
  String? title;
  String? description;
  String? startDate;
  String? endDate;
  String? pauseNote;
  String? coverImage;
  String? profileImage;
  String? videoAttachment;
  int? isRatingActive;
  int? isReviewActive;
  int? isPaid;
  int? createdById;
  String? createdByType;
  String? status;
  String? createdAt;
  String? updatedAt;
  int? isUpdated;
  String? cancellationNote;
  String? coverImageFullUrl;
  String? profileImageFullUrl;
  String? videoAttachmentFullUrl;
  double? averageRating;
  int? reviewsCommentsCount;
  StoreDetails? store;

  AdvertisementModel({
    this.id,
    this.storeId,
    this.addType,
    this.title,
    this.description,
    this.startDate,
    this.endDate,
    this.pauseNote,
    this.coverImage,
    this.profileImage,
    this.videoAttachment,
    this.isRatingActive,
    this.isReviewActive,
    this.isPaid,
    this.createdById,
    this.createdByType,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.isUpdated,
    this.cancellationNote,
    this.coverImageFullUrl,
    this.profileImageFullUrl,
    this.videoAttachmentFullUrl,
    this.averageRating,
    this.reviewsCommentsCount,
    this.store,
  });

  AdvertisementModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    storeId = json['store_id'];
    addType = json['add_type'];
    title = json['title'];
    description = json['description'];
    startDate = json['start_date'];
    endDate = json['end_date'];
    pauseNote = json['pause_note'];
    coverImage = json['cover_image'];
    profileImage = json['profile_image'];
    videoAttachment = json['video_attachment'];
    //priority = json['priority'];
    isRatingActive = json['is_rating_active'];
    isReviewActive = json['is_review_active'];
    isPaid = json['is_paid'];
    createdById = json['created_by_id'];
    createdByType = json['created_by_type'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    isUpdated = json['is_updated'];
    cancellationNote = json['cancellation_note'];
    coverImageFullUrl = json['cover_image_full_url'];
    profileImageFullUrl = json['profile_image_full_url'];
    videoAttachmentFullUrl = json['video_attachment_full_url'];
    averageRating = json['average_rating']?.toDouble();
    reviewsCommentsCount = json['reviews_comments_count'];
    store = json['store'] != null ? StoreDetails.fromJson(json['store']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['store_id'] = storeId;
    data['add_type'] = addType;
    data['title'] = title;
    data['description'] = description;
    data['start_date'] = startDate;
    data['end_date'] = endDate;
    data['pause_note'] = pauseNote;
    data['cover_image'] = coverImage;
    data['profile_image'] = profileImage;
    data['video_attachment'] = videoAttachment;
    //data['priority'] = priority;
    data['is_rating_active'] = isRatingActive;
    data['is_review_active'] = isReviewActive;
    data['is_paid'] = isPaid;
    data['created_by_id'] = createdById;
    data['created_by_type'] = createdByType;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['is_updated'] = isUpdated;
    data['cancellation_note'] = cancellationNote;
    data['cover_image_full_url'] = coverImageFullUrl;
    data['profile_image_full_url'] = profileImageFullUrl;
    data['video_attachment_full_url'] = videoAttachmentFullUrl;
    data['average_rating'] = averageRating;
    data['reviews_comments_count'] = reviewsCommentsCount;
    if (store != null) {
      data['store'] = store!.toJson();
    }
    return data;
  }
}

class StoreDetails {
  int? id;
  String? name;
  String? slug;
  String? logoFullUrl;
  String? coverPhotoFullUrl;
  int? moduleId;
  String? moduleType;
  List<TopItems>? topItems;

  StoreDetails(
      {this.id,
        this.name,
        this.slug,
        this.logoFullUrl,
        this.coverPhotoFullUrl,
        this.moduleId,
        this.moduleType,
        this.topItems});

  StoreDetails.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    slug = json['slug'];
    logoFullUrl = json['logo_full_url'];
    coverPhotoFullUrl = json['cover_photo_full_url'];
    moduleId = json['module_id'];
    moduleType = json['module_type'];
    if (json['top_items'] != null) {
      topItems = <TopItems>[];
      json['top_items'].forEach((v) {
        topItems!.add(new TopItems.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['slug'] = this.slug;
    data['logo_full_url'] = this.logoFullUrl;
    data['cover_photo_full_url'] = this.coverPhotoFullUrl;
    data['module_id'] = this.moduleId;
    data['module_type'] = this.moduleType;
    if (this.topItems != null) {
      data['top_items'] = this.topItems!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class TopItems {
  int? id;
  String? name;
  String? imageFullUrl;
  double? price;
  double? discount;
  String? discountType;
  int? orderCount;
  double? avgRating;

  TopItems(
      {this.id,
        this.name,
        this.imageFullUrl,
        this.price,
        this.discount,
        this.discountType,
        this.orderCount,
        this.avgRating});

  TopItems.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    imageFullUrl = json['image_full_url'];
    price = json['price']?.toDouble();
    discount = json['discount']?.toDouble();
    discountType = json['discount_type'];
    orderCount = json['order_count'];
    avgRating = json['avg_rating']?.toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['image_full_url'] = imageFullUrl;
    data['price'] = price;
    data['discount'] = discount;
    data['discount_type'] = discountType;
    data['order_count'] = orderCount;
    data['avg_rating'] = avgRating;
    return data;
  }
}