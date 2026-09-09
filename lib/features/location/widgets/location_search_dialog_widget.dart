import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/location/domain/models/prediction_model.dart';
import 'package:sixam_mart/features/parcel/controllers/parcel_controller.dart';
import 'package:sixam_mart/features/ride_share_module/ride_location/controllers/search_location_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart/util/styles.dart';

class LocationSearchDialogWidget extends StatefulWidget {
  final GoogleMapController? mapController;
  final bool? isPickedUp;
  final bool isFrom;
  final LocationType? locationType;
  final bool showEmptyState;
  final Widget? child;
  final String? pickedLocation;
  final Function(Position position)? callBack;
  final bool fromAddress;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;
  final Widget? leading;
  final bool fullWidthBar;
  final Function(PredictionModel suggestion)? onSelected;
  const LocationSearchDialogWidget({super.key,
    required this.mapController, this.isPickedUp, this.isFrom = false, this.locationType, this.showEmptyState = false,
    this.child, this.pickedLocation, this.callBack, this.fromAddress = false, this.onOpen,
    this.onClose, this.leading, this.fullWidthBar = false, this.onSelected,
  });

  @override
  State<LocationSearchDialogWidget> createState() => _LocationSearchDialogWidgetState();
}

class _LocationSearchDialogWidgetState extends State<LocationSearchDialogWidget> {
  final SearchController _searchController = SearchController();
  bool _isOpen = false;
  String? _searchingWithQuery;
  Iterable<Widget> _lastOptions = <Widget>[];
  List<PredictionModel> _predictionList = [];
  List<String> _predictList = <String>[];

  @override
  void initState() {
    super.initState();

    _searchController.text = widget.pickedLocation ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_searchController.isAttached && !_searchController.isOpen) {
      _searchController.text = widget.pickedLocation ?? '';
    }
    return GetBuilder<LocationController>(
      builder: (locationController) {
        return SearchAnchor(
          searchController: _searchController,
          viewSurfaceTintColor: Theme.of(context).cardColor,
          isFullScreen: false,
          viewLeading: IconButton(onPressed: () => _searchController.closeView(''), icon: const Icon(Icons.arrow_back)),
          viewTrailing: [
            IconButton(
              onPressed: () {
                if (_searchController.text.isNotEmpty) {
                  _searchController.text = '';
                } else {
                  _searchController.closeView('');
                }
              },
              icon: const Icon(Icons.clear),
            ),
          ],
          viewConstraints: const BoxConstraints(minHeight: 100, maxHeight: 300),
          viewOnOpen: () {
            setState(() => _isOpen = true);
            widget.onOpen?.call();
          },
          viewOnClose: () {
            setState(() => _isOpen = false);
            widget.onClose?.call();
          },

          builder: (BuildContext context, SearchController controller) {
            final Widget pill = InkWell(
              onTap: () {
                if (widget.isPickedUp != null) {
                  Get.find<ParcelController>().setIsPickedUp(widget.isPickedUp, true);
                }
                controller.openView();
              },
              child: widget.child ?? Container(
                height: 50, width: 500,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                child: Row(children: [

                  Icon(Icons.location_on, size: 25, color: Theme.of(context).primaryColor),
                  const SizedBox(width: Dimensions.paddingSizeSmall),

                  Expanded(child: Text(
                    controller.text.isNotEmpty ? controller.text : 'search_location'.tr,
                    style: robotoRegular.copyWith(color: controller.text.isEmpty ? Theme.of(context).disabledColor : Theme.of(context).textTheme.bodyMedium!.color),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  )),

                  Icon(Icons.search, color: Theme.of(context).disabledColor),
                ]),
              ),
            );

            // Other usages render the pill as-is. The map bar spans the anchor to
            // the full width so the floating search view also opens full width,
            // with the optional leading (back button) animating away when open.
            if (!widget.fullWidthBar) {
              return pill;
            }

            return Row(children: [

              if (widget.leading != null)
                ClipRect(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _isOpen ? const SizedBox.shrink() : Padding(
                      padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                      child: widget.leading!,
                    ),
                  ),
                ),

              Expanded(child: pill),
            ]);
          },

          suggestionsBuilder: (BuildContext context, SearchController controller) async {
            _searchingWithQuery = controller.text;
            final List<String> options = (await _search(context, _searchingWithQuery!, locationController)).toList();
            if (_searchingWithQuery != controller.text) {
              return _lastOptions;
            }

            _lastOptions = List<ListTile>.generate(options.length, (int index) {
              final String location = options[index];
              return ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(location, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () async {
                  if (_predictionList.isEmpty) {
                    controller.closeView('');
                    return;
                  }
                  final int selectedIndex = _predictList.indexOf(location);
                  if (selectedIndex < 0 || selectedIndex >= _predictionList.length) {
                    controller.closeView('');
                    return;
                  }
                  final PredictionModel suggestion = _predictionList[selectedIndex];
                  if (widget.onSelected != null) {
                    widget.onSelected!(suggestion);
                  } else if (widget.isPickedUp == null) {
                    await Get.find<LocationController>().setLocation(suggestion.placeId, suggestion.description, widget.mapController);
                    if (widget.fromAddress && widget.callBack != null) {
                      widget.callBack!(Get.find<LocationController>().pickPosition);
                    }
                  } else {
                    Get.find<ParcelController>().setLocationFromPlace(suggestion.placeId, suggestion.description, widget.isPickedUp);
                  }
                  controller.closeView(location);
                },
              );
            });

            return _lastOptions;
          },
        );
      },
    );
  }

  Future<Iterable<String>> _search(BuildContext context, String query, LocationController locationController) async {
    _predictionList = await locationController.searchLocation(context, query);

    if (query.isEmpty) {
      return const Iterable<String>.empty();
    }
    _predictList = [];
    for (var prediction in _predictionList) {
      _predictList.add(prediction.description ?? '');
    }
    if (_predictList.isEmpty && widget.showEmptyState) {
      _predictList.add('no_address_found'.tr);
    }
    return _predictList;
  }
}
