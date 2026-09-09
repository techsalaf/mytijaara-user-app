import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class SearchFieldWidget extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? suffixIcon;
  final IconData? prefixIcon;
  final Function iconPressed;
  final Color? filledColor;
  final Color? iconColor;
  final Function? onSubmit;
  final Function? onChanged;
  final double? radius;
  final bool isFocused;
  final Widget? prefixWidget;
  // Compact mode: tightens the field's height (small content padding + a shrunk
  // suffix-icon tap target) so it lines up with an adjacent back button.
  final bool dense;
  const SearchFieldWidget({
    super.key, required this.controller, required this.hint, this.suffixIcon,
    required this.iconPressed, this.filledColor, this.onSubmit, this.onChanged, this.iconColor,
    this.radius, this.prefixIcon, this.isFocused = false, this.prefixWidget, this.dense = false,
  });

  @override
  State<SearchFieldWidget> createState() => _SearchFieldWidgetState();
}

class _SearchFieldWidgetState extends State<SearchFieldWidget> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      textInputAction: TextInputAction.search,
      autofocus: widget.isFocused,
      inputFormatters: [
        FilteringTextInputFormatter.deny(RegExp(r'[!@#$%^&*(),.?":{}|<>_+-/~`•√π÷×§∆£¢€¥°=©®™✓;]')),
      ],
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(widget.radius ?? Dimensions.radiusSmall), borderSide: BorderSide.none),
        filled: true, fillColor: widget.filledColor ?? Theme.of(context).cardColor,
        isDense: true,
        contentPadding: widget.dense
            ? const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall, horizontal: Dimensions.paddingSizeSmall)
            : null,
        suffixIcon: widget.suffixIcon != null ? IconButton(
          onPressed: widget.iconPressed as void Function()?,
          // In dense mode drop the default 48px min tap target so it doesn't inflate
          // the field height.
          padding: widget.dense ? EdgeInsets.zero : null,
          constraints: widget.dense ? const BoxConstraints(minWidth: 30, minHeight: 0) : null,
          icon: Icon(widget.suffixIcon, color: widget.iconColor ?? Theme.of(context).textTheme.bodyLarge!.color),
        ) : null,
        suffixIconConstraints: widget.dense ? const BoxConstraints(minWidth: 30, minHeight: 30) : null,
        prefixIcon: widget.prefixWidget ?? (widget.prefixIcon != null ? Icon(widget.prefixIcon, size: 24, color: Theme.of(context).disabledColor) : null),
        prefixIconConstraints: widget.prefixWidget != null ? const BoxConstraints(minWidth: 0, minHeight: 0) : null,
      ),
      onSubmitted: widget.onSubmit as void Function(String)?,
      onChanged: widget.onChanged as void Function(String)?,
    );
  }
}
