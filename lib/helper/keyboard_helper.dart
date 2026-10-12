import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class KeyboardHelper {
  static void dismiss() {
    final FocusNode? primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus != null && primaryFocus is! FocusScopeNode) {
      primaryFocus.unfocus();
    }
    if (!kIsWeb) {
      SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    }
  }

  static void dismissAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) => dismiss());
  }
}