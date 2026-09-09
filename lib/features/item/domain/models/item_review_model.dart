class ItemReviewModel {
  RatingSummary? ratingSummary;
  int? totalSize;
  String? limit;
  String? offset;
  List<ItemReview>? reviews;

  ItemReviewModel({
    this.ratingSummary,
    this.totalSize,
    this.limit,
    this.offset,
    this.reviews,
  });

  ItemReviewModel.fromJson(Map<String, dynamic> json) {
    ratingSummary = json['rating_summary'] != null
        ? RatingSummary.fromJson(json['rating_summary'])
        : null;
    totalSize = json['total_size'];
    limit = json['limit']?.toString();
    offset = json['offset']?.toString();
    if (json['reviews'] != null) {
      reviews = [];
      json['reviews'].forEach((v) {
        reviews!.add(ItemReview.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (ratingSummary != null) {
      data['rating_summary'] = ratingSummary!.toJson();
    }
    data['total_size'] = totalSize;
    data['limit'] = limit;
    data['offset'] = offset;
    if (reviews != null) {
      data['reviews'] = reviews!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class RatingSummary {
  double? avgRating;
  int? totalReviews;
  List<RatingBreakdown>? breakdown;

  RatingSummary({this.avgRating, this.totalReviews, this.breakdown});

  RatingSummary.fromJson(Map<String, dynamic> json) {
    avgRating = json['avg_rating']?.toDouble();
    totalReviews = json['total_reviews'];
    if (json['breakdown'] != null) {
      breakdown = [];
      json['breakdown'].forEach((v) {
        breakdown!.add(RatingBreakdown.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['avg_rating'] = avgRating;
    data['total_reviews'] = totalReviews;
    if (breakdown != null) {
      data['breakdown'] = breakdown!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class RatingBreakdown {
  String? label;
  int? star;
  int? count;

  RatingBreakdown({this.label, this.star, this.count});

  RatingBreakdown.fromJson(Map<String, dynamic> json) {
    label = json['label'];
    star = json['star'];
    count = json['count'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['label'] = label;
    data['star'] = star;
    data['count'] = count;
    return data;
  }
}

class ItemReview {
  int? id;
  int? itemId;
  int? userId;
  String? comment;
  List<String>? attachment;
  int? rating;
  int? orderId;
  String? createdAt;
  String? updatedAt;
  int? itemCampaignId;
  int? status;
  int? moduleId;
  int? storeId;
  String? reply;
  String? reviewId;
  String? repliedAt;
  String? itemName;
  ReviewCustomer? customer;

  ItemReview({
    this.id,
    this.itemId,
    this.userId,
    this.comment,
    this.attachment,
    this.rating,
    this.orderId,
    this.createdAt,
    this.updatedAt,
    this.itemCampaignId,
    this.status,
    this.moduleId,
    this.storeId,
    this.reply,
    this.reviewId,
    this.repliedAt,
    this.itemName,
    this.customer,
  });

  ItemReview.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    itemId = json['item_id'];
    userId = json['user_id'];
    comment = json['comment'];
    if (json['attachment'] != null) {
      attachment = [];
      json['attachment'].forEach((v) {
        attachment!.add(v.toString());
      });
    }
    rating = json['rating'];
    orderId = json['order_id'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    itemCampaignId = json['item_campaign_id'];
    status = json['status'];
    moduleId = json['module_id'];
    storeId = json['store_id'];
    reply = json['reply'];
    reviewId = json['review_id']?.toString();
    repliedAt = json['replied_at'];
    itemName = json['item_name'];
    customer = json['customer'] != null
        ? ReviewCustomer.fromJson(json['customer'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['item_id'] = itemId;
    data['user_id'] = userId;
    data['comment'] = comment;
    data['attachment'] = attachment;
    data['rating'] = rating;
    data['order_id'] = orderId;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['item_campaign_id'] = itemCampaignId;
    data['status'] = status;
    data['module_id'] = moduleId;
    data['store_id'] = storeId;
    data['reply'] = reply;
    data['review_id'] = reviewId;
    data['replied_at'] = repliedAt;
    data['item_name'] = itemName;
    if (customer != null) {
      data['customer'] = customer!.toJson();
    }
    return data;
  }
}

class ReviewCustomer {
  int? id;
  String? firstName;
  String? lastName;
  String? phone;
  String? email;
  String? image;
  String? imageFullUrl;

  ReviewCustomer({
    this.id,
    this.firstName,
    this.lastName,
    this.phone,
    this.email,
    this.image,
    this.imageFullUrl,
  });

  ReviewCustomer.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    firstName = json['f_name'];
    lastName = json['l_name'];
    phone = json['phone'];
    email = json['email'];
    image = json['image'];
    imageFullUrl = json['image_full_url'];
  }

  String get fullName {
    final String name = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    return name;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['f_name'] = firstName;
    data['l_name'] = lastName;
    data['phone'] = phone;
    data['email'] = email;
    data['image'] = image;
    data['image_full_url'] = imageFullUrl;
    return data;
  }
}
