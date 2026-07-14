import { preferences, relationalStore } from "@kit.ArkData";
import { BusinessError } from "@kit.BasicServicesKit";
import { Candidate } from "./Candidate";
import { FallbackLexiconHelper } from "./FallbackLexiconHelper";
import { FallbackT2SHelper } from "./FallbackT2SHelper";
import { VirtualInputKey } from "./VirtualInputKey";
import { Lexicon } from "./Lexicon";
import { LexiconType } from "./LexiconType";
import { Segmentation, Scheme, Segmenter } from "./Segmenter";
import { CharCode } from "./CharCode";
import { Combo } from "../ninekey/Combo";
import { CandidateType } from "./CandidateType";

interface InternalLexicon {
    readonly word: string;
    readonly romanization: string;
    readonly frequency: number;
    readonly latest: number;
    readonly input: string;
    readonly inputCount: number;
    readonly mark: string;
}

interface MemoryEntry {
    readonly word: string;
    readonly romanization: string;
    readonly frequency: number;
    readonly latest: number;
    readonly shortcut: number;
    readonly spell: number;
    readonly nineKeyAnchors: number;
    readonly nineKeyCode: number
}

export class InputMemory {
    private static readonly legacyMemoryTable: string = "memory";
    private static readonly definedMigrationValue: number = 2026;
    private static readonly migrationKey: string = "input_memory_migration2026";
    private static readonly recentIntervalMilliseconds: number = 86400000;
    private static readonly defaultSpellLimit: number = 20;
    private static readonly defaultShortcutLimit: number = 20;
    private static readonly defaultStrictLimit: number = 20;
    private static readonly partialShortcutLimit: number = 300;
    private static readonly gainedShortcutLimit: number = 300;
    private static readonly maxPartialInputLength: number = 10;
    private static isMigrating: boolean = false;

    private static hashCode(str: string): number {
        let hash = 0;
        for (let i = 0; i < str.length; i++) {
            hash = Math.imul(31, hash) + str.charCodeAt(i) | 0;
        }
        return hash;
    }

    private static nowMilliseconds(): number {
        return Date.now();
    }

    private static keysText(keys: VirtualInputKey[]): string {
        return CharCode.keysText(keys);
    }

    private static normalizeShortcutText(text: string): string {
        return text.replace(/y/g, "j");
    }

    private static normalizeAnchorKey(key: VirtualInputKey): VirtualInputKey {
        return CharCode.normalizeAnchorKey(key);
    }

    private static stripTones(text: string): string {
        return text.replace(/\d/g, "");
    }

    private static stripSpacesAndTones(text: string): string {
        return text.replace(/[\d\s]/g, "");
    }

    private static splitRomanization(text: string): string[] {
        return text.split(/\s+/).filter((part) => part.length > 0);
    }

    private static anchorsText(romanization: string): string {
        return InputMemory.splitRomanization(romanization)
            .map((syllable) => syllable[0] ?? "")
            .join("");
    }

    private static letterText(romanization: string): string {
        return romanization.replace(/[^a-z]/g, "");
    }

    private static makeMemoryEntry(word: string, romanization: string, frequency: number = 1, latest: number = InputMemory.nowMilliseconds()): MemoryEntry {
        const anchors = InputMemory.anchorsText(romanization);
        const syllableText = InputMemory.letterText(romanization);
        const shortcut = InputMemory.hashCode(anchors);
        const spell = InputMemory.hashCode(syllableText);
        const nineKeyAnchors: number = CharCode.nineKeyCharCode(anchors) ?? 0;
        const nineKeyCode: number = CharCode.nineKeyCharCode(syllableText) ?? 0;
        return {
            word: word,
            romanization: romanization,
            frequency: frequency,
            latest: latest,
            shortcut: shortcut,
            spell: spell,
            nineKeyAnchors: nineKeyAnchors,
            nineKeyCode: nineKeyCode
        };
    }

    private static schemeLength(scheme: Scheme): number {
        return scheme.reduce((acc, syllable) => acc + syllable.alias.length, 0);
    }

    private static schemeAliasText(scheme: Scheme): string {
        return InputMemory.keysText(scheme.flatMap((syllable) => syllable.alias));
    }

    private static schemeOriginText(scheme: Scheme): string {
        return InputMemory.keysText(scheme.flatMap((syllable) => syllable.origin));
    }

    private static schemeOriginAnchorsText(scheme: Scheme): string {
        const anchors: string[] = [];
        for (const syllable of scheme) {
            const anchor = syllable.origin[0];
            if (anchor !== undefined) {
                anchors.push(anchor.text);
            }
        }
        return anchors.join("");
    }

    private static schemeMark(scheme: Scheme): string {
        return scheme.map((syllable) => InputMemory.keysText(syllable.alias)).join(" ");
    }

    private static schemeSyllableText(scheme: Scheme): string {
        return scheme.map((syllable) => InputMemory.keysText(syllable.origin)).join(" ");
    }

    private static schemeAliasAnchors(scheme: Scheme): VirtualInputKey[] {
        const anchors: VirtualInputKey[] = [];
        for (const syllable of scheme) {
            const anchor = syllable.alias[0];
            if (anchor !== undefined) {
                anchors.push(anchor);
            }
        }
        return anchors;
    }

