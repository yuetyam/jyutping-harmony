// Run with Node 24+ and DevEco Studio's TypeScript compiler (no npm dependencies).
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const { DatabaseSync } = require("node:sqlite");
const studio = process.env.DEVECO_STUDIO_HOME || path.join(process.env.HOME, "Applications/DevEco-Studio.app/Contents");
const ts = require(path.join(studio, "tools/ohpm/node_modules/typescript/lib/typescript.js"));
require.extensions[".ets"] = (module, filename) => {
    const source = fs.readFileSync(filename, "utf8");
    const output = ts.transpileModule(source, { compilerOptions: { target: ts.ScriptTarget.ES2020, module: ts.ModuleKind.CommonJS } }).outputText;
    module._compile(output, filename);
};
const root = path.resolve(__dirname, "../entry/src/main/ets/InputMethodExtensionAbility");
const load = (name) => require(path.join(root, "model", name + ".ets"))[name];
const EngineCode = load("EngineCode");
const Engine = load("Engine");
const Segmenter = load("Segmenter");
const PinyinSegmenter = load("PinyinSegmenter");
const PinyinResearcher = load("PinyinResearcher");
const NineKeyEngine = load("NineKeyEngine");
const NineKeyPinyinResearcher = load("NineKeyPinyinResearcher");
const StructureResearcher = load("StructureResearcher");
const PlainText = load("PlainText");
const ExtraEntry = load("ExtraEntry");
const SymbolResearcher = load("SymbolResearcher");
const CharCode = load("CharCode");
const VirtualInputKey = load("VirtualInputKey");
const { Combo } = require(path.join(root, "ninekey/Combo.ets"));
const keys = (text) => Array.from(text).map((char) => {
    const key = char === "'" ? VirtualInputKey.apostrophe : VirtualInputKey.matchVirtualKey(CharCode.virtualKeyInputCode(char));
    assert.ok(key, char);
    return key;
});
const combos = (text) => Array.from(text).map((char) => Object.values(Combo).find((combo) => combo.digit === Number(char)));
const db = new DatabaseSync(path.resolve(__dirname, "../entry/src/main/resources/resfile/ime.sqlite3"), { readOnly: true });
let opened = 0;
const store = {
    querySqlSync(sql, args = []) {
        const statement = db.prepare(sql);
        statement.setReturnArrays(true);
        const rows = statement.all(...args);
        let index = -1;
        opened++;
        return {
            goToFirstRow() { index = 0; return rows.length > 0; },
            goToNextRow() { return ++index < rows.length; },
            getLong(column) { return Number(rows[index][column]); },
            getString(column) { return String(rows[index][column]); },
            close() { opened--; }
        };
    }
};
// Fail on caught database errors rather than accepting silently empty suggestions.
console.error = (...args) => { throw new Error(args.join(" ")); };
const suggest = (text) => Engine.suggest(keys(text), Segmenter.segment(keys(text), store), store);
assert.equal(EngineCode.radix100Overflowed([]), 0n);
assert.equal(EngineCode.decimalOverflowed(Array(20).fill(9)), 7766279631452241919n);
assert.equal(EngineCode.radix100Overflowed(Array(12).fill(45)), -766174822515915311n);
assert.equal(CharCode.charCode("abcdefghi"), undefined); // InputMemory's encoding is unchanged.
for (const [input, word, romanization] of [["a", "啊", "aa3"], ["m", "唔", "m4"], ["ngo", "我", "ngo5"], ["ngoxx", "我", "ngo5"], ["ngo5", "我", "ngo5"], ["nei'hou", "你好", "nei5 hou2"], ["ngo'", "我", "ngo5"]]) {
    assert.ok(suggest(input).some((item) => item.text === word && item.romanization === romanization && item.input === input), input);
}
assert.equal(suggest("'ngo").length, 0);
assert.ok(!suggest("ngoxx").some((item) => item.romanization === "ngo4"));
assert.ok(suggest("ngomuk").some((item) => item.text === "我木" && item.number > 1000000));
for (const input of ["nei5hou", "neihou2", "nei5hou2", "nei5hou2a", "ngo55", "nei5hou2aa3", "n'h", "n'h'", "n'e'i", "nei'hou'", "n'e'i'h", "nei5'hou2"]) {
    for (const item of suggest(input)) assert.ok(item.inputCount > 0 && item.inputCount <= input.length, input);
}
for (const input of ["ngo", "ngaam", "mama", "mami", "neihou", "heung gong yan"]) {
    const plain = input.replace(/ /g, "");
    assert.ok(Segmenter.segment(keys(plain), store).length > 0, plain);
}
assert.ok(ExtraEntry.search(keys("depje")).some((item) => item.text === "嗒嘢"));
assert.ok(ExtraEntry.nineKeySearch(combos("33753")).some((item) => item.text === "嗒嘢"));
assert.ok(NineKeyEngine.suggest(combos("646"), store).some((item) => item.text === "我"));
for (const input of ["nihao", "xian", "xi'an", "zhongguo"]) {
    assert.ok(PinyinResearcher.suggest(keys(input), PinyinSegmenter.segment(keys(input), store), store).length > 0, input);
}
assert.ok(NineKeyPinyinResearcher.suggest(combos("64426"), store).some((item) => item.text === "你好"));
assert.ok(StructureResearcher.suggest(keys("mukmuk"), Segmenter.segment(keys("mukmuk"), store), store).some((item) => item.text === "林"));
const plain = db.prepare("SELECT input, word FROM plain_text_table WHERE length(input) > 9 LIMIT 1").get();
assert.ok(PlainText.search(keys(plain.input), store).some((item) => item.text === plain.word));
assert.ok(PlainText.queryNineKey(combos(EngineCode.nineKey(plain.input)), store).some((item) => item.text === plain.word));
const symbol = db.prepare("SELECT romanization FROM symbol_table WHERE complexity < 10 LIMIT 1").get().romanization.replace(/[1-6 ]/g, "");
assert.ok(SymbolResearcher.search(keys(symbol), Segmenter.segment(keys(symbol), store), store).length > 0);
assert.ok(SymbolResearcher.searchNineKey(combos(EngineCode.nineKey(symbol)), store).length > 0);
// Long and negative codes must round-trip through SQLite without Number conversion.
for (const row of db.prepare("SELECT word, romanization, CAST(spell AS TEXT) AS spell, CAST(spell_9key AS TEXT) AS nine, CAST(complexity AS TEXT) AS complexity FROM lexicon_core WHERE spell < 0 AND char_count = 3 LIMIT 12").all()) {
    const text = row.romanization.replace(/[1-6 ]/g, "");
    assert.equal(EngineCode.text(text), row.spell);
    assert.equal(EngineCode.nineKey(text), row.nine);
    assert.ok(suggest(text).some((item) => item.text === row.word && item.romanization === row.romanization), text);
}
for (const row of db.prepare("SELECT input, word FROM plain_text_table WHERE letter_count >= 16 LIMIT 12").all()) {
    const digits = Array.from(row.input).map((char) => CharCode.nineKeyInterCode(char)).join("");
    assert.ok(PlainText.search(keys(row.input), store).some((item) => item.text === row.word));
    assert.ok(PlainText.queryNineKey(combos(digits), store).some((item) => item.text === row.word));
}
const queryPlan = db.prepare("EXPLAIN QUERY PLAN SELECT word FROM lexicon_core WHERE spell = CAST(? AS INTEGER) AND complexity = CAST(? AS INTEGER)").all("-1", "333");
assert.ok(queryPlan.some((item) => item.detail.includes("ix_lexicon_core_spell")));
const BasicInputEvent = load("BasicInputEvent");
const { KeyboardCase } = require(path.join(root, "model/KeyboardCase.ets"));
assert.equal(BasicInputEvent.normalizedPreviewMark(keys("ngoxxnei5").map((key) => new BasicInputEvent(key, KeyboardCase.uppercased))), "NGO5 NEI5");
const Lookup = load("Lookup");
assert.deepEqual(Lookup.romanizations("我\u{10ffff}", store), []);
assert.ok(Lookup.romanizations("我木", store).includes("ngo5 muk6"));
const Converter = load("Converter");
const EngineLexicon = load("EngineLexicon");
const memory = EngineLexicon.make("我", "ngo5", "ngo", -1);
const symbolItem = { ...memory, type: 3, text: "😀", note: "我" };
assert.deepEqual(Converter.dispatch([memory], [], [symbolItem], [memory]).map((item) => item.text), ["我", "😀"]);
if (process.env.COREIME_REFERENCE) {
    const reference = JSON.parse(fs.readFileSync(process.env.COREIME_REFERENCE, "utf8"));
    const differences = [];
    for (const [input, expected] of Object.entries(reference)) {
        let actual;
        if (input.startsWith("nine:")) actual = NineKeyEngine.suggest(combos(input.slice(5)), store);
        else if (input.startsWith("pinyin-nine:")) actual = NineKeyPinyinResearcher.suggest(combos(input.slice(12)), store);
        else if (input.startsWith("pinyin:")) {
            const k = keys(input.slice(7));
            actual = PinyinResearcher.suggest(k, PinyinSegmenter.segment(k, store), store);
        } else actual = suggest(input);
        const normalize = (item) => ({ text: item.text, romanization: item.romanization, input: item.input, mark: item.mark, number: item.number });
        if (JSON.stringify(actual.map(normalize)) !== JSON.stringify(expected.filter((item, index, items) => !input.startsWith("pinyin") || items.findIndex((other) => other.text === item.text && other.romanization === item.romanization) === index).map(normalize))) differences.push({ input, expected: expected.length, actual: actual.length, firstExpected: expected.slice(0, 3), firstActual: actual.slice(0, 3) });
    }
    if (differences.length > 0) console.log(JSON.stringify(differences, null, 2));
    else console.log(`Swift parity passed for ${Object.keys(reference).length} input cases (reverse-lookup duplicates normalized)`);
    assert.equal(differences.length, 0, "Swift reference parity");
}
assert.equal(opened, 0, "Every result set closes");
assert.equal(db.prepare("PRAGMA integrity_check").get().integrity_check, "ok");
console.log("Engine database regressions passed");
db.close();
