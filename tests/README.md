# Engine regression checks

Run `node tests/engines.cjs` with Node 24 or newer. The runner uses the TypeScript compiler bundled with DevEco Studio; set `DEVECO_STUDIO_HOME` to its `Contents` directory if it is not installed under `~/Applications`.

The tests execute the actual ArkTS engine files after transpilation, with Node SQLite adapting the synchronous RDB result-set interface. They use the bundled IME database read-only, check lookup results and consumed input, and fail on query errors or leaked result sets. This validates engine logic and SQLite queries; it does not replace ArkTS compilation or HarmonyOS device testing of the RDB adapter, preview, or touch interactions.

Build the app using the checked-in Hvigor wrapper. Optional `COREIME_REFERENCE` accepts a JSON fixture exported from Swift CoreIME against the same database: keys are input strings (prefixed with `nine:` for nine-key input, `pinyin:` for Pinyin, or `pinyin-nine:` for nine-key Pinyin); values are ordered lexicons with `text`, `romanization`, `input`, `mark`, and `number`. The comparison normalizes reverse-lookup duplicates to the existing HarmonyOS contract.
