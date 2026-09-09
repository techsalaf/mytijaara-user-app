import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_loader.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/address/controllers/address_controller.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/location/domain/models/prediction_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/features/location/screens/pick_map_screen.dart';
import 'package:sixam_mart/features/parcel/controllers/parcel_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

enum PickLocationMode { parcelSender, parcelReceiver, checkout }

class PickLocationScreen extends StatefulWidget {
  final PickLocationMode mode;
  final Future<void> Function(AddressModel address)? onAddressPicked;
  // Pre-fills the search field (e.g. the address already selected in the
  // checkout delivery-address section) instead of the current location.
  final String? initialSearchText;

  const PickLocationScreen({super.key,
    required this.mode, this.onAddressPicked, this.initialSearchText,
  }) : assert(mode != PickLocationMode.checkout || onAddressPicked != null,
       'onAddressPicked is required for checkout mode');

  @override
  State<PickLocationScreen> createState() => _PickLocationScreenState();
}

class _PickLocationScreenState extends State<PickLocationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  AddressModel? _appCurrentAddress;
  String? _selectedAddress;
  List<PredictionModel> _suggestions = [];
  bool _isSearching = false;
  bool _loadingSuggestions = false;
  bool _hasQueried = false;
  int _selectedTabIndex = 0;

  bool get _isParcelMode => widget.mode == PickLocationMode.parcelSender || widget.mode == PickLocationMode.parcelReceiver;
  bool get _showCurrentLocation => widget.mode != PickLocationMode.parcelReceiver;

  @override
  void initState() {
    super.initState();
    _appCurrentAddress = AddressHelper.getUserAddressFromSharedPref();

    final parcelController = Get.find<ParcelController>();
    parcelController.loadParcelRecentAddresses();
    Get.find<LocationController>().loadRecentAddresses();

    if (_isParcelMode) {
      final existing = widget.mode == PickLocationMode.parcelSender
          ? parcelController.pickupAddress
          : parcelController.destinationAddress;
      _selectedAddress = existing?.address;
      _searchController.text = existing?.address ?? '';
    } else {
      // Pre-fill the search field with the address already selected in the
      // delivery-address section; fall back to the current bound address.
      _selectedAddress = widget.initialSearchText ?? _appCurrentAddress?.address;
      _searchController.text = _selectedAddress ?? '';
    }

    if (AuthHelper.isLoggedIn() && Get.find<AddressController>().addressList == null) {
      Get.find<AddressController>().getAddressList();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<AddressModel> _recentList() {
    // Parcel flow keeps its own recent store; the regular checkout/location flow
    // uses delivery addresses cached on order placement.
    return _isParcelMode
        ? Get.find<ParcelController>().parcelRecentAddresses
        : Get.find<LocationController>().recentAddresses;
  }

  List<AddressModel> _savedList() {
    return Get.find<AddressController>().addressList ?? <AddressModel>[];
  }

  /// Tab labels. Saved tab only appears when user is logged in.
  /// If recent is empty (and user is logged in), saved comes first.
  List<String> _orderedTabs() {
    if (!AuthHelper.isLoggedIn()) {
      return <String>['recent'.tr];
    }
    final bool recentEmpty = _recentList().isEmpty;
    return recentEmpty
        ? <String>['saved'.tr, 'recent'.tr]
        : <String>['recent'.tr, 'saved'.tr];
  }

  List<AddressModel> _activeList() {
    final tabs = _orderedTabs();
    final int safeIndex = _selectedTabIndex.clamp(0, tabs.length - 1);
    final activeLabel = tabs[safeIndex];
    return activeLabel == 'recent'.tr ? _recentList() : _savedList();
  }

  Future<void> _onSearchChanged(String value) async {
    if (value.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _suggestions = [];
        _loadingSuggestions = false;
        _hasQueried = false;
      });
      return;
    }
    setState(() {
      _isSearching = true;
      _loadingSuggestions = true;
      _hasQueried = true;
    });
    final results = await Get.find<LocationController>().searchLocation(context, value);
    if (!mounted) return;
    setState(() {
      _suggestions = results;
      _loadingSuggestions = false;
    });
  }

  void _clearSearch() {
    if (_searchController.text.trim().isEmpty) {
      _searchFocusNode.unfocus();
      setState(() {
        _isSearching = false;
        _hasQueried = false;
      });
      return;
    }
    _searchController.clear();
    _searchFocusNode.requestFocus();
    setState(() {
      _isSearching = false;
      _suggestions = [];
      _hasQueried = false;
    });
  }

  Future<void> _onSuggestionSelected(PredictionModel suggestion) async {
    Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
    final AddressModel address = await Get.find<LocationController>().setLocation(
      suggestion.placeId,
      suggestion.description,
      null,
    );
    Get.back();
    if (!mounted) return;
    _searchFocusNode.unfocus();
    setState(() {
      _isSearching = false;
      _suggestions = [];
      _hasQueried = false;
      _searchController.text = address.address ?? '';
    });

    final double? lat = double.tryParse(address.latitude ?? '');
    final double? lng = double.tryParse(address.longitude ?? '');
    if (lat == null || lng == null) {
      await _commitAndPop(address);
      return;
    }
    _openMapPicker(initialPosition: LatLng(lat, lng), initialAddress: address.address);
  }

  Future<void> _useCurrentLocation() async {
    Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
    final AddressModel address = await Get.find<LocationController>().getCurrentLocation(true);
    Get.back();
    if (!mounted) return;
    _searchFocusNode.unfocus();
    setState(() {
      _isSearching = false;
    });
    await _commitAndPop(address);
  }

  Future<void> _openMapPicker({LatLng? initialPosition, String? initialAddress}) async {
    AddressModel? pendingAddress;
    final pickMapScreen = PickMapScreen(
      fromSignUp: false, fromAddAddress: false, canRoute: false, route: '', onPicked: (AddressModel address) {
        pendingAddress = address;
      },
      initialPosition: initialPosition, initialAddress: initialAddress,
    );

    if (ResponsiveHelper.isDesktop(context)) {
      await showGeneralDialog(
        context: context,
        pageBuilder: (ctx, anim1, anim2) => SizedBox(height: 300, width: 300, child: pickMapScreen),
      );
    } else {
      await Get.toNamed(RouteHelper.getPickMapRoute('parcel', false), arguments: pickMapScreen);
    }

    if (!mounted) return;
    if (pendingAddress != null) {
      await _commitAndPop(pendingAddress!);
    }
  }

  Future<void> _commitAndPop(AddressModel address) async {
    final lat = address.latitude;
    final lng = address.longitude;
    if (lat == null || lng == null) {
      showCustomSnackBar('please_select_address'.tr);
      return;
    }

    Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
    final ZoneResponseModel responseModel = await Get.find<LocationController>().getZone(
      lat.toString(), lng.toString(), false,
    );
    Get.back();

    if (!responseModel.isSuccess) {
      showCustomSnackBar('service_not_available_in_this_location'.tr);
      return;
    }

    final AddressModel resolved = AddressModel(
      id: address.id,
      addressType: address.addressType,
      contactPersonNumber: address.contactPersonNumber,
      contactPersonName: address.contactPersonName,
      address: address.address,
      latitude: address.latitude,
      longitude: address.longitude,
      zoneId: responseModel.zoneIds.isNotEmpty ? responseModel.zoneIds[0] : 0,
      zoneIds: responseModel.zoneIds,
      method: address.method,
      streetNumber: address.streetNumber,
      house: address.house,
      floor: address.floor,
      zoneData: responseModel.zoneData,
    );

    switch (widget.mode) {
      case PickLocationMode.parcelSender:
        Get.find<ParcelController>().setPickupAddress(resolved, true);
        break;
      case PickLocationMode.parcelReceiver:
        Get.find<ParcelController>().setDestinationAddress(resolved);
        break;
      case PickLocationMode.checkout:
        await widget.onAddressPicked!(resolved);
        break;
    }

    if (!mounted) return;
    Get.back();
  }

  String _resolveTitle() {
    switch (widget.mode) {
      case PickLocationMode.parcelSender:
        return 'set_sender_location'.tr;
      case PickLocationMode.parcelReceiver:
        return 'set_receiver_location'.tr;
      case PickLocationMode.checkout:
        return 'set_delivery_location'.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CustomAppBar(title: _resolveTitle()),
      body: SafeArea(
        child: GetBuilder<ParcelController>(builder: (parcelController) {
          return Column(children: [

            _SearchBar(
              controller: _searchController, focusNode: _searchFocusNode, onChanged: _onSearchChanged, onClear: _clearSearch,
              onTap: () {
                if (_hasQueried) {
                  setState(() => _isSearching = true);
                }
              },
            ),

            Expanded(
              child: _isSearching
                  ? _SuggestionsCard(
                      suggestions: _suggestions,
                      loading: _loadingSuggestions,
                      onSelected: _onSuggestionSelected,
                    )
                  : _IdleContent(
                      appCurrentAddress: _appCurrentAddress,
                      showCurrentLocation: _showCurrentLocation,
                      isCurrentSelected: _appCurrentAddress?.address != null && _selectedAddress != null && _appCurrentAddress!.address!.trim() == _selectedAddress!.trim(),
                      onMapTap: _openMapPicker,
                      onCurrentTap: () {
                        if (_appCurrentAddress != null) {
                          _commitAndPop(_appCurrentAddress!);
                        }
                      },
                      tabs: _orderedTabs(),
                      selectedTab: _selectedTabIndex.clamp(0, _orderedTabs().length - 1),
                      onTabChanged: (i) => setState(() => _selectedTabIndex = i),
                      addressList: _activeList(),
                      onAddressTap: _commitAndPop,
                    ),
            ),

            if (_isSearching)
              _SearchModeBottomBar(
                showCurrentLocation: _showCurrentLocation,
                onMapTap: _openMapPicker,
                onCurrentTap: _useCurrentLocation,
              ),
          ]);
        }),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onTap;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
        child: Row(children: [
          Icon(CupertinoIcons.placemark, size: 20, color: Theme.of(context).disabledColor),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              onTap: onTap,
              textInputAction: TextInputAction.search,
              textCapitalization: TextCapitalization.words,
              keyboardType: TextInputType.streetAddress,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
              decoration: InputDecoration(
                hintText: 'search_location'.tr,
                hintStyle: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Theme.of(context).hintColor,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          GestureDetector(
            onTap: onClear,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: Icon(Icons.close, size: 18, color: Theme.of(context).disabledColor),
            ),
          ),
        ]),
      ),
    );
  }
}

