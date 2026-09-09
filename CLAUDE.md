# CLAUDE.md — 6amMart User App

> **See also:** [.claude/CONVENTIONS.md](.claude/CONVENTIONS.md) — migration policy (old vs `_new` folders), canonical exemplar files, and copy-paste templates for new features. Read it alongside this file before scaffolding code.

## Widget Rules

**Always use Class widgets, never method/function widgets.**

- If the widget is only used within one file, prefix it with `_` to make it private.
- If it is reused across files, place it in the feature's `widgets/` folder or `lib/common/widgets/`.

```dart
// CORRECT — public widget (reusable across files)
class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) => Card(child: Text(product.name));
}

// CORRECT — private widget (file-scoped only)
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Text(title);
}

// WRONG — never do this
Widget _buildProductCard(Product product) => Card(child: Text(product.name));
```

Reason: class widgets are reusable, properly rebuild in the widget tree, benefit from `const` constructors, and are debuggable in DevTools. Function widgets bypass the widget lifecycle.

### Constructor Parameter Formatting — group 5 per line

When a `StatelessWidget` or `StatefulWidget` constructor has many parameters, **do not place each constructor parameter on its own line**. Group them **5 per line**, then wrap to the next line for the next 5, and so on.

This rule applies **only to the constructor parameter list**. The `final` field declarations above the constructor stay one per line as usual.

```dart
// CORRECT — fields one per line, constructor params grouped 5 per line
class ProductCard extends StatelessWidget {
  final Product product;
  final bool isFeatured;
  final VoidCallback? onTap;
  final double? width;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final bool showBadge;
  final String? badgeText;
  final TextStyle? titleStyle;
  final bool isHorizontal;
  final int? maxLines;

  const ProductCard({super.key,
    required this.product, this.isFeatured = false, this.onTap, this.width, this.padding,
    this.backgroundColor, this.borderRadius, this.showBadge = false, this.badgeText, this.titleStyle,
    this.isHorizontal = false, this.maxLines,
  });

  @override
  Widget build(BuildContext context) => const SizedBox();
}

// WRONG — every constructor parameter on its own line
const ProductCard({
  super.key,
  required this.product,
  this.isFeatured = false,
  this.onTap,
  this.width,
  this.padding,
  this.backgroundColor,
  this.borderRadius,
  this.showBadge = false,
  this.badgeText,
  this.titleStyle,
  this.isHorizontal = false,
  this.maxLines,
});
```

Notes:
- For constructors with **5 or fewer** parameters, a single line is fine (no wrapping needed).
- Keep parameters in their original order — do not reorder them just to fit the grouping.
- This formatting rule is project-specific and overrides `dart format` defaults if they conflict.

---

## Project Architecture

**Clean Architecture + GetX**, with strict layer separation per feature.

```
lib/
├── api/            # HTTP client, API checker, local cache client
├── common/         # Shared widgets (73+), shared models
├── features/       # 45+ self-contained feature modules
├── helper/         # Utilities, DI (get_di.dart), route_helper.dart
├── interfaces/     # Abstract contracts
├── local/          # Drift ORM SQLite cache
├── theme/          # Light/dark theme definitions
└── util/           # Constants: dimensions.dart, images.dart, styles.dart, app_constants.dart
```

Each feature follows this internal structure:

```
features/<feature>/
├── controllers/    # GetX controllers (state + business logic calls)
├── domain/
│   ├── models/
│   ├── repositories/   # *_repository.dart + *_repository_interface.dart
│   └── services/       # *_service.dart + *_service_interface.dart
├── screens/        # Full-page UI widgets
└── widgets/        # Feature-scoped reusable widgets
```

---

## State Management — GetX

- All controllers extend `GetxController implements GetxService`
- Use `update()` to trigger rebuilds; wrap in `GetBuilder<ControllerName>`
- **Never use `Rx<T>` / `.obs`** — always use plain fields + `update()`
- Register all dependencies in `lib/helper/get_di.dart` using `Get.lazyPut()`
- Retrieve controllers via `Get.find<ControllerName>()`

```dart
class ItemController extends GetxController implements GetxService {
  List<Item>? _items;
  List<Item>? get items => _items;

  Future<void> getItems() async {
    _items = await _itemServiceInterface.getItems();
    update();
  }
}
```

