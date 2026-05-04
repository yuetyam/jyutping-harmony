# AGENTS.md

## Project summary

- HarmonyOS Stage-model ArkTS app for the Jyutping based Cantonese keyboard.
- The repo contains a single `entry` module plus `AppScope` metadata/resources.
- The shipped app has two main surfaces:
  - the regular app UI (`entry/src/main/ets/pages`)
  - the input-method extension (`entry/src/main/ets/InputMethodExtensionAbility`)

## Repository map

- `AppScope/app.json5`: bundle metadata.
- `entry/src/main/module.json5`: declares `EntryAbility`, `EntryBackupAbility`, and `InputMethodExtensionAbility`.
- `entry/src/main/ets/pages/`: tabbed app screens such as Home, Romanization, Cantonese lookup, About, and Privacy.
- `entry/src/main/ets/InputMethodExtensionAbility/`: keyboard runtime. `InputController.ets` is the main coordination point for panel lifecycle, candidates, preferences, audio, haptics, and database access.
- `entry/src/main/ets/search/`: SQLite-backed Cantonese/Jyutping lookup helpers and view models.
- `entry/src/main/resources/`: colors, localized strings, raw assets, route/profile JSON, and bundled SQLite databases.
- `entry/src/test/`: local Hypium tests.
- `entry/src/ohosTest/`: device-side `ohosTest` module.

## Tooling expectations

- There is **no** `.editorconfig`, **no** npm script entrypoint, and **no** checked-in `hvigorw` wrapper.
- Build configuration lives in:
  - `build-profile.json5`
  - `hvigorfile.ts`
  - `entry/build-profile.json5`
  - `entry/hvigorfile.ts`
- Prefer DevEco Studio for build/run/test tasks unless the environment already has HarmonyOS CLI tools installed.
- If using CLI, first confirm `ohpm`/`hvigor` exist on the host; do not invent replacement scripts.
- Keep `code-linter.json5` in mind: linting targets `**/*.ets` and explicitly ignores `src/test`, `src/ohosTest`, `src/mock`, `oh_modules`, and build outputs.

## Code style and conventions

- Match the existing ArkTS style:
  - 4-space indentation
  - semicolons
  - double-quoted strings
  - explicit type annotations are common and preferred
- File, component, and model names are generally PascalCase.
- Keep imports explicit from `@kit.*` packages rather than hiding platform dependencies behind new wrappers unless there is a strong reason.
- Error paths are usually logged with `console.error(...)` or `hilog.error(...)`; avoid silent failures.
- Follow existing naming and storage patterns instead of introducing parallel state containers.

## Localization and copy

- User-facing text is localized. Relevant string resources live under:
  - `AppScope/resources/*/element/string.json`
  - `entry/src/main/resources/*/element/string.json`
- Supported locales include `en_US`, `zh_CN`, `zh_HK`, and `zh_TW`.
- If you add or rename user-visible strings, update the locale files consistently instead of changing only one language.
- Existing README and in-app copy use Cantonese/Chinese phrasing in several places; preserve that tone when editing visible text.

## Keyboard-specific notes

- `entry/src/main/ets/InputMethodExtensionAbility/InputController.ets` is the highest-impact file in the repo. Changes there can affect:
  - candidate generation
  - buffer/session state
  - preview text behavior
  - keyboard layout switching
  - audio and haptic feedback
  - database bootstrapping
- Keyboard settings are stored in `kbsettings` preferences with keys such as `audio`, `haptic`, and `charset`.
- The main app privacy gate uses a separate shared preference value (`privacy`) in `pages/Index.ets` and `pages/PrivacyScreen.ets`.
- When changing persisted keys or value semantics, add a migration path or preserve backward compatibility.

## Bundled data and database coupling

- Bundled databases live in `entry/src/main/resources/resfile/`, including:
  - `imedb.sqlite3`
  - `appdb.sqlite3`
- `InputController.ets` copies the IME database into the app database directory using a **versioned filename** (`imedb-20260311-tmp.sqlite3` at the time of writing).
- That version string is coupled across:
  - `copyKeyboardDatabase(...)`
  - `obtainStore()`
  - `deleteOldDatabases(...)`
- If you refresh the bundled IME database, update all of those places together. Do not change only one reference.

## Resources

- Raw keyboard assets live under `entry/src/main/resources/rawfile/` (`click.m4a`, `modifier.m4a`, `delete.m4a`, `confusion.json`).
- UI/profile resources live under `entry/src/main/resources/base/` plus locale/theme overrides.
- Before removing or renaming a resource, search for all `$r(...)`, `resourceManager.getRawFd(...)`, and profile JSON references.

## Testing guidance

- The repo includes Hypium test scaffolding in `entry/src/test/` and `entry/src/ohosTest/`.
- Current tests appear to be mostly template-level smoke tests, so do not assume they cover keyboard/search behavior.
- For non-trivial logic changes, prefer adding focused tests around pure/helper logic when possible, especially in model/search code.

## Safety notes

- `build-profile.json5` and `entry/build-profile.json5` contain environment-specific signing configuration. Do not rewrite signing paths, passwords, aliases, or certificate settings unless the task is explicitly about signing/release setup.
- This repo may already have local build or signing differences; keep changes surgical and avoid “cleanup” edits unrelated to the requested task.