class _IdleContent extends StatelessWidget {
  final AddressModel? appCurrentAddress;
  final bool showCurrentLocation;
  final bool isCurrentSelected;
  final VoidCallback onMapTap;
  final VoidCallback onCurrentTap;
  final List<String> tabs;
  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  final List<AddressModel> addressList;
  final ValueChanged<AddressModel> onAddressTap;

  const _IdleContent({
    required this.appCurrentAddress, required this.showCurrentLocation, required this.isCurrentSelected, required this.onMapTap, required this.onCurrentTap, required this.tabs, required this.selectedTab, required this.onTabChanged, required this.addressList, required this.onAddressTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

        _MapAndCurrentCard(
          appCurrentAddress: appCurrentAddress,
          showCurrentLocation: showCurrentLocation,
          isCurrentSelected: isCurrentSelected,
          onMapTap: onMapTap,
          onCurrentTap: onCurrentTap,
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        _TabsAndListCard(
          tabs: tabs,
          selectedTab: selectedTab,
          onTabChanged: onTabChanged,
          addressList: addressList,
          onAddressTap: onAddressTap,
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),
      ]),
    );
  }
}

class _MapAndCurrentCard extends StatelessWidget {
  final AddressModel? appCurrentAddress;
  final bool showCurrentLocation;
  final bool isCurrentSelected;
  final VoidCallback onMapTap;
  final VoidCallback onCurrentTap;

