# 03 — Screen: Notes

This chapter walks the **Notes** feature end-to-end: a Keep-style note list with pinning, archiving, color tagging, and free-text search. It is the simplest full-stack vertical in the app and therefore the best place to see Clean Architecture, Riverpod wiring, and Isar persistence cooperate in real code. By the end you should be able to point at any line in any of the sixteen files below and explain what layer it belongs to and who calls it.

If you have read `00-how-flutter-works.md` you already know what a widget tree is, what Riverpod does (it is the DI container), and that Isar is a local NoSQL store with code-generated queries. This chapter does not re-teach any of that — it only shows how those pieces are assembled into a working screen.

## File map

| Layer | File | Responsibility | Spring analogue |
|---|---|---|---|
| Domain | `domain/entities/note.dart` | Immutable business object | `@Entity` POJO (no JPA annotations) |
| Domain | `domain/repositories/note_repository.dart` | Interface — the contract | `interface NoteRepository` |
| Domain | `domain/use_cases/create_note_use_case.dart` | Validation + delegate | `@Service` method `createNote()` |
| Domain | `domain/use_cases/update_note_use_case.dart` | Pass-through save | `@Service` method `updateNote()` |
| Domain | `domain/use_cases/delete_note_use_case.dart` | Pass-through delete | `@Service` method `deleteNote()` |
| Domain | `domain/use_cases/search_notes_use_case.dart` | Trim + branch on empty query | `@Service` method `search()` |
| Domain | `domain/use_cases/toggle_pin_use_case.dart` | Pass-through flip | `@Service` method `togglePin()` |
| Domain | `domain/use_cases/toggle_archive_use_case.dart` | Pass-through flip | `@Service` method `toggleArchive()` |
| Data | `data/models/note_model.dart` (+ `.g.dart`) | Isar-annotated row | `@Entity` + Hibernate mapping |
| Data | `data/datasources/note_local_datasource.dart` | Raw Isar queries | `JpaRepository` impl |
| Data | `data/repositories/note_repository_impl.dart` | Maps models to entities | `@Repository` bean |
| Presentation | `presentation/providers/notes_provider.dart` | State + DI wiring | `@Controller` + bean config |
| Presentation | `presentation/screens/notes_list_screen.dart` | The list page | Thymeleaf view + controller |
| Presentation | `presentation/screens/note_editor_screen.dart` | Create/edit page | Thymeleaf form + controller |
| Presentation | `presentation/widgets/note_card.dart` | One list row | Reusable view fragment |
| Presentation | `presentation/widgets/color_picker.dart` | Horizontal color strip | Reusable view fragment |

The folder layout itself enforces Clean Architecture: `domain` knows nothing of `data` or `presentation`; `data` depends only on `domain`; `presentation` depends on both. If you ever see an `import` in `domain/` pointing at `data/` or `presentation/`, that is a bug — the dependency rule has been violated.

## Layer 1 — Domain

The domain layer is pure Dart. No Isar, no Flutter, no Riverpod imports. You could lift this folder into a server-side Dart project and it would still compile.

### Entity — `note.dart`

```dart
class Note {
  final int id;
  final String title;
  final String body;
  final int colorIndex;
  final bool isPinned;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    required this.id,
    required this.title,
    required this.body,
    this.colorIndex = 0,
    this.isPinned = false,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });
```

This is the canonical "value object" in the system. Every field is `final`, the constructor is `const`, and there is no setter anywhere. Think of it as the POJO you would write in Java with all fields `private final` and only getters — except Dart synthesizes the getters for you when you declare a field.

The `copyWith` method below it is the idiomatic Dart equivalent of Lombok's `@With` or Java 16 records' `with...` pattern:

```dart
Note copyWith({
  int? id,
  String? title,
  ...
}) {
  return Note(
    id: id ?? this.id,
    title: title ?? this.title,
    ...
  );
}
```

Because every parameter is nullable (`int?`, `String?`), the caller only passes the fields they want to change. The `??` operator is Dart's null-coalesce — `id ?? this.id` reads as "use the new id if provided, otherwise keep the current one". This pattern is used heavily in the editor screen when the user toggles pin state or changes color.

Finally a tiny domain-level invariant:

```dart
bool get isEmpty => title.trim().isEmpty && body.trim().isEmpty;
```

A getter, not a method. Callers write `note.isEmpty`, not `note.isEmpty()`. The use case layer uses this to reject empty saves.

### Repository interface — `note_repository.dart`

```dart
abstract interface class NoteRepository {
  Future<List<Note>> getAllNotes();
  Future<List<Note>> getPinnedNotes();
  Future<List<Note>> getArchivedNotes();
  Future<List<Note>> searchNotes(String query);
  Future<Note?> getNoteById(int id);
  Future<int> createNote(Note note);
  Future<void> updateNote(Note note);
  Future<void> deleteNote(int id);
  Future<void> togglePin(int id);
  Future<void> toggleArchive(int id);
}
```

`abstract interface class` is Dart 3 syntax for "this is a pure interface — no fields, no implementation, classes must `implements` it rather than `extends` it." The Java equivalent is just `interface NoteRepository`.

