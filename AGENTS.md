# AI rules for Flutter

You are an expert in Flutter and Dart development. Your goal is to build
beautiful, performant, and maintainable applications following modern best
practices.

## Build, Lint, and Test Commands

### Running the App
```bash
flutter run                    # Run on connected device
flutter run -d <device_id>    # Run on specific device
flutter run --release          # Run in release mode
```

### Building
```bash
flutter build apk              # Build Android APK
flutter build apk --debug     # Build debug APK
flutter build apk --release   # Build release APK
flutter build ios             # Build iOS
flutter build windows         # Build Windows desktop
flutter build web             # Build web version
```

### Linting and Analysis
```bash
flutter analyze               # Run static analysis (linter + analyzer)
```

### Testing
```bash
flutter test                  # Run all tests
flutter test test/           # Run tests in specific directory
flutter test test/file_test.dart         # Run single test file
flutter test test/file_test.dart -n test_name  # Run specific test by name
```

### Code Generation
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Dependencies
```bash
flutter pub get              # Get dependencies
flutter pub add <package>   # Add dependency
flutter pub add dev:<package> # Add dev dependency
```

## Project Structure
* Standard Flutter project with `lib/main.dart` as entry point.
* Tests in `test/` directory, mirroring `lib/` structure.

### Architecture Pattern (MVC/MVVM)
* `controllers/` - Business logic using ChangeNotifier
* `models/` - Data models (Hive persistence)
* `services/` - External integrations (permissions, audio)
* `screens/` - UI pages
* `widgets/` - Reusable UI components

## Code Style Guidelines

### Formatting and Style
* **Line length:** 80 characters or fewer.
* **Case:** `PascalCase` for classes, `camelCase` for members/variables/functions/enums, `snake_case` for files.
* **Strings:** Prefer single quotes (`'` not `"`).
* **Use `const`** constructors whenever possible.
* **Sort imports:** Dart SDK, then packages, then relative. Alphabetically within groups.

### Naming Conventions
* **Avoid abbreviations** - use `audioPlayer` not `ap`.
* **Methods:** Use verbs (`getSongs()`, `playAudio()`).
* **Variables:** Use nouns (`currentSong`, `isPlaying`).
* **Booleans:** Prefix with `is`, `has`, `can`, `should`.

### Type Annotations
* **Always declare return types** for functions/methods.
* **Use explicit types** for public APIs.
* **Prefer `final`** over `var` when value doesn't change.
* **Use `late`** sparingly - only when initialization is guaranteed.

### Error Handling
* **Never fail silently** - always handle with try-catch.
* **Use specific exceptions** - catch `FileSystemException`, not generic `Exception`.
* **Provide meaningful error messages** - include context.
* **Use Result types** for operations that can fail.

### Null Safety
* **Avoid `!`** unless absolutely certain value is non-null.
* **Use `?.`** for nullable access.
* **Use `??`** for default values.
* **Prefer early returns** with null checks.

### Functions
* **Keep functions short** - under 20 lines.
* **Single responsibility** - each function does one thing well.
* **Use arrow syntax** for simple one-liners.

## Flutter Best Practices
* **SOLID Principles:** Apply throughout.
* **Composition over Inheritance:** Favor composition.
* **Immutability:** Prefer immutable data structures.
* **State Management:** Use built-in solutions (Streams, ValueNotifier, ChangeNotifier).
* **Navigation:** Use `go_router`.
* **List Performance:** Use `ListView.builder` for long lists.
* **Const Constructors:** Use for widgets whenever possible.

## State Management (Provider)
Use ChangeNotifier with Provider for state management:
```dart
// In main.dart
ChangeNotifierProvider(create: (_) => AudioPlayerController())
ChangeNotifierProvider(create: (_) => SettingsController())

// In widgets
final controller = context.read<AudioPlayerController>();
final state = context.watch<AudioPlayerController>();
```

## Routing (go_router)
Configure routes in `lib/router/app_router.dart`:
```dart
final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/player', builder: (_, __) => const PlayerScreen()),
  ],
);
```

## Hive Persistence
Models use Hive with generated adapters:
```dart
@HiveType(typeId: 0)
class Song extends HiveObject {
  @HiveField(0)
  final String title;
}
// Run: dart run build_runner build --delete-conflicting-outputs
```

## Testing
* **Convention:** Follow Arrange-Act-Assert pattern.
* **Unit Tests:** Use `package:test` for controllers and services.
* **Widget Tests:** Use `package:flutter_test` for widgets and screens.
* **Mocks:** Prefer fakes/stubs over mocks.

## Key Dependencies
* `go_router` - Navigation
* `provider` - State management
* `just_audio` - Audio playback
* `hive` / `hive_flutter` - Local storage
* `google_fonts` - Typography

## Lint Rules
The project uses these rules in `analysis_options.yaml`:
```yaml
linter:
  rules:
    prefer_single_quotes: true
    avoid_print: false
    use_key_in_widget_constructors: true
    prefer_const_constructors: true
    always_declare_return_types: true
    prefer_final_fields: true
    prefer_final_locals: true
```