  const _MapAndCurrentCard({
    required this.appCurrentAddress, required this.showCurrentLocation, required this.isCurrentSelected, required this.onMapTap, required this.onCurrentTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeSmall,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        InkWell(
          onTap: onMapTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
            child: Row(children: [
              Image.asset(Images.mapSet, width: 20, height: 20, color: Theme.of(context).disabledColor),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              Expanded(
                child: Text('set_on_map'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
              ),
              Icon(Icons.arrow_forward, size: 18, color: Theme.of(context).disabledColor),
            ]),
          ),
        ),
        if (showCurrentLocation && appCurrentAddress != null)
          InkWell(
            onTap: onCurrentTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(CupertinoIcons.placemark, size: 22, color: Theme.of(context).disabledColor),
                ),
                const SizedBox(width: Dimensions.paddingSizeDefault),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('current_location'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
                    const SizedBox(height: 2),
                    Text(
                      appCurrentAddress?.address ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ]),
                ),
                Icon(isCurrentSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 22, color: isCurrentSelected ? Theme.of(context).primaryColor : Theme.of(context).disabledColor),
              ]),
            ),
          ),
      ]),
    );
  }
}

class _TabsAndListCard extends StatelessWidget {
  final List<String> tabs;
  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  final List<AddressModel> addressList;
  final ValueChanged<AddressModel> onAddressTap;