Note what types appear here: only `Note` (domain entity), primitives, and `Future`. No `NoteModel`, no `Isar`. The interface is the contract the rest of the app codes against; the data layer fulfills it.

`createNote` returns `Future<int>` — the autogenerated id of the newly inserted row, identical to JPA's `save(entity)` returning the managed entity with its assigned id.

### Use cases — six tiny services

Each use case is a single-method class. Spring developers should read each one as a `@Service` method extracted into its own type. The reason for the one-class-per-method discipline: each use case becomes a unit of testable, swappable business logic, and the type system makes it obvious what the screen depends on.

**`create_note_use_case.dart`** — the only use case with non-trivial logic:

```dart
class CreateNoteUseCase {
  final NoteRepository _repository;
  const CreateNoteUseCase(this._repository);

  Future<int> call(Note note) async {
    if (note.isEmpty) throw const ValidationException('Note cannot be empty');
    return _repository.createNote(note);
  }
}
```

Two things to notice. First, the constructor is `const` and takes the dependency positionally — classic constructor injection, the same as Spring's preferred form. Second, the method is named `call`, which lets the caller invoke the instance as if it were a function:

```dart
await CreateNoteUseCase(_repository)(note);  // looks like a function call
```

That is Dart's "callable class" sugar — equivalent to Java's `Function<Note, CompletableFuture<Integer>>`, but with a real class behind it so you can still mock or stub it.

The validation logic guards the invariant from the entity. If both fields are blank we throw `ValidationException` (defined in `core/errors/app_exceptions.dart`). The exception bubbles up through the provider; the screen surfaces it as a snackbar.

**`update_note_use_case.dart`** — pass-through:

```dart
class UpdateNoteUseCase {
  final NoteRepository _repository;
  const UpdateNoteUseCase(this._repository);

  Future<void> call(Note note) => _repository.updateNote(note);
}
```

`=>` is shorthand for `{ return ...; }`. There is no validation here on purpose: the editor screen guarantees the note has an id (it loaded it from disk), and pin/archive toggles do not produce empty notes. If business rules grow later, this is the only line that has to change.

**`delete_note_use_case.dart`**, **`toggle_pin_use_case.dart`**, **`toggle_archive_use_case.dart`** — all three follow the same three-line pattern:

```dart
class DeleteNoteUseCase {
  final NoteRepository _repository;
  const DeleteNoteUseCase(this._repository);

  Future<void> call(int id) => _repository.deleteNote(id);
}
```

You might ask: "Why bother? The screen could call the repository directly." Two answers. (1) The screen depends on use cases, not repositories, which means changing the toggle-pin behaviour (say, adding "max 5 pinned notes") only requires editing one file. (2) It keeps every screen action symmetrical — there is exactly one way to perform a business action, and it is named after the action.

**`search_notes_use_case.dart`** — branching logic:

```dart
class SearchNotesUseCase {
  final NoteRepository _repository;
  const SearchNotesUseCase(this._repository);

  Future<List<Note>> call(String query) {
    if (query.trim().isEmpty) return _repository.getAllNotes();
    return _repository.searchNotes(query.trim());
  }
}
```

When the user opens search and then clears the field, this use case quietly redirects to the full list. The repository never sees an empty query. The whole search flow — "empty query means everything" — is encoded once, here.

## Layer 2 — Data

The data layer turns abstract domain types into rows in an Isar collection. It has one Isar dependency and one mapping responsibility.

### Model — `note_model.dart`

```dart
import 'package:isar/isar.dart';
import '../../domain/entities/note.dart';

part 'note_model.g.dart';

@collection
class NoteModel {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  late String title;

  late String body;
  int colorIndex = 0;
  bool isPinned = false;
  bool isArchived = false;

  @Index()
  late DateTime createdAt;

  @Index()
  late DateTime updatedAt;
```

`@collection`, `@Index`, and `Id` are the Isar equivalents of JPA's `@Entity`, `@Index`, and `@Id`. The `part 'note_model.g.dart'` directive at the top is critical: Isar uses code generation (`build_runner`) to emit a sibling file `note_model.g.dart` containing the actual query builder methods (`isar.noteModels`, `.filter().titleContains(...)`, etc.). If you ever see a "undefined getter `noteModels`" error, it means the generated file is missing or stale — run `dart run build_runner build --delete-conflicting-outputs` to regenerate.

The `.g.dart` file is checked in to source control but is never edited by hand. Treat it the way you would treat Hibernate's bytecode-enhanced classes: it exists, it is necessary, you ignore it.

`late` is Dart's "I will assign this before reading it, please don't make me write a default" marker. The compiler skips null-safety checks in exchange for a runtime error if you read it before writing.

Two methods bridge the model to the entity:

```dart
Note toEntity() => Note(
      id: id,
      title: title,
      body: body,
      colorIndex: colorIndex,
      ...
    );

static NoteModel fromEntity(Note note) => NoteModel()
  ..id = note.id
  ..title = note.title
  ..body = note.body
  ..colorIndex = note.colorIndex
  ..isPinned = note.isPinned
  ..isArchived = note.isArchived
  ..createdAt = note.createdAt
  ..updatedAt = note.updatedAt;
```