### Initialization — use widget `initState`, not controller `onInit`

Controllers are **singletons** registered via `Get.lazyPut()`. `onInit` only fires once for the app's lifetime and will not re-run when navigating back to a screen. Always trigger data loading from the widget's `initState`.

```dart
// CORRECT
class _ItemScreenState extends State<ItemScreen> {
  @override
  void initState() {
    super.initState();
    Get.find<ItemController>().getItems();
  }

  @override
  Widget build(BuildContext context) => GetBuilder<ItemController>(
        builder: (controller) => ...,
      );
}

// WRONG — stale data on revisit; onInit does not re-run
class ItemController extends GetxController implements GetxService {
  @override
  void onInit() {
    super.onInit();
    getItems();
  }
}
```

### `notify` parameter — suppress synchronous `update()` when called from `initState`

A controller method that calls `update()` **before** an `await` triggers a synchronous rebuild. This is safe when called from a button or gesture handler, but **unsafe when called from `initState`** (the widget tree has not been built yet).

**Rule:** Any controller method that contains a synchronous `update()` before an `await` must accept a `bool notify = true` parameter and guard that call. The final `update()` after the `await` is always safe and must remain unconditional.

```dart
// CORRECT — controller method
Future<void> loadPickerRoots({bool notify = true}) async {
  _pickerRootList = null;
  if (notify) update();          // guarded — skip when called from initState
  _pickerRootList = await service.getPickerRoots();
  update();                      // always safe — widget is mounted by this point
}

// CORRECT — called from initState
@override
void initState() {
  super.initState();
  Get.find<MyController>().loadPickerRoots(notify: false);
}

// CORRECT — called from user interaction (default notify: true)
onTap: () => Get.find<MyController>().loadPickerRoots(),

// WRONG — calling update() before await with no guard, then calling from initState
Future<void> loadPickerRoots() async {
  _pickerRootList = null;
  update();    // ← unsafe if called from initState
  _pickerRootList = await service.getPickerRoots();
  update();
}
```

---

## Navigation — GetX Named Routes

- All routes defined in `lib/helper/route_helper.dart`
- Navigate with `Get.toNamed(RouteHelper.getSomePage())`
- Pass arguments via route parameters or `Get.arguments`
- Deep link handling via `app_links` package

---

## Dependency Injection

- **All** controllers, services, and repositories are registered in `lib/helper/get_di.dart`
- Use interfaces for all service and repository dependencies
- Pattern: Controller → ServiceInterface → RepositoryInterface → ApiClient

```dart
// In get_di.dart
Get.lazyPut(() => FeatureController(featureServiceInterface: Get.find()));
Get.lazyPut<FeatureServiceInterface>(() => FeatureService(featureRepositoryInterface: Get.find()));
Get.lazyPut<FeatureRepositoryInterface>(() => FeatureRepository(apiClient: Get.find()));
```

---

## API / Network Layer

- HTTP client: `lib/api/api_client.dart` (extends `GetxService`)
- Methods: `getData()`, `postData()`, `putData()`, `deleteData()`, `multipartRequest()`
- All responses validated through `lib/api/api_checker.dart`
- Standard response wrapper: `lib/common/models/response_model.dart`
- Offline cache via Drift (`lib/local/`) — keyed by endpoint

---

## Local Persistence (`SharedPreferences`)

**Never call `SharedPreferences` directly from a controller.** Local read/write must flow through the same layered pipeline as network calls: **Controller → ServiceInterface → RepositoryInterface → Repository (which owns the `SharedPreferences` instance)**.

- The **repository** is the only layer that touches `sharedPreferences` and deals in **raw primitives** (`String`, `bool`, `int`, the JSON string).
- The **service** owns the **business logic + (de)serialization** — JSON encode/decode, model mapping, de-duplication, list caps, etc. It returns typed values (`AddressModel`, `List<Model>`).
- The **controller** holds in-memory state and calls the service only — no `Get.find<SharedPreferences>()`, no `jsonEncode`/`jsonDecode`, no storage keys.
- Storage keys + limits live in `lib/util/app_constants.dart`.