    private static makeInternalLexicon(word: string, romanization: string, frequency: number, latest: number, input: string, mark?: string): InternalLexicon {
        return {
            word: word,
            romanization: romanization,
            frequency: frequency,
            latest: latest,
            input: input,
            inputCount: input.length,
            mark: mark ?? input,
        };
    }

    private static replacedInput(item: InternalLexicon, input: string, mark?: string): InternalLexicon {
        return InputMemory.makeInternalLexicon(
            item.word,
            item.romanization,
            item.frequency,
            item.latest,
            input,
            mark ?? input
        );
    }

    private static toLexicon(item: InternalLexicon, number: number): Lexicon {
        return {
            type: LexiconType.Cantonese,
            text: item.word,
            romanization: item.romanization,
            input: item.input,
            inputCount: item.inputCount,
            number: number,
            mark: item.mark,
        };
    }

    private static internalLexiconKey(item: InternalLexicon): string {
        return `${item.word}\u0000${item.romanization}`;
    }

    private static distinctInternalLexicons(items: InternalLexicon[]): InternalLexicon[] {
        const handled: string[] = [];
        const results: InternalLexicon[] = [];
        for (const item of items) {
            const key = InputMemory.internalLexiconKey(item);
            if (handled.includes(key)) {
                continue;
            }
            handled.push(key);
            results.push(item);
        }
        return results;
    }
    private static timeSort(items: InternalLexicon[], now: number = InputMemory.nowMilliseconds()): InternalLexicon[] {
        return [...items].sort((lhs, rhs) => {
            if (lhs.inputCount !== rhs.inputCount) {
                return rhs.inputCount - lhs.inputCount;
            }
            const isLHSRecent = (now - lhs.latest) < InputMemory.recentIntervalMilliseconds;
            const isRHSRecent = (now - rhs.latest) < InputMemory.recentIntervalMilliseconds;
            if (isLHSRecent !== isRHSRecent) {
                return isLHSRecent ? -1 : 1;
            }
            if (lhs.frequency !== rhs.frequency) {
                return rhs.frequency - lhs.frequency;
            }
            return rhs.latest - lhs.latest;
        });
    }
    private static advancedSort(items: InternalLexicon[], inputLength: number): InternalLexicon[] {
        const now = InputMemory.nowMilliseconds();
        const recentEntries = items
            .filter((item) => item.inputCount === inputLength && ((now - item.latest) < InputMemory.recentIntervalMilliseconds))
            .sort((lhs, rhs) => rhs.frequency - lhs.frequency);
        if (recentEntries.length < 1) {
            return InputMemory.timeSort(items, now);
        }
        if (recentEntries.length === items.length) {
            return recentEntries;
        }
        const others = items.filter((item) => {
            return item.inputCount !== inputLength || ((now - item.latest) >= InputMemory.recentIntervalMilliseconds);
        });
        return [...recentEntries, ...InputMemory.timeSort(others, now)];
    }
    private static queryIdealSingleSyllable(keys: VirtualInputKey[], syllableStore: relationalStore.RdbStore): Scheme | undefined {
        if (keys.length < 1) {
            return undefined;
        }
        const segmentation = Segmenter.segment(keys, syllableStore);
        return segmentation.find((scheme: Scheme) => scheme.length === 1 && InputMemory.schemeLength(scheme) === keys.length);
    }
    private static matchedTailSyllable(keys: VirtualInputKey[], syllableStore: relationalStore.RdbStore,
        cache: Record<string, string>): string | undefined {
        if (keys.length < 1) {
            return undefined;
        }
        const cacheKey = InputMemory.keysText(keys);
        const cached = cache[cacheKey];
        if (cached !== undefined) {
            return cached.length > 0 ? cached : undefined;
        }
        const matched = InputMemory.queryIdealSingleSyllable(keys, syllableStore);
        if (matched === undefined) {
            cache[cacheKey] = "";
            return undefined;
        }
        const originText = InputMemory.schemeOriginText(matched);
        cache[cacheKey] = originText;
        return originText;
    }
    private static descendingInputLengths(inputLength: number): number[] {
        const lengths: number[] = [];
        for (let index = inputLength - 1; index >= 1; index--) {
            lengths.push(index);
        }
        return lengths;
    }
    private static idealLexicons(items: InternalLexicon[], inputLength: number, limit?: number): Lexicon[] {
        const sorted = InputMemory.distinctInternalLexicons(InputMemory.advancedSort(items, inputLength));
        const handled = limit === undefined ? sorted : sorted.slice(0, limit);
        return handled.map((item) => InputMemory.toLexicon(item, -1));
    }
    private static queriedLexicons(items: InternalLexicon[]): Lexicon[] {
        return InputMemory.distinctInternalLexicons(InputMemory.timeSort(items))
            .slice(0, 6)
            .map((item) => InputMemory.toLexicon(item, -2));
    }