The `..` operator is Dart's "cascade" — it evaluates the expression on the left, then performs the operation on the right, and returns the left value. So `NoteModel()..title = ...` reads as "make a new `NoteModel`, set `title` on it, return the model". This is a workaround for the fact that `NoteModel` has no constructor parameters (Isar requires the no-arg form so it can reconstruct rows from disk).

Mapping in both directions is intentional. The domain entity is immutable, but Isar wants a mutable bean with default values. Rather than fight either tool, we accept one mapping layer.

### Datasource — `note_local_datasource.dart`

The datasource is the only place in the app where Isar queries appear. Everything below the repository-impl line is database talk.

```dart
class NoteLocalDatasource {
  final Isar _isar;
  NoteLocalDatasource(this._isar);

  Future<List<NoteModel>> getAllNotes() async {
    try {
      return _isar.noteModels
          .filter()
          .isArchivedEqualTo(false)
          .sortByIsPinnedDesc()
          .thenByUpdatedAtDesc()
          .findAll();
    } on IsarError catch (e) {
      throw DatabaseException('Failed to load notes', cause: e);
    }
  }
```

`_isar.noteModels` is the generated collection accessor (from `note_model.g.dart`). The fluent chain is Isar's strongly-typed query builder — every predicate method (`isArchivedEqualTo`, `sortByIsPinnedDesc`) is generated from the field names on `NoteModel`, so a typo becomes a compile error.

Note the `on IsarError catch` pattern: it is Dart's typed catch. Equivalent to Java's `catch (IsarException e)`. We wrap every low-level error in the app's own `DatabaseException` so the upper layers never have to import Isar to handle failure. The `cause: e` parameter is just a constructor argument on the exception — Dart has no built-in `getCause()`, so the project's exception classes carry it explicitly.

The search query uses a `group` for the OR condition:

```dart
Future<List<NoteModel>> searchNotes(String query) async {
  try {
    final lower = query.toLowerCase();
    return _isar.noteModels
        .filter()
        .isArchivedEqualTo(false)
        .group((q) => q
            .titleContains(lower, caseSensitive: false)
            .or()
            .bodyContains(lower, caseSensitive: false))
        .sortByUpdatedAtDesc()
        .findAll();
  } on IsarError catch (e) {
    throw DatabaseException('Search failed', cause: e);
  }
}
```

`group` is how Isar lets you write `(a OR b) AND c`. Without it the query would parse as `isArchived = false AND title LIKE 'q' OR body LIKE 'q'`, which would return archived notes whose body matches. The `group` forces precedence.

Writes go through Isar transactions:

```dart
Future<int> putNote(NoteModel model) async {
  try {
    return _isar.writeTxn(() => _isar.noteModels.put(model));
  } on IsarError catch (e) {
    throw DatabaseException('Failed to save note', cause: e);
  }
}
```

`writeTxn` is Isar's `@Transactional` equivalent — it acquires the write lock, runs the closure, and commits. All mutations in this codebase pass through it: `putNote`, `deleteNote`. There is no rollback API because Isar treats the closure as atomic by definition.

`put` is upsert: if `model.id == Isar.autoIncrement`, a row is inserted and the generated id is returned; otherwise the existing row is replaced. That is why `NoteRepositoryImpl.updateNote` and `createNote` can share the same datasource method.

### Repository impl — `note_repository_impl.dart`

This class is glue. Its only job is to call the datasource and map `NoteModel` to `Note` (and vice versa).

```dart
class NoteRepositoryImpl implements NoteRepository {
  final NoteLocalDatasource _datasource;
  NoteRepositoryImpl(this._datasource);

  @override
  Future<List<Note>> getAllNotes() async {
    final models = await _datasource.getAllNotes();
    return models.map((m) => m.toEntity()).toList();
  }
```

The `@override` annotation is hint-only in Dart but treated as required by the linter. The pattern `models.map(...).toList()` is the equivalent of Java's `stream().map(...).collect(toList())`. `map` in Dart returns a lazy `Iterable`; `.toList()` materializes it.

Two methods do more than mapping. `togglePin` and `toggleArchive` need to read-modify-write:

```dart
@override
Future<void> togglePin(int id) async {
  final model = await _datasource.getNoteById(id);
  if (model == null) return;
  model.isPinned = !model.isPinned;
  model.updatedAt = DateTime.now();
  await _datasource.putNote(model);
}

@override
Future<void> toggleArchive(int id) async {
  final model = await _datasource.getNoteById(id);
  if (model == null) return;
  model.isArchived = !model.isArchived;
  model.isPinned = false; // archived notes can't be pinned
  model.updatedAt = DateTime.now();
  await _datasource.putNote(model);
}
```

Note the implicit business rule: archiving a note unpins it. This logic lives in the repository, not the use case, because it is a property of the persistence model rather than a screen-level decision. If you wanted to enforce it more aggressively (say, log a warning), the use case is where you would do it; the repository is where you keep the invariant honest.

`getNoteById` returning `null` is a no-op rather than an error. This is deliberate: a slide-action on a card that was just deleted from another device would otherwise throw.

## Layer 3 — Presentation

The presentation layer ties Riverpod, the use cases, and the widgets together.

