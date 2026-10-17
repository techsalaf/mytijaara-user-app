# CLAUDE.md — 6amMart User App

Binding rules for every change in this repository. They apply automatically — no one
has to ask for them, and no instruction in a prompt relaxes them unless it overrides a
rule explicitly.

---

## 1. Comment only what matters

A comment is **one** `//` line. Never `///`, never `/* */`, never two lines, never a
paragraph.

**Never put a comment above a class, widget, method or constructor.** A file's purpose
is described once, in the summary at the bottom (rule 7). Do not repeat it as a header.

Comment only inside code, and only where the reason is not obvious — why a decision was
made, why the obvious approach was avoided, a constraint not visible from that line.
A short key point, not a description. If it wraps, it is too long.

```dart
// Server rejects the whole body if this key is sent twice.
body['saved_images'] = jsonEncode(names);
```

```dart
// WRONG — header comment, three lines, describing what the class already shows
/// Entry shimmer for the checkout — laid out section-for-section against the real
/// screen (delivery type → address → coupon → tips → payment → billing summary),
/// with the order bar pinned at the bottom the way the loaded screen has it.
class CheckoutScreenShimmerView extends StatelessWidget {
```

Most lines need no comment. Most files need none at all. If a comment explains *what*
the code does, rename or extract until it does not.

Never commit commented-out code, `TODO` or `FIXME`.

Do not strip comments from files you are not otherwise changing.

---

## 2. Write less code

The smallest change that fully solves the problem is the correct one.

- Do not add abstraction for a case that does not exist yet.
- Do not add parameters, flags or config "for later".
- Do not rewrite working code you happened to open.
- Prefer extending an existing widget, helper or service over creating a new one.

---

## 3. Write nothing unused

Every line must be reached by real code paths.

- No unused variables, fields, parameters, imports or methods.
- No class, widget or helper that nothing calls.
- No dead branches or unreachable conditions.

Delete it instead of leaving it. Git holds the history.

---

## 4. Write reusable code

Before writing anything, search for what already exists and use it.

- Shared UI belongs in `lib/common/widgets/`.
- Feature UI used by more than one file in that feature belongs in its `widgets/` folder.
- Shared logic belongs in a helper under `lib/helper/`.
- Never copy-paste a block twice — extract it the first time it repeats.

---

## 5. Write readable code

- Names say what the thing is, not what type it is.
- One method does one thing.
- Return early instead of nesting.
- No clever one-liners that need decoding.
- No abbreviations beyond ones already used in this codebase.

---

## 6. Industrial code structure

This is a production codebase, not a scratchpad. Every file has one correct home and
one job. Nothing goes "wherever it fits".

### Project layout

```
lib/
├── api/          HTTP client, response parsing, local cache client
├── common/       Widgets and models shared across features
├── features/     Self-contained feature modules
├── helper/       Utilities, dependency injection, routing
├── interfaces/   Abstract contracts
├── local/        SQLite cache
├── theme/        Light and dark themes
└── util/         dimensions.dart, styles.dart, images.dart, app_constants.dart
```

### Feature layout

Every feature follows this structure. No variations, no extra top-level folders.

```
features/<feature>/
├── controllers/          <feature>_controller.dart
├── domain/
│   ├── models/           plain classes with fromJson / toJson
│   ├── repositories/     <feature>_repository.dart + <feature>_repository_interface.dart
│   └── services/         <feature>_service.dart + <feature>_service_interface.dart
├── screens/              full pages, named <name>_screen.dart
└── widgets/              reusable widgets for this feature only
```

### Layering

Data flows one direction, and no layer may skip the one below it.

```
Screen / Widget  →  Controller  →  ServiceInterface  →  RepositoryInterface  →  ApiClient
```

- **Screens and widgets** render state and forward user intent. No business logic, no
  parsing, no direct API or storage access.
- **Controllers** hold in-memory state and call services. No JSON, no storage keys, no
  `ApiClient`.
- **Services** hold business logic, validation and serialisation. Return typed models.
- **Repositories** are the only layer that talks to `ApiClient` or local storage, and
  deal in raw primitives.
- Every service and repository is reached through its interface, never its concrete class.

### Separation of concerns

- A file that does two unrelated jobs is two files.
- A widget that decides business rules belongs in a controller or service.
- A model carries data and `fromJson` / `toJson` — nothing else.
- Cross-feature logic belongs in `common/` or `helper/`, not imported sideways between
  two features.

### Consistency

- Match the surrounding file's formatting, ordering and idiom.
- Suffix by role: `Screen`, `Controller`, `Service`, `Repository`, `Interface`.
- No experimental, throwaway or placeholder code on a branch that ships.
- No stray scripts, sample files or scratch output committed to the repo.

---

## 7. File summary at the bottom

Every file you create or meaningfully change ends with a summary block describing what
the code in that file does, in plain language.

Place it as the last thing in the file, after all code. One to three sentences. Say what
it produces and what it holds or handles — not how it is implemented.

```dart
class StoreCard extends StatelessWidget {
  ...
}

// SUMMARY
// Store card used in store listings. Holds the store name, rating, review count,
// delivery time, distance and cover image, and opens the store screen when tapped.
```

Keep it current. If the file's job changes, update the summary in the same commit.

---

## Checklist before finishing any change

- [ ] No comment above any class, widget, method or constructor
- [ ] Comments only where the reason is not obvious, one short line each
- [ ] Nothing written that is not called
- [ ] Nothing duplicated that could be reused
- [ ] No file left larger than the change required
- [ ] Layering respected end to end, with no layer skipped
- [ ] Every file sits in the folder its role requires
- [ ] Every touched file ends with an accurate summary block