```dart
// Repository — raw primitives only, the sole owner of SharedPreferences
@override
String? getRecentDeliveryAddresses() => sharedPreferences.getString(AppConstants.recentDeliveryAddresses);

@override
Future<void> saveRecentDeliveryAddresses(String addresses) async {
  await sharedPreferences.setString(AppConstants.recentDeliveryAddresses, addresses);
}

// Service — JSON + business logic (dedup, cap), returns typed models
@override
List<AddressModel> getRecentDeliveryAddresses() {
  final String? raw = locationRepoInterface.getRecentDeliveryAddresses();
  if (raw == null || raw.isEmpty) return [];
  final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
  return decoded.map((e) => AddressModel.fromJson(e as Map<String, dynamic>)).toList();
}

// Controller — in-memory state only, delegates to the service
void loadRecentAddresses() {
  _recentAddresses = locationServiceInterface.getRecentDeliveryAddresses();
}
```

```dart
// WRONG — controller reaching into SharedPreferences and doing JSON itself
final prefs = Get.find<SharedPreferences>();
_recentAddresses = (jsonDecode(prefs.getString(AppConstants.recentDeliveryAddresses)!) as List)
    .map((e) => AddressModel.fromJson(e)).toList();
```

Exception: thin static helpers that already wrap a single pref key (e.g. `AddressHelper.getUserAddressFromSharedPref()`) may be reused as-is.

---

## Common Widgets

Use existing shared widgets from `lib/common/widgets/` before creating new ones:

| Widget | File |
|--------|------|
| `CustomButton` | `custom_button.dart` |
| `CustomAppBar` | `custom_app_bar.dart` |
| `CustomImage` | `custom_image.dart` |
| `CustomLoader` | `custom_loader.dart` |
| `showCustomSnackBar()` | `custom_snackbar.dart` |
| `CustomDialog` | `custom_dialog.dart` |
| Card layouts | `card_design/` subdirectory |

---

## Styling & Theme

- Spacing/sizes: `lib/util/dimensions.dart`
- Text styles: `lib/util/styles.dart`
- Asset paths: `lib/util/images.dart`
- App-wide constants: `lib/util/app_constants.dart`
- Colors: via `Theme.of(context)` — supports light/dark + per-module color theming
- Font: Roboto (weights 400, 500, 700, 900) — defined in `pubspec.yaml`
- Never hardcode colors, sizes, or font sizes — always reference `Dimensions` / `Styles` / theme

---

## Platforms

The app targets **iOS, Android, and Web**. Use `ResponsiveHelper` for layout decisions. Platform-specific code should be gated with `kIsWeb` or `Platform` checks. Route transitions differ: fade for web, top-level for mobile.

---

## Code Conventions

- Use `const` constructors wherever possible
- Always pass `super.key` in widget constructors
- Name screens with `Screen` suffix, widgets without (or with `Widget` suffix for clarity)
- Name controllers with `Controller` suffix, services with `Service`, repositories with `Repository`
- Interface files: `*_interface.dart` (in domain/repositories and domain/services)
- Models are plain Dart classes with `fromJson` / `toJson`

---

## Localization

Every user-visible string **must** use `.tr` (GetX translation). Never use a raw string literal in UI code.

When adding any new user-visible string:
1. Add the key + English value to `assets/language/en.json`
2. Add the key + translated value to **every** other language file in `assets/language/` (currently `ar.json`, `bn.json`, `es.json`)
3. All four files must stay in sync — missing keys fall back to the key name itself, not a translation
4. always add localization keys end of file
```dart
// CORRECT
Text('filters'.tr)
Text('currently_open'.tr)

// WRONG — never hardcode UI strings
Text('Filters')
Text('Currently Open')
```

---

## Do Not

- Do not create function/method widgets — always create class widgets (use `_PrivateClass` for file-scoped widgets)
- Do not use `Rx<T>` / `.obs` — use plain fields + `update()`
- Do not use `GetxController.onInit()` for data loading — controllers are singletons; use widget `initState` instead
- Do not use `ScaffoldMessenger.of(context).showSnackBar(...)` directly — always use `showCustomSnackBar(message)` from `lib/common/widgets/custom_snackbar.dart`
- Do not hardcode strings visible to users — use `.tr` (GetX) for i18n
- Do not call `Get.put()` inside widgets — all DI is in `get_di.dart`
- Do not add new dependencies without checking if an existing package already covers the need
- Do not bypass the service/repository layer by calling `ApiClient` directly from a controller
