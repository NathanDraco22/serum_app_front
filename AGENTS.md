#### 🎯 Frontend Commands (Dart / Flutter)
*   `onion dart <entity>`: Generates the client data layer: Models, DataSource, and Repository. (Symmetric equivalent to backend `crud`).
*   `onion dart-cubit <entity>`: Generates BLoC state management classes (`Read` and `Write` Cubits) with their state hierarchies.
*   `onion flutter-module <entity>`: Creates a complete UI and logic feature module: `cubit/`, `dialog/`, `view/`, and `widgets/` folders with ready-to-use stubs.
*   `onion dart-model <entity>`: Generates only the 4 typed Dart models (`Base`, `Create`, `Update`, `InDb`).
*   `onion dart-view <entity>`: Generates a basic screen view (StatelessWidget).
*   `onion barrel <directory>`: Generates a barrel file (`export.dart`) in a given directory, re-exporting all `.dart` files inside.

## 🎯 4. Frontend Standards (Flutter / Dart)

### 4.1 Folder Organization (Frontend)
*   **Feature Modules**: `lib/src/modules/<modulo_singular>/`. Includes `cubit/` folder, local dialogs, main `view/` screens, and local widgets.
*   **DataSources**: `lib/src/data/`.
*   **Repositories**: `lib/src/domain/repositories/`.
*   **Models**: `lib/src/domain/models/`.
*   **Shared Cubits**: Cubits affecting multiple feature areas live in `lib/src/cubits/`.

### 4.2 Frontend Layer Flow
```
View (UI) ➔ Cubit (State Logic) ➔ Repository (Domain/Caché) ➔ DataSource (Params/Source Config) ➔ Service (Infrastructure/Output)
```

1.  **View (UI)**: Triggers actions in the Write Cubit upon data mutation, or listens to the Read Cubit states to build lists/screens.
2.  **Cubit**: State manager layer. Communicates synchronously or asynchronously with the repository and emits structured states (`Initial`, `Loading`, `Success`, `Refreshing`, `Error`).
3.  **Repository**: Maps raw JSON responses to strongly-typed Dart objects, maintains an in-memory cache, and acts as the reactive event bus when utilizing `ReactiveRepository`.
4.  **DataSource**: Encapsulates specific parameter requirements to consume a data stream or resource (e.g., base path `_endpoint`, channel parameters, or local keys). Delegates actual query/mutation execution to the underlying Service.
5.  **Service**: Any technical infrastructure or low-level component acting as a data output, persistence channel, or physical medium outside the app's pure logic. This can be a network client (e.g., REST HTTP client `HttpService`, Websockets), local data storage (e.g., Hive, SQLite), or hardware/OS APIs (e.g., clipboard access, physical printing services, GPS, camera, sensors).

### 4.3 Client Data Layer (DataSources & Repositories)
*   **DataSource (Singleton)**: Stores config parameters (like `_endpoint`). Its only role is delegating the physical request to the sub-service (e.g., via `with HttpService` mixin or an injected client instance) and returning raw payloads (`Map<String, dynamic>`). **Must not map JSON to objects**.
*   **Repository (Singleton)**: Maps raw payloads using `fromJson`, manages in-memory data (`List<Model> _list`), and updates local states upon creation, modification, or deletion to maintain instantaneous UI reactiveness without redundant channel requests.

### 4.4 Post-Generation Manual Adjustments (`onion dart`)
After executing `onion dart <entity>`, add the missing package imports manually:
*   **Inside DataSource (`*_data_source.dart`)**:
    ```dart
    import 'package:[project_name]/src/services/http_service.dart';
    import 'package:[project_name]/src/tools/http_tool.dart';
    ```
*   **Inside Repository (`*_repository.dart`)**:
    ```dart
    import 'package:[project_name]/src/data/[entities]_data_source.dart';
    import 'package:[project_name]/src/domain/models/[entity]_model.dart';
    import 'package:[project_name]/src/domain/responses/list_response.dart';
    ```

---

### 4.5 State Management: Standard vs Reactive Cubit

Mutations in UI lists can be coordinated using one of these two approaches:

#### 🅰️ Standard / Manual Approach (UI-Coordinated)
Cubits remain isolated, and the UI coordinates state synchronization:
1.  The main screen wraps buttons/dialogs inside a `BlocListener<WriteEntityCubit, WriteEntityState>`.
2.  Upon detecting success (`ItemCreated`, `ItemUpdated`, `ItemDeleted`), the UI synchronously calls the `ReadEntityCubit` to mutate the cache:
    ```dart
    // UI BlocListener Example
    listener: (context, state) {
      if (state is ItemCreated) {
        context.read<ReadEntityCubit>().markItemCreated(state.item);
      }
    }
    ```

#### 🅱️ Reactive Approach (`ReactiveRepository`)
Decouples UI coordination by managing updates at the Repository layer via streams:
1.  The repository mixes in `ReactiveRepository<T>` and notifies listeners upon successful actions:
    ```dart
    class UsersRepository with ReactiveRepository<UserInDb> {
      Future<UserInDb> createUser(CreateUser createUser) async {
        final result = await usersDataSource.createUser(createUser.toJson());
        final user = UserInDb.fromJson(result);
        notifyItemCreated(user); // Emits RepoItemCreated
        return user;
      }
    }
    ```
