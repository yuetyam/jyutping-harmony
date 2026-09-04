# Preparing

`preparing` builds the SQLite databases bundled with the HarmonyOS app from the source text files in `res`.

The generated products match the schemas and data produced by the iOS database preparation project:

- `app.sqlite3` matches the iOS `app.sqlite3` database.
- `ime.sqlite3` matches the iOS `mobile.sqlite3` database.

The macOS `desktop.sqlite3` database is not generated. SQLite optimization steps such as changing the page size, `VACUUM`, and `ANALYZE` are also intentionally omitted.

## Requirements

- Rust 1.85 or later with Cargo
- The SQLite library supplied by the operating system (`libsqlite3` on macOS and Linux, or `winsqlite3.dll` on Windows)

The project has no third-party Rust dependencies.

## Generate Databases

Run the generator from this directory:

```sh
cargo run --release
```

The completed databases are written atomically to:

```text
../entry/src/main/resources/resfile/app.sqlite3
../entry/src/main/resources/resfile/ime.sqlite3
```

The output paths are fixed and do not depend on the current working directory.

## Verification

Run the Rust checks with:

```sh
cargo fmt --check
cargo test
cargo clippy --all-targets -- -D warnings
```

Generated databases can be checked with the SQLite command-line tool:

```sh
sqlite3 ../entry/src/main/resources/resfile/app.sqlite3 "PRAGMA integrity_check;"
sqlite3 ../entry/src/main/resources/resfile/ime.sqlite3 "PRAGMA integrity_check;"
```
