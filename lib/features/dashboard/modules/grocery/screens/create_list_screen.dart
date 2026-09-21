import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_asset_image_widget.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

class CreateListScreen extends StatefulWidget {
  const CreateListScreen({super.key});

  @override
  State<CreateListScreen> createState() => _CreateListScreenState();
}

class _CreateListScreenState extends State<CreateListScreen> {
  final TextEditingController _itemController = TextEditingController();
  final List<String> _items = <String>['Milk', 'Coffee'];
  bool _saveForLater = true;

  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }

  void _addItem() {
    final String item = _itemController.text.trim();
    if(item.isEmpty) {
      return;
    }

    setState(() {
      _items.add(item);
      _itemController.clear();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _onMyListTap() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Create List'),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeDefault,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'item'.tr,
                      style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                    Row(children: [
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: TextField(
                            controller: _itemController,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _addItem(),
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Ex: Milk',
                              hintStyle: robotoRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).hintColor,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 8),
                              filled: true,
                              fillColor: Theme.of(context).cardColor,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                borderSide: BorderSide(color: Theme.of(context).disabledColor.withAlpha(100)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                borderSide: BorderSide(color: Theme.of(context).disabledColor.withAlpha(100)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),

                      InkWell(
                        onTap: _addItem,
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        child: Container(
                          height: 38,
                          width: 38,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 22),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'item_list'.tr,
                      style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeDefault),

                    _items.isEmpty ? const SizedBox(
                      height: 220,
                      child: _EmptyListView(),
                    ) : ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.35,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                                border: Border.all(color: Theme.of(context).disabledColor.withAlpha(70)),
                              ),
                              child: ListView.separated(
                                padding: EdgeInsets.zero,
                                itemCount: _items.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
                                    child: Row(children: [
                                      Expanded(
                                        child: Text(
                                          _items[index],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: robotoRegular.copyWith(
                                            fontSize: Dimensions.fontSizeLarge,
                                            color: Theme.of(context).textTheme.bodyLarge?.color,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: Dimensions.paddingSizeSmall),
                                      InkWell(
                                        onTap: () => _removeItem(index),
                                        child: const Icon(Icons.delete_outline, color: Color(0xFFFF3B30), size: 20),
                                      ),
                                    ]),
                                  );
                                },
                                separatorBuilder: (context, index) => Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: Theme.of(context).disabledColor.withAlpha(70),
                                ),
                              ),
                            ),
                            const SizedBox(height: Dimensions.paddingSizeDefault),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: Checkbox(
                                    value: _saveForLater,
                                    activeColor: Theme.of(context).primaryColor,
                                    side: BorderSide(color: Theme.of(context).disabledColor.withValues(alpha: .5)),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _saveForLater = value ?? false;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Save For Latter',
                                        style: robotoRegular.copyWith(
                                          fontSize: Dimensions.fontSizeLarge,
                                          color: Theme.of(context).textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Wrap(
                                        children: [
                                          Text(
                                            'If you check this you will see it in your ',
                                            style: robotoRegular.copyWith(
                                              fontSize: Dimensions.fontSizeSmall,
                                              color: Theme.of(context).hintColor,
                                            ),
                                          ),
                                          InkWell(
                                            onTap: _onMyListTap,
                                            child: Text(
                                              'My List.',
                                              style: robotoRegular.copyWith(
                                                fontSize: Dimensions.fontSizeSmall,
                                                color: Theme.of(context).primaryColor,
                                                decoration: TextDecoration.underline,
                                                decorationColor: Theme.of(context).primaryColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              CustomButton(
                buttonText: "Let's Start Shopping",
                height: 40,
                radius: Dimensions.radiusSmall,
                fontSize: Dimensions.fontSizeSmall,
                isBold: false,
                textStyle: robotoBold.copyWith(color: Colors.white,),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyListView extends StatelessWidget {
  const _EmptyListView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              const CustomAssetImageWidget(Images.emptyBox, height: 60, width: 60, fit: BoxFit.contain),
              Positioned(
                top: -5,
                child: Container(
                  height: 18,
                  width: 18,
                  decoration: BoxDecoration(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add, color: Theme.of(context).cardColor, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Text(
            'No items added yet. Please add at least\nitems to continue shopping',
            textAlign: TextAlign.center,
            style: robotoRegular.copyWith(
              fontSize: 10,
              color: Theme.of(context).hintColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
