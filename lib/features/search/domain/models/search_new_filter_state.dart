class SearchNewFilterState {
  final double minPrice;
  final double maxPrice;
  final Set<String> types;
  final Set<int> ratings;
  final Set<String> deliveryTimes;
  final Set<String> categories;
  final Set<String> cuisines;
  final Set<String> offers;
  final SearchNewSortOption sortOption;

  const SearchNewFilterState({
    required this.minPrice,
    required this.maxPrice,
    required this.types,
    required this.ratings,
    required this.deliveryTimes,
    required this.categories,
    required this.cuisines,
    required this.offers,
    required this.sortOption,
  });

  factory SearchNewFilterState.initial() {
    return const SearchNewFilterState(
      minPrice: 0,
      maxPrice: 1000,
      types: <String>{},
      ratings: <int>{},
      deliveryTimes: <String>{},
      categories: <String>{},
      cuisines: <String>{},
      offers: <String>{},
      sortOption: SearchNewSortOption.recommended,
    );
  }

  SearchNewFilterState copyWith({
    double? minPrice,
    double? maxPrice,
    Set<String>? types,
    Set<int>? ratings,
    Set<String>? deliveryTimes,
    Set<String>? categories,
    Set<String>? cuisines,
    Set<String>? offers,
    SearchNewSortOption? sortOption,
  }) {
    return SearchNewFilterState(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      types: types ?? this.types,
      ratings: ratings ?? this.ratings,
      deliveryTimes: deliveryTimes ?? this.deliveryTimes,
      categories: categories ?? this.categories,
      cuisines: cuisines ?? this.cuisines,
      offers: offers ?? this.offers,
      sortOption: sortOption ?? this.sortOption,
    );
  }

  bool get hasActiveFilters {
    final SearchNewFilterState initialState = SearchNewFilterState.initial();
    return minPrice != initialState.minPrice
        || maxPrice != initialState.maxPrice
        || types.isNotEmpty
        || ratings.isNotEmpty
        || deliveryTimes.isNotEmpty
        || categories.isNotEmpty
        || cuisines.isNotEmpty
        || offers.isNotEmpty
        || sortOption != initialState.sortOption;
  }
}

enum SearchNewSortOption {
  recommended,
  priceLowToHigh,
  priceHighToLow,
  ratingHighToLow,
  fastestDelivery,
}