### Provider + try/catch logger pattern — `notes_provider.dart`

Three providers and one notifier live in this file. Each one is intentionally small.

```dart
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final isar = ref.watch(isarProvider);
  final datasource = NoteLocalDatasource(isar);
  return NoteRepositoryImpl(datasource);
});
```

This is the DI binding. `Provider<NoteRepository>` is the registry — anyone who calls `ref.read(noteRepositoryProvider)` gets the same instance. The closure receives a `ref` (Riverpod's equivalent of `ApplicationContext`) and uses it to look up the Isar instance, then constructs the chain by hand: datasource over Isar, repository over datasource. This is the only place in the feature where concrete classes are wired together.

```dart
final noteSearchQueryProvider = StateProvider<String>((ref) => '');
```

A `StateProvider` is the simplest mutable Riverpod primitive — one value, settable from anywhere via `ref.read(noteSearchQueryProvider.notifier).state = '...'`. The list screen drives this from its search text field; the results provider watches it.

```dart
final notesProvider = AsyncNotifierProvider<NotesNotifier, List<Note>>(NotesNotifier.new);
```

`AsyncNotifierProvider` is the standard Riverpod pattern for "async-loaded state that callers can mutate". Equivalent to a `@Bean` of type `BehaviorSubject<List<Note>>` plus a service that owns it. The state is exposed as `AsyncValue<List<Note>>` — a sealed union of `AsyncLoading`, `AsyncData`, and `AsyncError`. The list screen pattern-matches on this with `.when(loading: ..., data: ..., error: ...)`.

The notifier body:

```dart
class NotesNotifier extends AsyncNotifier<List<Note>> {
  late NoteRepository _repository;

  @override
  Future<List<Note>> build() async {
    _repository = ref.watch(noteRepositoryProvider);
    return _repository.getAllNotes();
  }
```

`build()` is Riverpod's lifecycle hook — it runs once on first read, and re-runs whenever a watched provider invalidates. Its return value becomes the initial state. Here we cache the repository handle and fetch the full list.

Every mutator follows the same shape — call the use case, log the outcome, update local state, and rethrow on failure. The `delete` method is representative:

```dart
Future<void> delete(int id) async {
  try {
    await DeleteNoteUseCase(_repository)(id);
    AppLogger.I.action('notes', 'delete', data: {'id': id});
    state = AsyncData(state.valueOrNull?.where((n) => n.id != id).toList() ?? []);
  } catch (e, s) {
    AppLogger.I.error('notes', 'delete failed', error: e, stack: s, data: {'id': id});
    rethrow;
  }
}
```

Five things happen in nine lines:

1. **Instantiate the use case**. `DeleteNoteUseCase(_repository)(id)` builds the class and immediately invokes its `call` method. The use case is single-use; constructing it per call is free.
2. **Log success**. `AppLogger.I` is a singleton (Dart convention for "Instance"). `.action(category, action, data: ...)` emits a structured log entry. The logger backs the diagnostic screen accessible from the app bar.
3. **Update state optimistically**. Rather than re-querying the database, we filter the deleted id out of the current list and emit a new `AsyncData`. This avoids a flash of loading state.
4. **Log failure on catch**. `catch (e, s)` is Dart's idiom for "error and stack trace". The two-argument form is mandatory if you want the stack.
5. **Rethrow**. The screen needs to know if it failed (so it can show a snackbar). Swallowing the exception here would silently lose errors.

`create` differs slightly because it has to splice the new note into the pinned/unpinned ordering:

```dart
Future<void> create(Note note) async {
  try {
    final id = await CreateNoteUseCase(_repository)(note);
    final created = note.copyWith(id: id);
    AppLogger.I.action('notes', 'create', data: {'id': id, 'len': note.body.length});
    state = AsyncData([...?state.valueOrNull?.where((n) => n.isPinned), created, ...?state.valueOrNull?.where((n) => !n.isPinned)]);
    ref.invalidateSelf();
  } catch (e, s) {
    AppLogger.I.error('notes', 'create failed', error: e, stack: s);
    rethrow;
  }
}
```

`...?` is the null-safe spread operator: "if the iterable is non-null, expand its elements here; otherwise skip". This builds `[pinned notes..., new note, unpinned notes...]` in one expression, then `ref.invalidateSelf()` triggers a real re-fetch from the database (so the ordering matches the canonical Isar query exactly on the next frame).

`togglePin`, `toggleArchive`, and `save` all use `ref.invalidateSelf()` rather than an optimistic update — pin reorders the list, archive removes a note from view, save changes the `updatedAt` timestamp that affects sort order. Refetching is cheaper than reproducing the sort logic in Dart.

Last, the search provider:

```dart
final noteSearchResultsProvider = FutureProvider<List<Note>>((ref) {
  final query = ref.watch(noteSearchQueryProvider);
  final repository = ref.watch(noteRepositoryProvider);
  return SearchNotesUseCase(repository)(query);
});
```

A `FutureProvider` re-runs every time a watched dependency changes. So every keystroke in the search field updates `noteSearchQueryProvider`, which invalidates this provider, which re-runs the search use case. Riverpod handles request deduplication and cancellation automatically.

### List screen — `notes_list_screen.dart`

```dart
class NotesListScreen extends ConsumerStatefulWidget {
  const NotesListScreen({super.key});

  @override
  ConsumerState<NotesListScreen> createState() => _NotesListScreenState();
}
```

`ConsumerStatefulWidget` is Riverpod's mix-in equivalent for `StatefulWidget` — it grants the state class a `ref` field. We need state here because the search-mode toggle (`_isSearching`) and the search controller (`_searchController`) are local UI concerns that do not belong in a provider.

The build method branches on search mode:

```dart
@override
Widget build(BuildContext context) {
  final notesAsync = _isSearching
      ? ref.watch(noteSearchResultsProvider)
      : ref.watch(notesProvider);

  return Scaffold(
    backgroundColor: kBgPrimary,
    appBar: _buildAppBar(),
    body: notesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: kAccentPurple)),
      error: (e, _) => const Center(
        child: Text(kError, style: TextStyle(color: kTextSecondary)),
      ),
      data: (notes) {
        if (notes.isEmpty) return _buildEmptyState();
        return ListView.builder(...);
      },
    ),
```

Two providers, one screen, one `AsyncValue.when` switch. When the user enters search mode the body re-binds to a different stream of data — no extra branches downstream. The `.when` API forces all three states to be handled; you cannot accidentally render stale data while loading.

The list itself is a vanilla `ListView.builder` with an entry animation:

```dart
itemBuilder: (_, i) => NoteCard(
  note: notes[i],
  onTap: () => _openNote(noteId: notes[i].id),
)
    .animate(delay: Duration(milliseconds: i * 40))
    .fadeIn(duration: 300.ms)
    .slideY(begin: 0.08, end: 0, duration: 300.ms, curve: Curves.easeOut),
```

`.animate()` is from the `flutter_animate` package — it wraps the widget in an animation controller. The chained `.fadeIn().slideY(...)` applies a staggered entry effect (each item starts 40 ms after the previous). This is cosmetic; you can delete it without affecting behaviour.

The FAB is the entry to the editor:

```dart
floatingActionButton: FloatingActionButton(
  onPressed: () => _openNote(),
  backgroundColor: kAccentPurple,
  child: const Icon(Iconsax.add, color: Colors.white),
),
```

`_openNote()` (with no `noteId`) pushes the editor in "create" mode. `_openNote(noteId: id)` pushes it in "edit" mode. The editor decides what to do based on whether it gets an id.

```dart
void _openNote({int? noteId}) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => NoteEditorScreen(noteId: noteId)),
  );
}
```

`Navigator.push` is the same as Spring MVC `redirect:/notes/edit/{id}` — it does not modify the current screen, it pushes a new screen onto the stack. When the editor pops itself (via `Navigator.pop`), the list screen rebuilds because `notesProvider` was invalidated by the save.

The app bar is custom-built to toggle between the title and the search field:

```dart
title: _isSearching
    ? TextField(
        controller: _searchController,
        autofocus: true,
        ...
        onChanged: (q) => ref.read(noteSearchQueryProvider.notifier).state = q,
      )
    : const Text(kNavNotes, ...),
```

`onChanged` writes every keystroke into the search-query provider. `ref.read(...)` (not `watch`) is the correct call here because we are mutating, not subscribing.

The diagnostic-logs IconButton in the actions list is unrelated to notes but lives in this app bar because it is a convenient global entry point.

### Editor screen — `note_editor_screen.dart`

The editor handles both create and update. Branching on `widget.noteId` is the only difference.

```dart
class NoteEditorScreen extends ConsumerStatefulWidget {
  final int? noteId;
  const NoteEditorScreen({super.key, this.noteId});
```

A nullable id is the create/edit signal. If null, we are creating; otherwise editing.

```dart
@override
void initState() {
  super.initState();
  _titleCtrl = TextEditingController();
  _bodyCtrl = TextEditingController();
  _loadNote();
}

Future<void> _loadNote() async {
  if (widget.noteId == null) return;
  final repo = ref.read(noteRepositoryProvider);
  final note = await repo.getNoteById(widget.noteId!);
  if (note == null || !mounted) return;
  _original = note;
  setState(() {
    _titleCtrl.text = note.title;
    _bodyCtrl.text = note.body;
    _colorIndex = note.colorIndex;
    _isPinned = note.isPinned;
  });
}
```

A few Flutter-isms worth flagging:

- `TextEditingController` is the bridge between a `TextField` widget and the current text. It is the equivalent of `<input v-model="...">` in Vue, except you instantiate it manually. It must be `dispose()`d when the state object is torn down — see the `dispose` method below.
- `mounted` is a state-level flag indicating whether this widget is still in the tree. After `await`, the widget could have been popped off; touching `setState` on a disposed widget throws. The `if (!mounted) return;` guard is standard hygiene.
- `_original` is kept around so that `save` knows whether to call `create` or `update`.

The save logic:

```dart
Future<void> _save() async {
  final title = _titleCtrl.text.trim();
  final body = _bodyCtrl.text.trim();
  if (title.isEmpty && body.isEmpty) {
    Navigator.pop(context);
    return;
  }

  setState(() => _isSaving = true);
  final now = DateTime.now();

  try {
    if (_original == null) {
      final note = Note(
        id: 0,
        title: title,
        body: body,
        colorIndex: _colorIndex,
        isPinned: _isPinned,
        createdAt: now,
        updatedAt: now,
      );
      await ref.read(notesProvider.notifier).create(note);
    } else {
      final updated = _original!.copyWith(
        title: title,
        body: body,
        colorIndex: _colorIndex,
        isPinned: _isPinned,
        updatedAt: now,
      );
      await ref.read(notesProvider.notifier).save(updated);
    }
  } finally {
    if (mounted) Navigator.pop(context);
  }
}
```

The early-exit for empty notes mirrors Google Keep's behaviour: if you back out of an empty new note, nothing is saved. The use case would also reject it (`CreateNoteUseCase` throws on `isEmpty`), but doing it here avoids triggering the loading spinner for nothing.

For create, `id: 0` is a sentinel — the model layer will see `id = 0`, treat it as "no id assigned" (Isar auto-increments anything other than a real id), and assign one on insert. For edit, `_original!.copyWith(...)` preserves the original id and `createdAt`.

`ref.read(notesProvider.notifier).create(note)` reaches into the notifier we discussed above. The `try/finally` guarantees the screen always pops, even if the use case throws.

The back button is wired to `_save` rather than the default pop:

```dart
leading: IconButton(
  icon: const Icon(Iconsax.arrow_left, color: kTextPrimary),
  onPressed: _save,
),
```

So leaving the editor saves implicitly — again, the Keep-style UX. If you wanted explicit save buttons, this is the line to change.

The body has two `TextField`s, an `Expanded` body field that fills the rest of the space, a `Divider`, and the color picker at the bottom:

```dart
body: Column(
  children: [
    Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kPaddingScreen),
        child: Column(
          children: [
            TextField(controller: _titleCtrl, ...),
            Expanded(
              child: TextField(
                controller: _bodyCtrl,
                ...
                maxLines: null,
                expands: true,
                ...
              ),
            ),
          ],
        ),
      ),
    ),
    const Divider(color: kGlassBorder, height: 1),
    Padding(
      padding: const EdgeInsets.symmetric(vertical: kSpaceSM),
      child: NoteColorPicker(
        selectedIndex: _colorIndex,
        onColorSelected: (i) => setState(() => _colorIndex = i),
      ),
    ),
    SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
  ],
),
```

`expands: true` on the body `TextField` (combined with `maxLines: null`) makes the field grow to fill the available `Expanded` slot. `MediaQuery.of(context).viewInsets.bottom` returns the keyboard's overlap height; the trailing `SizedBox` lifts the color picker above the keyboard when it appears.

The delete path includes a confirm dialog:

```dart
Future<void> _delete() async {
  if (_original == null) {
    Navigator.pop(context);
    return;
  }
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: kBgSecondary,
      title: const Text(kNoteDeleteConfirm, style: TextStyle(color: kTextPrimary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text(kCancel, ...),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(kDelete, style: TextStyle(color: Colors.red.shade400)),
        ),
      ],
    ),
  );
  if (confirmed == true && mounted) {
    await ref.read(notesProvider.notifier).delete(_original!.id);
    if (mounted) Navigator.pop(context);
  }
}
```

`showDialog<bool>` is the Flutter equivalent of `JOptionPane.showConfirmDialog` — it pushes a modal route and returns the value the dialog popped with. `Navigator.pop(ctx, true)` is "close this dialog and yield `true`".

### Note card — `note_card.dart`

The card has three jobs: render a note, expose slide actions (pin/archive/delete), and forward taps.

```dart
class NoteCard extends ConsumerWidget {
  final Note note;
  final VoidCallback onTap;

  const NoteCard({super.key, required this.note, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardColor = kNoteColors[note.colorIndex % kNoteColors.length];
```

`ConsumerWidget` is the stateless variant of `ConsumerStatefulWidget`. The `ref` here lets the card invoke the notifier directly when its slide actions fire — no need to thread a callback all the way down from the screen.

`note.colorIndex % kNoteColors.length` is defensive modulo: if a future migration adds colors and `colorIndex` exceeds the array length, this avoids a range error.

Slide actions are from the `flutter_slidable` package. The leading pane has a pin/unpin button; the trailing pane has archive and delete:

```dart
return Slidable(
  key: ValueKey(note.id),
  startActionPane: ActionPane(
    motion: const DrawerMotion(),
    children: [
      SlidableAction(
        onPressed: (_) => ref.read(notesProvider.notifier).togglePin(note.id),
        backgroundColor: kAccentPurple,
        foregroundColor: Colors.white,
        icon: note.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
        label: note.isPinned ? 'Unpin' : 'Pin',
        ...
      ),
    ],
  ),
  endActionPane: ActionPane(
    motion: const DrawerMotion(),
    children: [
      SlidableAction(
        onPressed: (_) => ref.read(notesProvider.notifier).toggleArchive(note.id),
        ...
      ),
      SlidableAction(
        onPressed: (_) => _confirmDelete(context, ref),
        ...
      ),
    ],
  ),
```

The `key: ValueKey(note.id)` is critical: the slidable widget needs a stable identity to track its open/closed state across rebuilds. Without it, swiping one card and then triggering a list rebuild would close the wrong card.

Each action's `onPressed` calls the appropriate notifier method directly. The notifier handles logging and state update; the card itself never touches the repository.

The visible body:

```dart
child: GestureDetector(
  onTap: onTap,
  child: Container(
    margin: const EdgeInsets.only(bottom: kSpaceSM),
    padding: const EdgeInsets.all(kPaddingCard),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(kRadiusMD),
      border: Border.all(color: kGlassBorder, width: 0.5),
    ),
    constraints: const BoxConstraints(minHeight: kNoteCardMinHeight),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (note.isPinned) ...[
              const Icon(Icons.push_pin, size: kIconSM, color: kAccentPurple),
              const SizedBox(width: kSpaceXS),
            ],
            Expanded(
              child: Text(
                note.title.isEmpty ? kNoteBody : note.title,
                ...
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
```

`if (note.isPinned) ...[ ... ]` is a "collection if" with a spread — only includes those widgets in the list when the condition is true. The pin icon and its spacing both appear or neither do. This is the Dart-idiomatic way to do conditional UI inside a children list.

When the title is empty, the body's placeholder (`kNoteBody`) is shown in the title slot to avoid an empty header. The body preview is shown below up to four lines:

```dart
if (note.body.isNotEmpty) ...[
  const SizedBox(height: kSpaceXS),
  Text(
    note.body,
    style: const TextStyle(color: kTextSecondary, fontSize: 13, height: 1.4),
    maxLines: 4,
    overflow: TextOverflow.ellipsis,
  ),
],
const SizedBox(height: kSpaceSM),
Text(
  du.formatDate(note.updatedAt),
  style: const TextStyle(color: kTextHint, fontSize: 11),
),
```

`du.formatDate` is the project's relative-time helper ("2 hours ago", "yesterday", "Jan 14").

Delete from the slide-action goes through the same dialog pattern:

```dart
void _confirmDelete(BuildContext context, WidgetRef ref) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: kBgSecondary,
      title: const Text(kNoteDeleteConfirm, ...),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text(kCancel, ...)),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            ref.read(notesProvider.notifier).delete(note.id);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(kNoteDeletedMsg)),
            );
          },
          child: Text(kDelete, style: TextStyle(color: Colors.red.shade400)),
        ),
      ],
    ),
  );
}
```

Note the difference from the editor's delete: this one fires a snackbar on success. The editor pops itself, so it cannot show a snackbar in its own scaffold; the list screen remains visible, so it can.

### Color picker — `color_picker.dart`

A small leaf widget. Pure presentational, stateless.

```dart
class NoteColorPicker extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onColorSelected;

  const NoteColorPicker({
    super.key,
    required this.selectedIndex,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: kPaddingScreen),
        itemCount: kNoteColors.length,
        separatorBuilder: (_, __) => const SizedBox(width: kSpaceSM),
        itemBuilder: (_, i) {
          final isSelected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onColorSelected(i),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: kNoteColors[i],
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? kAccentPurple : kGlassBorder,
                  width: isSelected ? 2.5 : 1,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: kAccentPurple, size: 18)
                  : null,
            ),
          );
        },
      ),
    );
  }
}
```

`ValueChanged<int>` is just a typedef for `void Function(int)` — the standard Flutter signature for "user selected something". The parent (editor screen) passes a closure that updates its own state.

`ListView.separated` is the horizontal variant of `ListView.builder` with automatic separators between items. The horizontal axis makes it scroll left-right.

No Riverpod here. No notifier. This widget is a pure function from props to pixels — the kind of dumb component you would also write in plain React.

## Trace: tap "+" and write a note

Now we follow one full user journey from tap to disk to refresh. The user taps the floating action button, types "Buy milk" in the title, picks a yellow color, taps back, and sees the note appear in the list.

### Step 1 — FAB tap

`NotesListScreen.build` registered:

```dart
floatingActionButton: FloatingActionButton(
  onPressed: () => _openNote(),
  ...
),
```

The closure calls `_openNote()` with no id, which pushes the editor:

```dart
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => NoteEditorScreen(noteId: noteId)),
);
```

`MaterialPageRoute` slides a new screen in from the right. The list screen stays alive but is hidden under the new route.

### Step 2 — Editor mounts

Flutter creates `_NoteEditorScreenState`. `initState` runs:

```dart
@override
void initState() {
  super.initState();
  _titleCtrl = TextEditingController();
  _bodyCtrl = TextEditingController();
  _loadNote();
}
```

`_loadNote()` short-circuits because `widget.noteId == null`. The screen renders with empty controllers, `_colorIndex == 0`, `_isPinned == false`, `_original == null`.

### Step 3 — User types and picks color

Each keystroke updates `_titleCtrl.text` internally. No state notification is needed — the `TextField` and its controller are linked directly.

When the user taps the yellow color in the picker:

```dart
onColorSelected: (i) => setState(() => _colorIndex = i),
```

`setState` schedules a rebuild. On the next frame the picker re-renders with the new selected ring, and the scaffold background updates because `cardBg` was computed from `_colorIndex` in the build method.

### Step 4 — User taps back

The leading button fires `_save`:

```dart
Future<void> _save() async {
  final title = _titleCtrl.text.trim();
  final body = _bodyCtrl.text.trim();
  if (title.isEmpty && body.isEmpty) {
    Navigator.pop(context);
    return;
  }

  setState(() => _isSaving = true);
  final now = DateTime.now();

  try {
    if (_original == null) {
      final note = Note(
        id: 0,
        title: title,
        body: body,
        colorIndex: _colorIndex,
        ...
        createdAt: now,
        updatedAt: now,
      );
      await ref.read(notesProvider.notifier).create(note);
    }
    ...
```

A `Note` entity is constructed with `id: 0` (the sentinel) and the current values. The notifier's `create` is called.

### Step 5 — Notifier.create

```dart
Future<void> create(Note note) async {
  try {
    final id = await CreateNoteUseCase(_repository)(note);
    final created = note.copyWith(id: id);
    AppLogger.I.action('notes', 'create', data: {'id': id, 'len': note.body.length});
    state = AsyncData([...?state.valueOrNull?.where((n) => n.isPinned), created, ...?state.valueOrNull?.where((n) => !n.isPinned)]);
    ref.invalidateSelf();
  } catch (e, s) {
    AppLogger.I.error('notes', 'create failed', error: e, stack: s);
    rethrow;
  }
}
```

`CreateNoteUseCase(_repository)(note)` is constructed and immediately invoked.

### Step 6 — CreateNoteUseCase.call

```dart
Future<int> call(Note note) async {
  if (note.isEmpty) throw const ValidationException('Note cannot be empty');
  return _repository.createNote(note);
}
```

The title is "Buy milk" (non-empty), so `isEmpty` is false. The use case delegates to `_repository.createNote(note)`.

### Step 7 — NoteRepositoryImpl.createNote

```dart
@override
Future<int> createNote(Note note) {
  final model = NoteModel.fromEntity(note);
  return _datasource.putNote(model);
}
```

The entity is converted to a model. `NoteModel.fromEntity` uses cascades to populate every field, including `id = 0` (which Isar will see as auto-increment).

### Step 8 — NoteLocalDatasource.putNote

```dart
Future<int> putNote(NoteModel model) async {
  try {
    return _isar.writeTxn(() => _isar.noteModels.put(model));
  } on IsarError catch (e) {
    throw DatabaseException('Failed to save note', cause: e);
  }
}
```

Isar opens a write transaction, runs `put`, commits, and returns the assigned id (say, `7`). The future resolves with `7`.

### Step 9 — Returns climb back up

- Datasource returns `7`.
- Repository returns `7`.
- Use case returns `7`.
- Notifier captures `id = 7`, builds `created = note.copyWith(id: 7)`.
- Notifier emits a new `AsyncData` with the created note spliced into the list.
- Notifier calls `ref.invalidateSelf()`.

### Step 10 — Provider re-runs

`ref.invalidateSelf()` schedules `NotesNotifier.build()` to run again on the next frame:

```dart
@override
Future<List<Note>> build() async {
  _repository = ref.watch(noteRepositoryProvider);
  return _repository.getAllNotes();
}
```

`getAllNotes()` walks all the way down — repo → datasource → Isar — and returns the canonical sorted list including the new note. This replaces the optimistic state with the database's view of truth.

### Step 11 — Editor pops

Back in `_save`, the `try` block exits and the `finally` runs:

```dart
} finally {
  if (mounted) Navigator.pop(context);
}
```

`Navigator.pop(context)` removes the editor from the route stack. The list screen becomes visible again.

### Step 12 — List rebuilds

The list screen's `build` was already subscribed to `notesProvider` via `ref.watch`. When the provider emitted the new state (after `invalidateSelf` completed), the framework marked the screen dirty. Now that the editor is gone, the framework runs the list's build method:

```dart
final notesAsync = _isSearching
    ? ref.watch(noteSearchResultsProvider)
    : ref.watch(notesProvider);

return Scaffold(
  ...
  body: notesAsync.when(
    loading: () => ...,
    error: (e, _) => ...,
    data: (notes) {
      if (notes.isEmpty) return _buildEmptyState();
      return ListView.builder(...);
    },
  ),
```

`notesAsync` is now `AsyncData([Note(id: 7, ...), ...])`. The `data` branch runs, `ListView.builder` constructs `NoteCard` widgets for each item, and the entry animation plays for the new card.

### Step 13 — Logger emits

In parallel with all of the above, `AppLogger.I.action('notes', 'create', ...)` wrote a structured entry. If the user opens the diagnostics screen from the app bar, they will see:

```
[notes] create {id: 7, len: 9}
```

That is the entire trace: one tap, one screen, one transaction, twelve files touched, zero coupling between layers. The list screen does not know what Isar is. The repository does not know what `AppLogger` is. The use case does not know what a `TextField` is. Each layer holds only the knowledge it strictly needs, which is exactly the Clean Architecture promise — and the same promise you got from Spring's controller/service/repository separation, expressed in Dart and Flutter idioms.