    private static nineKeyQueriedLexicons(items: InternalLexicon[]): Lexicon[] {
        return InputMemory.distinctInternalLexicons(InputMemory.nineKeyPeculiarSort(items))
            .slice(0, 6)
            .map((item) => InputMemory.toLexicon(item, -2));
    }
    private static nineKeyRegularSort(items: InternalLexicon[], isOrdered: boolean = false): InternalLexicon[] {
        const frequencyPreferred = isOrdered ? [...items] : [...items].sort((lhs, rhs) => rhs.frequency - lhs.frequency);
        const datePreferred = [...items].sort((lhs, rhs) => rhs.latest - lhs.latest);
        return InputMemory.distinctInternalLexicons([
            ...frequencyPreferred.slice(0, 3),
            ...datePreferred.slice(0, 5),
            ...frequencyPreferred
        ]);
    }
    private static nineKeyPeculiarSort(items: InternalLexicon[]): InternalLexicon[] {
        const inputCounts: number[] = [];
        for (const item of items) {
            if (!inputCounts.includes(item.inputCount)) {
                inputCounts.push(item.inputCount);
            }
        }
        inputCounts.sort((lhs, rhs) => rhs - lhs);
        return inputCounts.flatMap((inputCount) => {
            return InputMemory.nineKeyRegularSort(items.filter((item) => item.inputCount === inputCount));
        });
    }

