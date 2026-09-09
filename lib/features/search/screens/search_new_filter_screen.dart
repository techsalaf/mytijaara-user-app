import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/features/search/domain/models/search_new_filter_state.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/gaps.dart';
import 'package:sixam_mart/util/styles.dart';

class SearchNewFilterScreen extends StatefulWidget {
  final SearchNewFilterState initialFilter;
  // When provided (e.g. from the live search), replaces the hardcoded category
  // list with real categories. Null keeps the default mock list (global-search).
  final List<String>? dynamicCategories;
  // The Type (veg/non-veg/halal) section only applies to the food module.
  final bool isFood;

  const SearchNewFilterScreen({super.key, required this.initialFilter, this.dynamicCategories, this.isFood = true});

  @override
  State<SearchNewFilterScreen> createState() => _SearchNewFilterScreenState();
}

class _SearchNewFilterScreenState extends State<SearchNewFilterScreen> {
  static const List<String> _types = <String>['Halal', 'Veg', 'Non - Veg'];
  static const List<int> _ratings = <int>[5, 4, 3, 2];

  late SearchNewFilterState _draftFilter;
  late TextEditingController _minController;
  late TextEditingController _maxController;

  bool _showAllCategories = false;
  bool _isPriceExpanded = true;
  bool _isTypeExpanded = true;
  bool _isRatingsExpanded = true;
  bool _isCategoriesExpanded = true;