2.  The `ReadCubit` listens to the repository's `eventStream` directly in its constructor and auto-updates the state:
    ```dart
    class ReadUserCubit extends Cubit<ReadUserState> {
      ReadUserCubit({required this.usersRepository}) : super(ReadUserInitial()) {
        usersRepository.eventStream.listen((event) {
          if (event is RepoItemCreated<UserInDb>) markUserCreated(event.item);
          if (event is RepoItemUpdated<UserInDb>) markUserUpdated(event.item);
          if (event is RepoItemDeleted<UserInDb>) markUserDeleted(event.item);
        });
      }
      final UsersRepository usersRepository;
    }
    ```

### 4.6 Post-Generation Manual Adjustments in Cubits (`onion dart-cubit`)
1.  **Correct Model Import**: Replace `import 'package:test_entity_model.dart';` with the project-specific path.
2.  **Inject Repository**: Add the repository field and declare it in the Cubit constructor.
3.  **Align Model Types**: The CLI generates Cubit methods using a generic entity class name (e.g., `TestEntity` or `Entity`). You must adjust these signatures to match your concrete models (e.g., use `EntityInDb` for lists/returns, `CreateEntity` for creations, and `UpdateEntity` for updates).
4.  **Closed verification**: In async operations (`getAll()`, `getById()`), verify `if (isClosed) return;` before calling `emit` to prevent memory leaks if the widget was unmounted.

---

### 4.7 UX Premium in List Loading (Refreshing State)
To avoid flashing large loading indicators and erasing user lists during searches or filters, use a discrete top loader:
*   If the state is already `Success`, `getAll()` should emit the intermediate **`Refreshing`** state (inheriting from `Success` and keeping items in memory).
*   The UI displays a top `LinearProgressIndicator` while leaving the existing list visible in the background.
*   **CLI Support**: This `Refreshing` state (e.g., `ReadEntityRefreshing`) and its `.fromSuccess` factory **are automatically created** by `onion dart-cubit`, providing a premium UX scaffolding out of the box.

---

### 4.8 View Pattern and BlocProvider (Module Entry Point)
To make Cubits available across the module's sub-tree without passing variables, the main module entry widget must act as the provider.

#### View Layout Rules:
1.  **Entry Point (Screen/View)**: A public `StatelessWidget` mapping to the router. It fetches the Repository and wraps the sub-tree inside a `MultiBlocProvider` or `BlocProvider`, immediately triggering the initial load via cascade operator (`..getAll()`).
2.  **Child Hierarchy**: The direct child must be a private layout wrapper (e.g., `_RootScaffold`) followed by the content body (`_Body`).
3.  **Context Access**: Sub-widgets, dialogs, and loaders can query Cubits from context via `context.read<ReadEntityCubit>()` or `context.read<WriteEntityCubit>()`.

#### View Structure Example:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:[project_name]/src/domain/repositories/repositories.dart';
import 'package:[project_name]/src/modules/[module]/cubit/read_[entity]_cubit.dart';
import 'package:[project_name]/src/modules/[module]/cubit/write_[entity]_cubit.dart';

// 1. Public Entry Point (Dependency Injection)
class EntitiesScreen extends StatelessWidget {
  const EntitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<EntitiesRepository>(); 
    
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ReadEntityCubit(
            repository: repository,
          )..getAll(), // Cascaded call for initial data load
        ),
        BlocProvider(
          create: (context) => WriteEntityCubit(
            repository: repository,
          ),
        ),
      ],
      child: const _RootScaffold(),
    );
  }
}

// 2. Private Module Scaffold
class _RootScaffold extends StatelessWidget {
  const _RootScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entities Catalog'),
      ),
      body: const _Body(),
    );
  }
}

// 3. View Body (Listens to States)
class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReadEntityCubit, ReadEntityState>(
      builder: (context, state) {
        if (state is ReadEntityLoading || state is ReadEntityInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ReadEntityError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        
        state as ReadEntitySuccess;
        final items = state.items;

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              title: Text(item.name),
              onTap: () {
                // Diaglogs opened from here inherit context and can read Cubits
                showEntityDetailDialog(context, item); 
              },
            );
          },
        );
      },
    );
  }
}
```

---

## 🛠️ 5. Tools Layer (Utilities)

In both the backend (utility modules) and frontend (`lib/src/tools/` or equivalent), the `tools` folder enforces strict design rules:
*   **Purpose**: Houses date parsers, UI formatters, UUID generators, and global constants.
*   **Rule of Gold**: No class or function inside `tools` may contain business logic, invoke HTTP API calls, or write to database engines. They must be pure functions or pure infrastructure controllers (such as input formatters or physical print drivers).

---

## 🔍 6. Static Analysis (QA)

Before marking any task as complete, developers must run the static checkers locally and resolve all errors/warnings:

### 🐍 Python Backend Projects
Use `uv run` in the backend root directory for portable verification:
```powershell
# Check lints and formatting
uv run ruff check

# Check strict static typing
uv run ty check
```

### 🎯 Flutter / Dart Projects
```powershell
flutter analyze
```