    private static tableExists(tableName: string, store: relationalStore.RdbStore): boolean {
        const command = "SELECT EXISTS(SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?);";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [tableName]);
            return res.goToNextRow() && res.getLong(0) === 1;
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            try {
                res?.close();
            } catch (error) {
                const err: BusinessError = error as BusinessError;
                console.error(`message: ${err.message}, code: ${err.code}`);
            }
        }
        return false;
    }

    private static legacyTableHasLatestColumn(store: relationalStore.RdbStore): boolean {
        const command = "PRAGMA table_info(memory);";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command);
            while (res.goToNextRow()) {
                if (res.getString(1) === "latest") {
                    return true;
                }
            }
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            try {
                res?.close();
            } catch (error) {
                const err: BusinessError = error as BusinessError;
                console.error(`message: ${err.message}, code: ${err.code}`);
            }
        }
        return false;
    }
    private static ensureLegacyLatestColumn(store: relationalStore.RdbStore) {
        if (!(InputMemory.tableExists(InputMemory.legacyMemoryTable, store)) || InputMemory.legacyTableHasLatestColumn(store)) {
            return;
        }
        const command = "ALTER TABLE memory ADD COLUMN latest INTEGER NOT NULL DEFAULT 0;";
        try {
            store.executeSync(command);
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`error in ensureLegacyLatestColumn(), message: ${err.message}, code: ${err.code}`);
        }
    }

    private static ensureCoreMemoryTable(store: relationalStore.RdbStore) {
        try {
            const command: string = "CREATE TABLE IF NOT EXISTS core_memory (id INTEGER PRIMARY KEY AUTOINCREMENT, word TEXT NOT NULL, romanization TEXT NOT NULL, frequency INTEGER NOT NULL, latest INTEGER NOT NULL, shortcut INTEGER NOT NULL, spell INTEGER NOT NULL, nine_key_anchors INTEGER NOT NULL, nine_key_code INTEGER NOT NULL, UNIQUE (word, romanization));";
            store.executeSync(command);
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`error in ensureCoreMemoryTable(), message: ${err.message}, code: ${err.code}`);
        }
    }

    private static ensureCoreMemoryIndexes(store: relationalStore.RdbStore) {
        const commands: string[] = [
            "CREATE INDEX IF NOT EXISTS ix_core_memory_frequency ON core_memory (frequency);",
            "CREATE INDEX IF NOT EXISTS ix_core_memory_shortcut ON core_memory (shortcut, frequency DESC);",
            "CREATE INDEX IF NOT EXISTS ix_core_memory_spell ON core_memory (spell, frequency DESC);",
            "CREATE INDEX IF NOT EXISTS ix_core_memory_strict ON core_memory (spell, shortcut, frequency DESC);",
            "CREATE INDEX IF NOT EXISTS ix_core_memory_nine_key_anchors ON core_memory (nine_key_anchors, frequency DESC);",
            "CREATE INDEX IF NOT EXISTS ix_core_memory_nine_key_code ON core_memory (nine_key_code, frequency DESC);",
        ];
        for (const command of commands) {
            try {
                store.executeSync(command);
            } catch (error) {
                let err: BusinessError = error as BusinessError;
                console.error(`error in ensureCoreMemoryIndexes(), message: ${err.message}, code: ${err.code}`);
            }
        }
    }

    private static isLegacyDataPresent(store: relationalStore.RdbStore): boolean {
        if (!(InputMemory.tableExists(InputMemory.legacyMemoryTable, store))) {
            return false;
        }
        const command: string = "SELECT frequency FROM memory WHERE frequency > 0 LIMIT 1;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command);
            if (res.goToFirstRow()) {
                return res.getLong(0) > 0;
            }
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            try {
                res?.close();
            } catch (error) {
                const err: BusinessError = error as BusinessError;
                console.error(`message: ${err.message}, code: ${err.code}`);
            }
        }
        return false;
    }

    private static fetchLegacyEntries(lower: number, upper: number, store: relationalStore.RdbStore): MemoryEntry[] {
        const entries: MemoryEntry[] = [];
        const command: string = "SELECT word, romanization, frequency, latest FROM memory WHERE frequency > ? AND frequency <= ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [lower, upper]);
            while (res.goToNextRow()) {
                const word = res.getString(0);
                const romanization = res.getString(1);
                const frequency = res.getLong(2);
                const latest = res.getLong(3);
                entries.push(InputMemory.makeMemoryEntry(word, romanization, frequency, latest));
            }
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            try {
                res?.close();
            } catch (error) {
                const err: BusinessError = error as BusinessError;
                console.error(`message: ${err.message}, code: ${err.code}`);
            }
        }
        return entries;
    }

    private static migrate(lower: number, upper: number, store: relationalStore.RdbStore): boolean {
        const entries = InputMemory.fetchLegacyEntries(lower, upper, store);
        if (entries.length < 1) {
            return true;
        }
        const command: string = "INSERT OR IGNORE INTO core_memory (word, romanization, frequency, latest, shortcut, spell, nine_key_anchors, nine_key_code) VALUES (?, ?, ?, ?, ?, ?, ?, ?);";
        let didBeginTransaction: boolean = false;
        try {
            store.beginTransaction();
            didBeginTransaction = true;
            for (const entry of entries) {
                store.executeSync(command, [entry.word, entry.romanization, entry.frequency, entry.latest, entry.shortcut, entry.spell, entry.nineKeyAnchors, entry.nineKeyCode]);
            }
            store.commit();
            didBeginTransaction = false;
            return true;
        } catch (error) {
            if (didBeginTransaction) {
                try {
                    store.rollBack();
                } catch (rollbackError) {
                    let err: BusinessError = rollbackError as BusinessError;
                    console.error(`error in migrate() rollback, message: ${err.message}, code: ${err.code}`);
                }
            }
            let err: BusinessError = error as BusinessError;
            console.error(`error in migrate(), message: ${err.message}, code: ${err.code}`);
            return false;
        }
    }

    private static setMigrationValue(settings: preferences.Preferences, value: number) {
        try {
            settings.putSync(InputMemory.migrationKey, value);
            settings.flush().catch(() => {
                console.error("Failed to save input memory migration value");
            });
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`Failed to save input memory migration value, message: ${err.message}, code: ${err.code}`);
        }
    }

    private static missionAccomplished(settings: preferences.Preferences) {
        InputMemory.setMigrationValue(settings, InputMemory.definedMigrationValue);
        InputMemory.isMigrating = false;
    }

    private static getMigrationValue(settings: preferences.Preferences): number {
        try {
            const savedValue = settings.getSync(InputMemory.migrationKey, 0);
            return typeof savedValue === "number" ? savedValue : 0;
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`Failed to load input memory migration value, message: ${err.message}, code: ${err.code}`);
        }
        return 0;
    }

    private static performMigration(store: relationalStore.RdbStore, settings: preferences.Preferences) {
        const savedValue: number = InputMemory.getMigrationValue(settings);
        if (savedValue === InputMemory.definedMigrationValue) {
            InputMemory.isMigrating = false;
            return;
        }
        if (!(InputMemory.isLegacyDataPresent(store))) {
            InputMemory.missionAccomplished(settings);
            return;
        }
        InputMemory.isMigrating = true;
        if (savedValue === 0) {
            if (!InputMemory.migrate(20, 100000, store)) {
                InputMemory.isMigrating = false;
                return;
            }
            InputMemory.setMigrationValue(settings, 20);
        }
        let upper: number = savedValue === 0 ? 20 : savedValue;
        while (upper > 1) {
            const lower: number = upper - 1;
            if (!InputMemory.migrate(lower, upper, store)) {
                InputMemory.isMigrating = false;
                return;
            }
            InputMemory.setMigrationValue(settings, lower);
            upper = lower;
        }
        if (!InputMemory.migrate(0, 1, store)) {
            InputMemory.isMigrating = false;
            return;
        }
        InputMemory.missionAccomplished(settings);
    }

    static search(keys: VirtualInputKey[], store: relationalStore.RdbStore): Lexicon[] {
        if (InputMemory.isMigrating) {
            return [];
        }
        if (keys.length < 1) {
            return [];
        }
        const text = InputMemory.keysText(keys);
        const inputLength = keys.length;
        const fullMatched = InputMemory.spellMatch(text, text, store, InputMemory.defaultSpellLimit);
        if (fullMatched.length > 0) {
            return InputMemory.idealLexicons(fullMatched, inputLength, 6);
        }
        const shortcuts = InputMemory.shortcutMatch(text, text, store, 5);
        if (shortcuts.length > 0) {
            return InputMemory.idealLexicons(shortcuts, inputLength, 6);
        }
        return [];
    }

    static suggest(keys: VirtualInputKey[], segmentation: Segmentation, store: relationalStore.RdbStore, syllableStore: relationalStore.RdbStore): Lexicon[] {
        if (InputMemory.isMigrating) {
            return [];
        }
        return InputMemory.searchDetailed(keys, segmentation, true, store, syllableStore);
    }

    private static searchDetailed(keys: VirtualInputKey[], segmentation: Segmentation, deepSearch: boolean,
        store: relationalStore.RdbStore, syllableStore: relationalStore.RdbStore): Lexicon[] {
        if (keys.length < 1) {
            return [];
        }
        const tailSyllableCache: Record<string, string> = {};
        const inputLength = keys.length;
        const text = InputMemory.keysText(keys);
        const fullMatched = InputMemory.spellMatch(text, text, store, InputMemory.defaultSpellLimit);
        const idealSchemes = segmentation.filter((scheme) => InputMemory.schemeLength(scheme) === inputLength);
        const idealQueried = idealSchemes.flatMap((scheme) => {
            const spellCode = InputMemory.hashCode(InputMemory.schemeOriginText(scheme));
            const shortcutCode = InputMemory.hashCode(InputMemory.schemeOriginAnchorsText(scheme));
            return InputMemory.strictMatch(spellCode, shortcutCode, text, store, InputMemory.schemeMark(scheme), InputMemory.defaultStrictLimit);
        });
        const queried = InputMemory.query(segmentation, idealSchemes, deepSearch, store);
        const partialMatched = deepSearch ?
            InputMemory.partialMatch(keys, text, inputLength, segmentation, idealSchemes, store, syllableStore, tailSyllableCache) :
            [];
        const partialFallback = segmentation.length < 1 ?
            partialMatched.filter((item) => item.inputCount < inputLength) :
            [];
        if (fullMatched.length > 0 || idealQueried.length > 0) {
            return [...InputMemory.idealLexicons([...fullMatched, ...idealQueried], inputLength), ...partialFallback, ...queried];
        }
        const shortcuts = InputMemory.shortcutMatch(text, text, store, 5);
        if (shortcuts.length > 0) {
            return [...InputMemory.idealLexicons(shortcuts, inputLength), ...partialFallback, ...queried];
        }
        if (!deepSearch) {
            return queried;
        }
        if (partialMatched.length < 1) {
            return queried;
        }
        return [...partialMatched, ...queried];
    }

    private static partialMatch(keys: VirtualInputKey[], text: string, inputLength: number, segmentation: Segmentation,
        idealSchemes: Scheme[], store: relationalStore.RdbStore, syllableStore: relationalStore.RdbStore,
        tailSyllableCache: Record<string, string>): Lexicon[] {
        const shouldPartiallyMatch = inputLength <= InputMemory.maxPartialInputLength && (idealSchemes.length < 1 ||
            keys[0] === VirtualInputKey.letterM || keys[inputLength - 1] === VirtualInputKey.letterM);
        if (!shouldPartiallyMatch) {
            return [];
        }
        const prefixMatched: InternalLexicon[] = segmentation.flatMap((scheme) => {
            if (scheme.length < 1) {
                return [];
            }
            const tail = keys.slice(InputMemory.schemeLength(scheme));
            if (tail.length < 1) {
                return [];
            }
            const schemeAnchors = InputMemory.schemeAliasAnchors(scheme);
            const conjoinedText = InputMemory.keysText([...schemeAnchors, ...tail]);
            const schemeSyllableText = InputMemory.schemeSyllableText(scheme);
            const mark = `${InputMemory.schemeMark(scheme)} ${InputMemory.keysText(tail)}`.trim();
            const tailAsAnchorText = tail.map((key) => InputMemory.normalizeAnchorKey(key).text).join("");
            const conjoinedMatched = InputMemory.shortcutMatch(conjoinedText, conjoinedText, store, InputMemory.partialShortcutLimit)
                .flatMap((item) => {
                    const toneFreeRomanization = InputMemory.stripTones(item.romanization);
                    if (!toneFreeRomanization.startsWith(schemeSyllableText)) {
                        return [];
                    }
                    const suffixAnchorText = toneFreeRomanization.slice(schemeSyllableText.length)
                        .trim()
                        .split(/\s+/)
                        .filter((part) => part.length > 0)
                        .map((part) => part[0])
                        .join("");
                    if (suffixAnchorText !== tailAsAnchorText) {
                        return [];
                    }
                    return [InputMemory.replacedInput(item, text, mark)];
                });
            const transformedTailText = tail.map((key, index) => {
                return index === 0 && key === VirtualInputKey.letterY ? VirtualInputKey.letterJ.text : key.text;
            }).join("");
            const syllableText = `${schemeSyllableText} ${transformedTailText}`.trim();
            const anchorsText = InputMemory.keysText(schemeAnchors) + (tail[0]?.text ?? "");
            const anchorsMatched = InputMemory.shortcutMatch(anchorsText, anchorsText, store, InputMemory.partialShortcutLimit)
                .flatMap((item) => {
                    if (!InputMemory.stripTones(item.romanization).startsWith(syllableText)) {
                        return [];
                    }
                    return [InputMemory.replacedInput(item, text, mark)];
                });
            return [...conjoinedMatched, ...anchorsMatched];
        });
        const gainedMatched: InternalLexicon[] = InputMemory.descendingInputLengths(inputLength)
            .flatMap((length) => {
                const leadingText = InputMemory.keysText(keys.slice(0, length));
                return InputMemory.shortcutMatch(leadingText, leadingText, store, InputMemory.gainedShortcutLimit);
            })
            .flatMap((item) => {
                const tail = keys.slice(item.inputCount - 1);
                if (tail.length > 6) {
                    return [];
                }
                const converted = InputMemory.replacedInput(item, text, text);
                if (InputMemory.stripSpacesAndTones(item.romanization).startsWith(text)) {
                    return [converted];
                }
                const syllables = InputMemory.splitRomanization(item.romanization);
                const lastSyllable = syllables.length > 0 ? InputMemory.stripTones(syllables[syllables.length - 1]) : "";
                if (lastSyllable.length < 1) {
                    return [];
                }
                const tailSyllable = InputMemory.matchedTailSyllable(tail, syllableStore, tailSyllableCache);
                if (tailSyllable !== undefined) {
                    return lastSyllable === tailSyllable ? [converted] : [];
                }
                const tailText = InputMemory.keysText(tail);
                return lastSyllable.startsWith(tailText) ? [converted] : [];
            });
        return InputMemory.distinctInternalLexicons(
            InputMemory.advancedSort([...prefixMatched, ...gainedMatched], inputLength)
        ).slice(0, 5).map((item) => InputMemory.toLexicon(item, -1));
    }

    private static query(segmentation: Segmentation, idealSchemes: Scheme[], deepSearch: boolean,
        store: relationalStore.RdbStore): Lexicon[] {
        if (segmentation.length < 1) {
            return [];
        }
        if (!deepSearch) {
            return InputMemory.queriedLexicons(idealSchemes.flatMap((scheme) => InputMemory.perform(scheme, store)));
        }
        if (idealSchemes.length < 1) {
            return InputMemory.queriedLexicons(segmentation.flatMap((scheme) => InputMemory.perform(scheme, store)));
        } else {
            const queried = idealSchemes.flatMap((scheme) => {
                if (scheme.length <= 1) {
                    return [];
                }
                const prefixes: Scheme[] = [];
                for (let index = scheme.length - 1; index >= 1; index--) {
                    prefixes.push(scheme.slice(0, index));
                }
                return prefixes.flatMap((sliced) => InputMemory.perform(sliced, store));
            });
            return InputMemory.queriedLexicons(queried);
        }
    }

    private static perform(scheme: Scheme, store: relationalStore.RdbStore): InternalLexicon[] {
        const spellCode = InputMemory.hashCode(InputMemory.schemeOriginText(scheme));
        const shortcutCode = InputMemory.hashCode(InputMemory.schemeOriginAnchorsText(scheme));
        return InputMemory.strictMatch(
            spellCode,
            shortcutCode,
            InputMemory.schemeAliasText(scheme),
            store,
            InputMemory.schemeMark(scheme),
            InputMemory.defaultStrictLimit
        );
    }

    private static shortcutMatch(text: string, input: string, store: relationalStore.RdbStore,
        limit: number = InputMemory.defaultShortcutLimit, mark?: string): InternalLexicon[] {
        const code = InputMemory.hashCode(InputMemory.normalizeShortcutText(text));
        const lexicons: InternalLexicon[] = [];
        const command: string = "SELECT word, romanization, frequency, latest FROM core_memory WHERE shortcut = ? ORDER BY frequency DESC, latest DESC LIMIT ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [code, limit]);
            while (res.goToNextRow()) {
                const word = res.getString(0);
                const romanization = res.getString(1);
                const frequency = res.getLong(2);
                const latest = res.getLong(3);
                if (InputMemory.containsNonIdeographic(word)) { continue; }
                lexicons.push(InputMemory.makeInternalLexicon(word, romanization, frequency, latest, input, mark ?? input));
            }
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            try {
                res?.close();
            } catch (error) {
                const err: BusinessError = error as BusinessError;
                console.error(`message: ${err.message}, code: ${err.code}`);
            }
        }
        return lexicons;
    }

    private static spellMatch(text: string, input: string, store: relationalStore.RdbStore,
        limit: number = InputMemory.defaultSpellLimit, mark?: string): InternalLexicon[] {
        const code = InputMemory.hashCode(text);
        const lexicons: InternalLexicon[] = [];
        const command: string = "SELECT word, romanization, frequency, latest FROM core_memory WHERE spell = ? ORDER BY frequency DESC, latest DESC LIMIT ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [code, limit]);
            while (res.goToNextRow()) {
                const word = res.getString(0);
                const romanization = res.getString(1);
                const frequency = res.getLong(2);
                const latest = res.getLong(3);
                if (InputMemory.containsNonIdeographic(word)) { continue; }
                lexicons.push(InputMemory.makeInternalLexicon(
                    word,
                    romanization,
                    frequency,
                    latest,
                    input,
                    mark ?? InputMemory.stripTones(romanization).replace(/\s+/g, " ").trim()
                ));
            }
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            try {
                res?.close();
            } catch (error) {
                const err: BusinessError = error as BusinessError;
                console.error(`message: ${err.message}, code: ${err.code}`);
            }
        }
        return lexicons;
    }

    private static strictMatch(spell: number, shortcut: number, input: string, store: relationalStore.RdbStore,
        mark?: string, limit: number = InputMemory.defaultStrictLimit): InternalLexicon[] {
        const lexicons: InternalLexicon[] = [];
        const command: string = "SELECT word, romanization, frequency, latest FROM core_memory WHERE spell = ? AND shortcut = ? ORDER BY frequency DESC, latest DESC LIMIT ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [spell, shortcut, limit]);
            while (res.goToNextRow()) {
                const word = res.getString(0);
                const romanization = res.getString(1);
                const frequency = res.getLong(2);
                const latest = res.getLong(3);
                if (InputMemory.containsNonIdeographic(word)) { continue; }
                lexicons.push(InputMemory.makeInternalLexicon(
                    word,
                    romanization,
                    frequency,
                    latest,
                    input,
                    mark ?? InputMemory.stripTones(romanization).replace(/\s+/g, " ").trim()
                ));
            }
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            try {
                res?.close();
            } catch (error) {
                const err: BusinessError = error as BusinessError;
                console.error(`message: ${err.message}, code: ${err.code}`);
            }
        }
        return lexicons;
    }

    private static containsNonIdeographic(text: string): boolean {
        return /[^\p{Unified_Ideograph}]/u.test(text);
    }

    static nineKeySearch(combos: Combo[], store: relationalStore.RdbStore): Lexicon[] {
        if (InputMemory.isMigrating) {
            return [];
        }
        if (combos.length < 1 || combos.some((combo) => combo.isSpecial)) {
            return [];
        }
        const inputLength = combos.length;
        const fullCode = CharCode.comboCode(combos);
        if (inputLength < 2) {
            const codeMatched = InputMemory.nineKeyCodeMatch(fullCode, store, 100);
            const anchorsMatched = InputMemory.nineKeyAnchorsMatch(fullCode, store, 100);
            return [...codeMatched, ...anchorsMatched].map((item) => InputMemory.toLexicon(item, -1));
        }
        const fullCodeMatched = InputMemory.nineKeyRegularSort(InputMemory.nineKeyCodeMatch(fullCode, store, 100), true);
        const fullAnchorsMatched = InputMemory.nineKeyRegularSort(InputMemory.nineKeyAnchorsMatch(fullCode, store, 100), true);
        const ideal = InputMemory.distinctInternalLexicons([
            ...fullCodeMatched.slice(0, 10),
            ...InputMemory.nineKeyRegularSort([...fullCodeMatched, ...fullAnchorsMatched.slice(0, 5)])
        ]).map((item) => InputMemory.toLexicon(item, -1));
        const queried = InputMemory.nineKeyQueriedLexicons(InputMemory.descendingInputLengths(inputLength)
            .flatMap((leadingLength) => {
                const code = CharCode.comboCode(combos.slice(0, leadingLength));
                return InputMemory.nineKeyCodeMatch(code, store, 4);
            }));
        return [...ideal, ...queried];
    }
    private static nineKeyAnchorsMatch(code: number, store: relationalStore.RdbStore, limit: number = 100): InternalLexicon[] {
        if (code < 1) {
            return [];
        }
        const lexicons: InternalLexicon[] = [];
        const command: string = "SELECT word, romanization, frequency, latest FROM core_memory WHERE nine_key_anchors = ? ORDER BY frequency DESC, latest DESC LIMIT ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [code, limit]);
            while (res.goToNextRow()) {
                const word = res.getString(0);
                const romanization = res.getString(1);
                const frequency = res.getLong(2);
                const latest = res.getLong(3);
                const anchors = InputMemory.anchorsText(romanization);
                if (InputMemory.containsNonIdeographic(word)) { continue; }
                lexicons.push(InputMemory.makeInternalLexicon(word, romanization, frequency, latest, anchors, anchors));
            }
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            try {
                res?.close();
            } catch (error) {
                const err: BusinessError = error as BusinessError;
                console.error(`message: ${err.message}, code: ${err.code}`);
            }
        }
        return lexicons;
    }
    private static nineKeyCodeMatch(code: number, store: relationalStore.RdbStore, limit: number = 100): InternalLexicon[] {
        if (code < 1) {
            return [];
        }
        const lexicons: InternalLexicon[] = [];
        const command: string = "SELECT word, romanization, frequency, latest FROM core_memory WHERE nine_key_code = ? ORDER BY frequency DESC, latest DESC LIMIT ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [code, limit]);
            while (res.goToNextRow()) {
                const word = res.getString(0);
                const romanization = res.getString(1);
                const frequency = res.getLong(2);
                const latest = res.getLong(3);
                if (InputMemory.containsNonIdeographic(word)) { continue; }
                const mark = InputMemory.stripTones(romanization).replace(/\s+/g, " ").trim();
                const input = mark.replace(/\s+/g, "");
                lexicons.push(InputMemory.makeInternalLexicon(word, romanization, frequency, latest, input, mark));
            }
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            try {
                res?.close();
            } catch (error) {
                const err: BusinessError = error as BusinessError;
                console.error(`message: ${err.message}, code: ${err.code}`);
            }
        }
        return lexicons;
    }

    static prepare(store: relationalStore.RdbStore, settings?: preferences.Preferences) {
        InputMemory.ensureCoreMemoryTable(store);
        InputMemory.ensureCoreMemoryIndexes(store);
        InputMemory.ensureLegacyLatestColumn(store);
        try {
            const command: string = "CREATE TABLE IF NOT EXISTS fallback(word TEXT NOT NULL, romanization TEXT NOT NULL, shortcut INTEGER NOT NULL, ping INTEGER NOT NULL);";
            store.executeSync(command);
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`error in prepare(), message: ${err.message}, code: ${err.code}`);
        }
        try {
            const command: string = "CREATE TABLE IF NOT EXISTS variant_sim(left INTEGER NOT NULL, right INTEGER NOT NULL);";
            store.executeSync(command);
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`error in prepare(), message: ${err.message}, code: ${err.code}`);
        }
        InputMemory.prepareFallbackTables(store);
        if (settings !== undefined) {
            InputMemory.performMigration(store, settings);
        }
    }
    static process(candidates: Candidate[], store: relationalStore.RdbStore) {
        if (InputMemory.isMigrating) { return; }
        if (candidates.length < 1) { return; }
        const containsNonCantonese: boolean = candidates.some((item) => item.type != CandidateType.Cantonese);
        if (containsNonCantonese) { return; }
        const text: string = candidates.map(item => item.lexicon.text).join("");
        const romanization: string = candidates.map(item => item.lexicon.romanization ?? "").join(" ");
        const concatenated: Lexicon = {
            type: LexiconType.Cantonese,
            text: text,
            romanization: romanization,
            input: "i",
            inputCount: 1,
            number: 0
        };
        InputMemory.handle(concatenated, store);
    }
    private static handle(lexicon: Lexicon, store: relationalStore.RdbStore) {
        const frequency = InputMemory.find(lexicon, store);
        if (frequency > 0) {
            const newFrequency = frequency + 1;
            InputMemory.update(lexicon, newFrequency, store);
        } else {
            InputMemory.insert(lexicon, store);
        }
    }
    private static find(lexicon: Lexicon, store: relationalStore.RdbStore): number {
        let frequency: number = 0;
        const romanization = lexicon.romanization ?? "X";
        const command: string = "SELECT frequency FROM core_memory WHERE word = ? AND romanization = ? LIMIT 1;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [lexicon.text, romanization]);
            if (res.goToFirstRow()) {
                frequency = res.getLong(0);
            }
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            try {
                res?.close();
            } catch (error) {
                const err: BusinessError = error as BusinessError;
                console.error(`message: ${err.message}, code: ${err.code}`);
            }
        }
        return frequency;
    }
    private static update(lexicon: Lexicon, newFrequency: number, store: relationalStore.RdbStore) {
        const romanization = lexicon.romanization ?? "X";
        const latest = InputMemory.nowMilliseconds();
        const command: string = "UPDATE core_memory SET frequency = ?, latest = ? WHERE word = ? AND romanization = ?;";
        try {
            store.executeSync(command, [newFrequency, latest, lexicon.text, romanization]);
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        }
    }
    private static insert(lexicon: Lexicon, store: relationalStore.RdbStore) {
        const romanization = lexicon.romanization ?? "X";
        const entry = InputMemory.makeMemoryEntry(lexicon.text, romanization);
        const command: string = "INSERT INTO core_memory (word, romanization, frequency, latest, shortcut, spell, nine_key_anchors, nine_key_code) VALUES (?, ?, ?, ?, ?, ?, ?, ?);";
        try {
            store.executeSync(command, [entry.word, entry.romanization, entry.frequency, entry.latest, entry.shortcut, entry.spell, entry.nineKeyAnchors, entry.nineKeyCode]);
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        }
    }


    // Fallback searching

    static fallbackSearch(keys: VirtualInputKey[], store: relationalStore.RdbStore): Lexicon[] {
        return InputMemory.fallBackProcessSlices(keys, store);
    }
    private static fallBackProcessSlices(keys: VirtualInputKey[], store: relationalStore.RdbStore): Lexicon[] {
        const inputLength: number = keys.length;
        const range = [...Array(inputLength)].map((_value: number, index: number) => index);
        let items: Lexicon[] = range.flatMap(num => {
            const leadingKeys = keys.slice(0, inputLength - num);
            const leadingText = leadingKeys.map((key) => key.text).join("")
            const code = InputMemory.hashCode(leadingText);
            return InputMemory.fallBackMatch(leadingText, code, store);
        })
        return items;
    }
    private static fallBackMatch(text: string, code: number, store: relationalStore.RdbStore): Lexicon[] {
        const inputCount = text.length;
        const lexicons: Lexicon[] = [];
        const limit = 50;
        const command: string = "SELECT rowid, word, romanization FROM fallback WHERE ping = ? OR shortcut = ? LIMIT ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [code, code, limit]);
            while (res.goToNextRow()) {
                const num = res.getLong(0);
                const word = res.getString(1);
                const romanization = res.getString(2);
                const instance: Lexicon = {
                    type: LexiconType.Cantonese,
                    text: word,
                    romanization: romanization,
                    input: text,
                    inputCount: inputCount,
                    number: num,
                };
                lexicons.push(instance);
            }
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            try {
                res?.close();
            } catch (error) {
                const err: BusinessError = error as BusinessError;
                console.error(`message: ${err.message}, code: ${err.code}`);
            }
        }
        return lexicons;
    }


    // Fallback tables preparation

    private static prepareFallbackTables(store: relationalStore.RdbStore) {
        const needs = InputMemory.needsFallbackInsertion(store);
        if (needs) {
            InputMemory.fallbackInsert(store);
            InputMemory.t2sInsert(store);
        }
    }
    private static fallbackInsert(store: relationalStore.RdbStore) {
        const valuesText = FallbackLexiconHelper.generate();
        const leadingText: string = "INSERT INTO fallback (word, romanization, shortcut, ping) VALUES ";
        const trailingText: string = `;`;
        const command: string = leadingText + valuesText + trailingText;
        try {
            store.executeSync(command);
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        }
    }
    private static t2sInsert(store: relationalStore.RdbStore) {
        const valuesText = FallbackT2SHelper.generate();
        const leadingText: string = "INSERT INTO variant_sim (left, right) VALUES ";
        const trailingText: string = `;`;
        const command: string = leadingText + valuesText + trailingText;
        try {
            store.executeSync(command);
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        }
    }
    private static needsFallbackInsertion(store: relationalStore.RdbStore): boolean {
        let needs: boolean = true;
        const command: string = "SELECT shortcut FROM fallback WHERE ping = 109014 LIMIT 1;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command);
            if (res.goToFirstRow()) {
                const shortcut = res.getLong(0);
                needs = (shortcut != 110);
            }
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            try {
                res?.close();
            } catch (error) {
                const err: BusinessError = error as BusinessError;
                console.error(`message: ${err.message}, code: ${err.code}`);
            }
        }
        return needs;
    }
}