  @override
  void initState() {
    super.initState();
    _draftFilter = widget.initialFilter;
    _minController = TextEditingController(text: _formatCurrency(_draftFilter.minPrice));
    _maxController = TextEditingController(text: _formatCurrency(_draftFilter.maxPrice));
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _resetFilter() {
    setState(() {
      _draftFilter = SearchNewFilterState.initial();
      _minController.text = _formatCurrency(_draftFilter.minPrice);
      _maxController.text = _formatCurrency(_draftFilter.maxPrice);
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      Get.back<SearchNewFilterState>(result: _draftFilter);
    });
  }

  void _updatePriceRange(RangeValues values) {
    setState(() {
      _draftFilter = _draftFilter.copyWith(minPrice: values.start, maxPrice: values.end);
      _minController.text = _formatCurrency(values.start);
      _maxController.text = _formatCurrency(values.end);
    });
  }

  void _updatePriceFromText({required bool isMin, required String rawValue}) {
    final double? parsed = double.tryParse(rawValue.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (parsed == null) {
      return;
    }
    final double minValue = isMin ? parsed.clamp(0, _draftFilter.maxPrice) : _draftFilter.minPrice;
    final double maxValue = isMin ? _draftFilter.maxPrice : parsed.clamp(_draftFilter.minPrice, 1000);
    setState(() {
      _draftFilter = _draftFilter.copyWith(minPrice: minValue, maxPrice: maxValue);
    });
  }

  void _toggleStringSelection(Set<String> currentValues, String value, void Function(Set<String>) onChanged) {
    final Set<String> nextValues = <String>{...currentValues};
    if (nextValues.contains(value)) {
      nextValues.remove(value);
    } else {
      nextValues.add(value);
    }
    onChanged(nextValues);
  }

  void _toggleIntSelection(Set<int> currentValues, int value, void Function(Set<int>) onChanged) {
    final Set<int> nextValues = <int>{...currentValues};
    if (nextValues.contains(value)) {
      nextValues.remove(value);
    } else {
      nextValues.add(value);
    }
    onChanged(nextValues);
  }

  @override
  Widget build(BuildContext context) {
    final List<String> categoryOptions = widget.dynamicCategories ?? [];
    final List<String> visibleCategories = _showAllCategories ? categoryOptions : categoryOptions.take(5).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      body: SafeArea(
        child: Column(
          children: <Widget>[

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeDefault),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text('filter_data'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
                  ),
                  GestureDetector(
                    onTap: Get.back,
                    child: Container(
                      height: 34,
                      width: 34,
                      decoration: BoxDecoration(
                        color: Theme.of(context).disabledColor.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, size: 18, color: Theme.of(context).disabledColor),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Theme.of(context).disabledColor.withValues(alpha: 0.18)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                children: <Widget>[
                  _FilterSection(
                    title: 'price_range'.tr,
                    isExpanded: _isPriceExpanded,
                    onTap: () => setState(() => _isPriceExpanded = !_isPriceExpanded),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _PriceInput(
                                label: 'min'.tr,
                                controller: _minController,
                                onChanged: (String value) => _updatePriceFromText(isMin: true, rawValue: value),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Padding(
                              padding: const EdgeInsets.only(top: 28),
                              child: Text('-', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _PriceInput(
                                label: 'max'.tr,
                                controller: _maxController,
                                onChanged: (String value) => _updatePriceFromText(isMin: false, rawValue: value),
                              ),
                            ),
                          ],
                        ),
                        RangeSlider(
                          values: RangeValues(_draftFilter.minPrice, _draftFilter.maxPrice),
                          min: 0,
                          max: 1000,
                          divisions: 20,
                          activeColor: const Color(0xFF14A850),
                          onChanged: _updatePriceRange,
                        ),
                        Row(
                          children: <Widget>[
                            Text(_formatCurrency(_draftFilter.minPrice), style: robotoMedium.copyWith(color: const Color(0xFF14A850))),
                            const Spacer(),
                            Text(_formatCurrency(_draftFilter.maxPrice), style: robotoMedium.copyWith(color: const Color(0xFF14A850))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (widget.isFood) _FilterSection(
                    title: 'type'.tr,
                    isExpanded: _isTypeExpanded,
                    onTap: () => setState(() => _isTypeExpanded = !_isTypeExpanded),
                    child: Column(
                      children: _types.map((String value) {
                        final bool isSelected = _draftFilter.types.contains(value);
                        return _CheckItemRow(
                          label: _typeLabel(value),
                          isSelected: isSelected,
                          useRadio: true,
                          // Type is single-select — picking one replaces any prior choice.
                          onTap: () => setState(() {
                            _draftFilter = _draftFilter.copyWith(
                              types: isSelected ? <String>{} : <String>{value},
                            );
                          }),
                        );
                      }).toList(),
                    ),
                  ),
                  _FilterSection(
                    title: 'ratings'.tr,
                    isExpanded: _isRatingsExpanded,
                    onTap: () => setState(() => _isRatingsExpanded = !_isRatingsExpanded),
                    child: Column(
                      children: _ratings.map((int value) {
                        final String label = value == 5 ? '${'only_rate'.tr} 5' : '$value+ ${'rating'.tr}';
                        return _CheckItemRow(
                          label: label,
                          leading: const Icon(Icons.star, size: 14, color: Color(0xFFF0B322)),
                          isSelected: _draftFilter.ratings.contains(value),
                          onTap: () => setState(() {
                            _toggleIntSelection(_draftFilter.ratings, value, (Set<int> nextValues) {
                              _draftFilter = _draftFilter.copyWith(ratings: nextValues);
                            });
                          }),
                        );
                      }).toList(),
                    ),
                  ),
                  _FilterSection(
                    title: 'categories'.tr,
                    isExpanded: _isCategoriesExpanded,
                    onTap: () => setState(() => _isCategoriesExpanded = !_isCategoriesExpanded),
                    child: Column(
                      children: <Widget>[
                        ...visibleCategories.map((String value) {
                          return _CheckItemRow(
                            label: value,
                            isSelected: _draftFilter.categories.contains(value),
                            onTap: () => setState(() {
                              _toggleStringSelection(_draftFilter.categories, value, (Set<String> nextValues) {
                                _draftFilter = _draftFilter.copyWith(categories: nextValues);
                              });
                            }),
                          );
                        }),
                        GestureDetector(
                          onTap: () => setState(() => _showAllCategories = !_showAllCategories),
                          child: Padding(
                            padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                            child: Text(
                              _showAllCategories ? 'show_less'.tr : 'see_more'.tr,
                              style: robotoMedium.copyWith(color: const Color(0xFF4C88FF)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Theme.of(context).disabledColor.withValues(alpha: 0.18)),

          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingSizeLarge,
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeLarge,
            Dimensions.paddingSizeLarge,
          ),
          child: SizedBox(
            height: 50,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: CustomButton(
                    onPressed: _resetFilter,
                    buttonText: 'reset'.tr,
                    color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
                    textColor: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                Gaps.horizontalGapOf(Dimensions.paddingSizeLarge),
                Expanded(
                  child: CustomButton(
                    onPressed: () => Get.back<SearchNewFilterState>(result: _draftFilter),
                    buttonText: 'apply'.tr,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final bool isExpanded;
  final VoidCallback onTap;
  final Widget child;

  const _FilterSection({
    required this.title,
    required this.isExpanded,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).disabledColor.withValues(alpha: 0.18)),
        ),
      ),
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: onTap,
            child: Row(
              children: <Widget>[
                Expanded(child: Text(title, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge))),
                Container(
                  height: 28,
                  width: 28,
                  decoration: BoxDecoration(
                    color: Theme.of(context).disabledColor.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 18,
                    color: Theme.of(context).disabledColor,
                  ),
                ),
              ],
            ),
          ),
          if (isExpanded) ...<Widget>[
            Gaps.verticalGapOf(Dimensions.paddingSizeLarge),
            child,
          ],
        ],
      ),
    );
  }
}

class _PriceInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _PriceInput({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: robotoRegular.copyWith(color: Theme.of(context).disabledColor)),
        Gaps.verticalGapOf(Dimensions.paddingSizeSmall),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: onChanged,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Theme.of(context).disabledColor.withValues(alpha: 0.25)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Theme.of(context).disabledColor.withValues(alpha: 0.25)),
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckItemRow extends StatelessWidget {
  final String label;
  final Widget? leading;
  final bool isSelected;
  final bool useRadio;
  final VoidCallback onTap;

  const _CheckItemRow({
    required this.label,
    this.leading,
    required this.isSelected,
    this.useRadio = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: <Widget>[
            if (leading != null) ...<Widget>[
              leading!,
              Gaps.horizontalGapOf(6),
            ],
            Expanded(
              child: Text(
                label,
                style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            useRadio ? _RadioIndicator(isSelected: isSelected) : _CheckboxIndicator(isSelected: isSelected),
          ],
        ),
      ),
    );
  }
}

class _RadioIndicator extends StatelessWidget {
  final bool isSelected;
  const _RadioIndicator({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      width: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? const Color(0xFF14A850) : Theme.of(context).disabledColor.withValues(alpha: 0.45),
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                height: 10,
                width: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF14A850),
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}

class _CheckboxIndicator extends StatelessWidget {
  final bool isSelected;
  const _CheckboxIndicator({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      width: 26,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF14A850) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected ? const Color(0xFF14A850) : Theme.of(context).disabledColor.withValues(alpha: 0.45),
        ),
      ),
      child: isSelected ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
    );
  }
}

String _formatCurrency(double value) {
  return '\$${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2)}';
}

// Translated label for a type value (the stored value stays English for the API).
String _typeLabel(String value) {
  switch (value) {
    case 'Halal':
      return 'halal'.tr;
    case 'Veg':
      return 'veg'.tr;
    case 'Non - Veg':
      return 'non_veg'.tr;
    default:
      return value;
  }
}