  const _TabsAndListCard({
    required this.tabs, required this.selectedTab, required this.onTabChanged, required this.addressList, required this.onAddressTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Row(children: List.generate(tabs.length, (i) {
          final bool selected = selectedTab == i;
          return Padding(
            padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
            child: InkWell(
              onTap: () => onTabChanged(i),
              borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault,
                  vertical: Dimensions.paddingSizeExtraSmall,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).disabledColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                ),
                child: Text(
                  tabs[i],
                  style: robotoMedium.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: selected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ),
          );
        })),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        if (addressList.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
            child: Center(
              child: Text(
                'no_data_found'.tr,
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).disabledColor,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: addressList.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Theme.of(context).disabledColor.withValues(alpha: 0.15),
            ),
            itemBuilder: (context, index) {
              final address = addressList[index];
              return _AddressListTile(
                address: address,
                onTap: () => onAddressTap(address),
              );
            },
          ),
      ]),
    );
  }
}

class _AddressListTile extends StatelessWidget {
  final AddressModel address;
  final VoidCallback onTap;

  const _AddressListTile({required this.address, required this.onTap});

  IconData _iconForType() {
    switch ((address.addressType ?? '').toLowerCase()) {
      case 'home':
        return Icons.home_outlined;
      case 'office':
      case 'work':
        return Icons.work_outline;
      default:
        return Icons.location_on_outlined;
    }
  }

  String _displayLabel() {
    print("---> ${address.addressType}");
    final type = (address.addressType ?? '').trim();
    final addr = address.address ?? '';
    if (type.isNotEmpty && type.toLowerCase() != 'others') {
      return '${type.tr} : $addr';
    }
    return addr;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(_iconForType(), size: 18, color: Theme.of(context).disabledColor),
          ),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Expanded(
            child: Text(
              _displayLabel(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          Icon(Icons.chevron_right, size: 18, color: Theme.of(context).disabledColor),
        ]),
      ),
    );
  }
}

class _SuggestionsCard extends StatelessWidget {
  final List<PredictionModel> suggestions;
  final bool loading;
  final ValueChanged<PredictionModel> onSelected;

  const _SuggestionsCard({
    required this.suggestions,
    required this.loading,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Text('suggestions'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (suggestions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
              child: Center(
                child: Text(
                  'no_data_found'.tr,
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).disabledColor,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: suggestions.length,
              separatorBuilder: (ctx, idx) => Divider(
                height: 1,
                color: Theme.of(context).disabledColor.withValues(alpha: 0.15),
              ),
              itemBuilder: (context, index) {
                final s = suggestions[index];
                return InkWell(
                  onTap: () => onSelected(s),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                    child: Row(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: Theme.of(context).disabledColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.location_on_outlined, size: 18, color: Theme.of(context).disabledColor),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeDefault),
                      Expanded(
                        child: Text(
                          s.description ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: robotoMedium.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 18, color: Theme.of(context).disabledColor),
                    ]),
                  ),
                );
              },
            ),
        ]),
      ),
    );
  }
}

class _SearchModeBottomBar extends StatelessWidget {
  final bool showCurrentLocation;
  final VoidCallback onMapTap;
  final VoidCallback onCurrentTap;

  const _SearchModeBottomBar({required this.showCurrentLocation, required this.onMapTap, required this.onCurrentTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
      child: Row(children: [
        Expanded(
          child: InkWell(
            onTap: onMapTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.location_on_outlined, size: 18, color: Theme.of(context).primaryColor),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Text(
                  'set_on_map'.tr,
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ]),
            ),
          ),
        ),
        if (showCurrentLocation) ...[
          Container(width: 1, height: 24, color: Theme.of(context).disabledColor.withValues(alpha: 0.2)),
          Expanded(
            child: InkWell(
              onTap: onCurrentTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.my_location, size: 18, color: Theme.of(context).primaryColor),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Text(
                    'current_location'.tr,
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}
