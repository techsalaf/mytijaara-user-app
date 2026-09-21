class CustomerInformationBody {
  final String? name;
  final String? phone;
  final String? address;
  final String? road;
  final String? house;
  final String? floor;
  // Coordinates of the picked address — echoed back by the detail endpoint so
  // the bid checkout can pre-select this address as a placeable service location.
  final String? latitude;
  final String? longitude;

  const CustomerInformationBody({this.name, this.phone, this.address, this.road, this.house,
    this.floor, this.latitude, this.longitude,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'address': address,
    if (road != null && road!.isNotEmpty) 'road': road,
    if (house != null && house!.isNotEmpty) 'house': house,
    if (floor != null && floor!.isNotEmpty) 'floor': floor,
    if (latitude != null && latitude!.isNotEmpty) 'latitude': latitude,
    if (longitude != null && longitude!.isNotEmpty) 'longitude': longitude,
  };
}

class CustomServiceRequestBody {
  final int categoryId;
  final int? subCategoryId;
  final String? description;
  final CustomerInformationBody? customerInformation;
  final String? bookingDate;
  final String? bookingTime;

  const CustomServiceRequestBody({
    required this.categoryId, this.subCategoryId, this.description,
    this.customerInformation, this.bookingDate, this.bookingTime,
  });

  Map<String, dynamic> toJson() => {
    'category_id': categoryId,
    if (subCategoryId != null) 'sub_category_id': subCategoryId,
    if (description != null && description!.isNotEmpty) 'description': description,
    if (customerInformation != null) 'customer_information': customerInformation!.toJson(),
    if (bookingDate != null) 'booking_date': bookingDate,
    if (bookingTime != null) 'booking_time': bookingTime,
  };
}
