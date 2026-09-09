import 'dart:async';

import 'package:get/get.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';

class FoodModuleController extends GetxController {
  final String searchTitle;
  FoodModuleController({this.searchTitle = 'Search for'});

  // How long each word stays before the next one rolls up into view.
  static const Duration _wordChangeDuration = Duration(milliseconds: 2500);

  Timer? _wordChangeTimer;
  int _wordIndex = 0;
  String _currentWord = '';
  String get currentWord => _currentWord;

  @override
  void onInit() {
    super.onInit();
    _updateCurrentWord();
    _wordChangeTimer = Timer.periodic(_wordChangeDuration, (_) {
      _wordIndex++;
      _updateCurrentWord();
    });
  }

  // Words shown after "Search for": on Home (no module selected) the available
  // module names; inside a module the active module's categories — falling back
  // to the module name until categories are loaded.
  List<String> _buildWords() {
    final SplashController splash = Get.find<SplashController>();
    final bool isGlobal = splash.selectedModuleIndex == 0;

    if(isGlobal) {
      final modules = splash.moduleList ?? [];
      return modules
          .map((module) => module.moduleName ?? '')
          .where((String name) => name.trim().isNotEmpty)
          .toList();
    }

    final categories = Get.find<CategoryController>().categoryList ?? [];
    final List<String> categoryNames = categories
        .map((category) => category.name ?? '')
        .where((String name) => name.trim().isNotEmpty)
        .toList();
    if(categoryNames.isNotEmpty) {
      return categoryNames;
    }

    final String? moduleName = splash.module?.moduleName;
    return (moduleName != null && moduleName.trim().isNotEmpty) ? <String>[moduleName] : <String>[];
  }

  void _updateCurrentWord() {
    final List<String> words = _buildWords();
    final String next = words.isEmpty ? '' : words[_wordIndex % words.length];
    if(next != _currentWord) {
      _currentWord = next;
      update();
    }
  }

  @override
  void onClose() {
    _wordChangeTimer?.cancel();
    super.onClose();
  }
}
