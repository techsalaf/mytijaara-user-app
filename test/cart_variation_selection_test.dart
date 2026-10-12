import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/item/domain/repositories/item_repository_interface.dart';
import 'package:sixam_mart/features/item/domain/services/item_service.dart';

/// What the item sheet opened from the cart preselects for an old-style module
/// (grocery, pharmacy, shop — everything `getModuleConfig().newVariation` says no to).
///
/// `VariationView` reads `itemController.variationIndex[group]` for every choice
/// option and `setCartVariationIndex` writes back to the same slot, so this list has
/// to carry one entry per group. A short one showed no selection at all and put every
/// tap out of range, which is how a grocery row opened from the cart came up blank and
/// refused to change.
///
/// `ItemService` only needs its repository for the network calls, none of which this
/// arithmetic touches.
class _StubItemRepository implements ItemRepositoryInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

ChoiceOptions _group(List<String> options) =>
    ChoiceOptions.fromJson(<String, dynamic>{'name': 'choice_1', 'title': 'size', 'options': options});

void main() {
  final ItemService service = ItemService(itemRepositoryInterface: _StubItemRepository());

  // The shape a live payload uses: options keep their spaces, the stored type drops them.
  final List<ChoiceOptions> twoGroups = <ChoiceOptions>[
    _group(<String>['1 lb', ' 5 ib']),
    _group(<String>['Skinless', ' boneless chicken breast and thigh']),
  ];

  List<int> indexesFor(String? type, List<ChoiceOptions>? groups) => service.initializeCartVariationIndexes(
    type == null ? <Variation>[] : <Variation>[Variation(type: type)], groups,
  );

  group('a cart row whose variation can be matched', () {
    test('each group lands on the option the row holds', () {
      expect(indexesFor('5ib-bonelesschickenbreastandthigh', twoGroups), <int>[1, 1]);
    });

    test('the first option of each group is matched just as well as the rest', () {
      expect(indexesFor('1lb-Skinless', twoGroups), <int>[0, 0]);
    });

    test('a type that kept its spaces still matches — both sides are normalised', () {
      expect(indexesFor('5 ib-Skinless', twoGroups), <int>[1, 0]);
    });
  });

  group('a cart row the picker used to break on', () {
    test('no stored variation still yields one entry per group', () {
      // This is the reported case: `product_variation` comes back empty, and reading
      // `variationTypes[0]` off it threw before a single index was produced.
      expect(indexesFor(null, twoGroups), <int>[0, 0]);
    });

    test('fewer types than groups fills the groups the type does not reach', () {
      expect(indexesFor('5ib', twoGroups), <int>[1, 0]);
    });

    test('an unmatched type falls back to the first option rather than dropping the group', () {
      // An option carrying a hyphen splits into more parts than there are groups, so the
      // second group is compared against a fragment that matches nothing.
      expect(indexesFor('half-kg-Skinless', twoGroups), <int>[0, 0]);
    });

    test('an item with no choice options asks for no indexes', () {
      expect(indexesFor('1lb', const <ChoiceOptions>[]), isEmpty);
      expect(indexesFor('1lb', null), isEmpty);
    });
  });
}
