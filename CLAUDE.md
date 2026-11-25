# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

KarVocab — a Flutter app for learning English vocabulary with spaced repetition (SM-2) and AI-generated words (Gemini). University project for course INT1449 (Nhóm 03, PTIT). The team works in Vietnamese: UI strings, code comments, and docs are in Vietnamese. Keep that convention.

The repo root is **not** the Flutter project. All app code lives in `karvocab_flutter/`. Open or run that folder; opening the root in Android Studio gives a plain Java module with no Flutter run configuration.

## Commands

Run from `karvocab_flutter/`:

```bash
flutter pub get
flutter analyze                       # rubric target: 0 errors, 0 warnings
flutter test                          # rubric target: >= 15 tests
flutter test test/fe1_track_a_unit_test.dart                 # single file
flutter test --plain-name "Màn 02" test/fe1_track_a_widget_test.dart   # tests whose name contains the given text
flutter run -d emulator-5554          # Android emulator (first Gradle build is slow)
flutter run -d chrome                 # fastest way to check UI
```

Android build setup is in `android/settings.gradle.kts` (AGP 9.3.1, Kotlin 2.4.20, Gradle wrapper 9.7.1). Flutter prints deprecation warnings if AGP or Kotlin fall below the versions it supports.

## Architecture

The layers are `lib/core` → `lib/data` → `lib/presentation`. There is **no bloc package and no `domain/` layer**. State management is plain `ChangeNotifier` plus `ListenableBuilder`.

- **Stores/repositories are singletons that can be injected.** `CollectionStore.instance` and `AuthRepository.instance` are global `ChangeNotifier`s. Screens accept an optional `store` / `authRepository` constructor parameter and fall back to the singleton (`widget.store ?? CollectionStore.instance`). Tests rely on this: they inject fresh instances built from `MockVocabData.seedCollections()` / `seedVocabularies()` (in `test/fixtures/mock_vocab_data.dart`) with `latency: Duration.zero`. Keep this pattern for any new screen that reads state.
- **Offline by default, data saved on the device.** `main()` sets `LocalStore.app = PrefsLocalStore` (`shared_preferences`) before any store is touched; stores persist in their `notifyListeners` override. The app starts empty: there is no seed data in `lib/`, sample data lives only in `test/fixtures/`. Tests default to `MemoryLocalStore`, so each run starts clean. `CollectionStore.simulateNetworkError` still exercises Error State. The demo account (`AuthRepository.demoEmail` / `demoPassword`) also starts empty.
- **Optional backend.** Passing `--dart-define=API_BASE_URL=...` enables `ApiClient`: login/register/social/logout and AI generation go to the NestJS backend in `backend/`; everything else stays local. AI generation exists **only** through the backend: there is no offline word bank, and without a backend session Màn 13 shows why and disables the button. The team builds the frontend against the backend contract and does not invent data in the app; validation limits follow the backend DTOs. Doc comments say "Sprint 3" will replace method bodies with calls to the REST API in `docs/karvocab/BE-SPECIFICATION.md`, **keeping the method signatures unchanged**. Don't change public signatures casually.
- **Integration contract between the two FE tracks.** Track A (FE1: auth, collections/library, profile, settings) owns `CollectionStore` and the auth screens. Track B (FE2: AI vocab, quiz, dashboard) is not built yet. `MainShellScreen` has placeholder tabs for Home and Practice. Track B must add words only through `CollectionStore.addWords(collectionId, words)` (FE spec §5.1). Quiz results go through a future `dashboardStore.recordSessionResult(summary)`.
- **Screen numbering.** Code comments and test group names refer to screens by number from the FE spec ("Màn 02" = Login, "Màn 15" = Profile, etc.). The full list of 28 screens and the validation rules for each are in `docs/karvocab/FE-SPECIFICATION.md` §2 and §4.

## Rules from the spec / grading rubric

These rules come from `docs/karvocab/FE-SPECIFICATION.md` §6 and the README. The spec was written in React Native terms (`src/features/...`, `tokens.ts`). For Flutter they translate to the following:

- Use design tokens only: `core/constants/app_colors.dart`, `core/constants/app_dimensions.dart`, `core/theme/app_typography.dart`. Don't hardcode hex colors or font sizes in widgets. The tokens were extracted from the team's Figma file `KarVocab`.
- Every touch target (buttons, inputs) must be at least 48dp. `AppButton` and `AppTextField` are 52dp.
- Every list screen needs Loading, Empty (Axolotl illustration + CTA), and Error (friendly message + "Thử lại" retry) states. Use the widgets in `core/widgets/state_widgets.dart`.
- `AppTypography` uses `fontFamily: 'Nunito'`, but **no font is bundled in `pubspec.yaml`**. The app falls back to the platform font until Nunito assets are added. This is one reason the UI doesn't yet match Figma.
- `karvocab_flutter/docs/ai/prompt_log.md` is the graded AI-usage log (rubric criterion 5). AI-assisted work sessions are recorded there.
