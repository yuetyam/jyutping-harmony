import { preferences, relationalStore } from "@kit.ArkData";
import { BusinessError } from "@kit.BasicServicesKit";
import { Candidate } from "./Candidate";
import { VirtualInputKey } from "./VirtualInputKey";
import { Lexicon } from "./Lexicon";
import { LexiconType } from "./LexiconType";
import { Segmentation, Scheme, Segmenter } from "./Segmenter";
import { CharCode } from "./CharCode";
import { Combo } from "../ninekey/Combo";
import { CandidateType } from "./CandidateType";
import { EngineCode } from "./EngineCode";
import { NineKeySegmentation, NineKeyScheme } from "./NineKeySegmenter";

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
    readonly charCount: number;
    readonly letterCount: number;
    readonly complexity: string;
    readonly anchors: string;
    readonly spell: string;
    readonly nineKeyAnchors: string;
    readonly nineKeySpell: string;
}

export class InputMemory {
    private static readonly legacyMemoryTable: string = "memory";
    private static readonly legacyCoreMemoryTable: string = "core_memory";
    private static readonly definedMigrationValue: number = 2608;
    private static readonly migrationKey: string = "input_memory_migration2608";
    private static readonly previousMigrationKey: string = "input_memory_migration2026";
    private static readonly previousMigrationValue: number = 2026;
    private static readonly recentIntervalMilliseconds: number = 86400000;
    private static readonly partialShortcutLimit: number = 100;
    private static readonly gainedShortcutLimit: number = 100;
    private static readonly maxPartialInputLength: number = 24;
    private static isMigrating: boolean = false;

    private static nowMilliseconds(): number {
        return Date.now();
    }

    private static keysText(keys: VirtualInputKey[]): string {
        return CharCode.keysText(keys);
    }

    private static stripTones(text: string): string {
        return text.replace(/\d/g, "");
    }

    private static toneConverted(text: string): string {
        return text.replace(/vv/g, "4").replace(/xx/g, "5").replace(/qq/g, "6").replace(/v/g, "1").replace(/x/g, "2").replace(/q/g, "3");
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

    private static phoneTexts(romanization: string): string[] {
        return InputMemory.stripTones(romanization).split(/\s+/).filter((part) => part.length > 0);
    }

    private static makeMemoryEntry(word: string, romanization: string, frequency: number = 1, latest: number = InputMemory.nowMilliseconds()): MemoryEntry {
        const phones = InputMemory.phoneTexts(romanization);
        const anchors = phones.map((phone) => phone[0] ?? "").join("");
        const syllableText = InputMemory.letterText(romanization);
        const nineKeyAnchors = EngineCode.nineKey(anchors);
        const nineKeySpell = EngineCode.nineKey(syllableText);
        return {
            word: word,
            romanization: romanization,
            frequency: frequency,
            latest: latest,
            charCount: Array.from(word).length,
            letterCount: syllableText.length,
            complexity: EngineCode.complexity(phones.map((phone) => phone.length)),
            anchors: EngineCode.text(anchors),
            spell: EngineCode.text(syllableText),
            nineKeyAnchors: nineKeyAnchors,
            nineKeySpell: nineKeySpell
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

    private static replacedLexicon(item: Lexicon, input: string): Lexicon {
        return { type: item.type, text: item.text, romanization: item.romanization, input: input, inputCount: input.length, number: item.number, mark: item.mark, note: item.note };
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
    private static nineKeyQueriedLexicons(items: InternalLexicon[]): Lexicon[] {
        return InputMemory.distinctInternalLexicons(InputMemory.nineKeyPeculiarSort(items))
            .slice(0, 6)
            .map((item) => InputMemory.toLexicon(item, -2));
    }
    private static regularSort(items: InternalLexicon[], isOrdered: boolean = false): InternalLexicon[] {
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
            return InputMemory.regularSort(items.filter((item) => item.inputCount === inputCount));
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

    private static ensureMemoryTable(store: relationalStore.RdbStore) {
        try {
            const command: string = "CREATE TABLE IF NOT EXISTS memory2608 (id INTEGER PRIMARY KEY AUTOINCREMENT, word TEXT NOT NULL, romanization TEXT NOT NULL, frequency INTEGER NOT NULL, latest INTEGER NOT NULL, char_count INTEGER NOT NULL, letter_count INTEGER NOT NULL, complexity INTEGER NOT NULL, anchors INTEGER NOT NULL, spell INTEGER NOT NULL, anchors_9key INTEGER NOT NULL, spell_9key INTEGER NOT NULL, UNIQUE (word, romanization));";
            store.executeSync(command);
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`error in ensureMemoryTable(), message: ${err.message}, code: ${err.code}`);
        }
    }

    private static ensureMemoryIndexes(store: relationalStore.RdbStore) {
        const commands: string[] = [
            "CREATE INDEX IF NOT EXISTS ix2608_frequency ON memory2608 (frequency);",
            "CREATE INDEX IF NOT EXISTS ix2608_anchors ON memory2608 (anchors, char_count, frequency DESC);",
            "CREATE INDEX IF NOT EXISTS ix2608_spell ON memory2608 (spell, letter_count, complexity, frequency DESC);",
            "CREATE INDEX IF NOT EXISTS ix2608_anchors_9key ON memory2608 (anchors_9key, char_count, frequency DESC);",
            "CREATE INDEX IF NOT EXISTS ix2608_spell_9key ON memory2608 (spell_9key, letter_count, complexity, frequency DESC);",
            "CREATE INDEX IF NOT EXISTS ix2608_word ON memory2608 (word, frequency DESC);",
            "CREATE INDEX IF NOT EXISTS ix2608_lexicon ON memory2608 (word, romanization);",
        ];
        for (const command of commands) {
            try {
                store.executeSync(command);
            } catch (error) {
                let err: BusinessError = error as BusinessError;
                console.error(`error in ensureMemoryIndexes(), message: ${err.message}, code: ${err.code}`);
            }
        }
    }

    private static isLegacyDataPresent(table: string, store: relationalStore.RdbStore): boolean {
        if (!(InputMemory.tableExists(table, store))) {
            return false;
        }
        const command: string = `SELECT frequency FROM ${table} WHERE frequency > 0 LIMIT 1;`;
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

    private static fetchLegacyEntries(table: string, lower: number, upper: number, store: relationalStore.RdbStore): MemoryEntry[] {
        const entries: MemoryEntry[] = [];
        const command: string = `SELECT word, romanization, frequency, latest FROM ${table} WHERE frequency > ? AND frequency <= ? ORDER BY frequency DESC;`;
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

    private static migrate(table: string, lower: number, upper: number, store: relationalStore.RdbStore): boolean {
        const entries = InputMemory.fetchLegacyEntries(table, lower, upper, store);
        if (entries.length < 1) {
            return true;
        }
        const command: string = "INSERT OR IGNORE INTO memory2608 (word, romanization, frequency, latest, char_count, letter_count, complexity, anchors, spell, anchors_9key, spell_9key) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);";
        let didBeginTransaction: boolean = false;
        try {
            store.beginTransaction();
            didBeginTransaction = true;
            for (const entry of entries) {
                store.executeSync(command, [entry.word, entry.romanization, entry.frequency, entry.latest, entry.charCount, entry.letterCount, entry.complexity, entry.anchors, entry.spell, entry.nineKeyAnchors, entry.nineKeySpell]);
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
        try {
            settings.deleteSync(InputMemory.previousMigrationKey);
        } catch (error) {
            console.error(`Failed to clear previous input memory migration value: ${(error as BusinessError).message}`);
        }
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
        let previousMigrationValue: number = 0;
        try {
            previousMigrationValue = settings.getSync(InputMemory.previousMigrationKey, 0) as number;
        } catch (error) {
            console.error(`Failed to load previous input memory migration value: ${(error as BusinessError).message}`);
        }
        const legacyTable = previousMigrationValue === InputMemory.previousMigrationValue ? InputMemory.legacyCoreMemoryTable : InputMemory.legacyMemoryTable;
        if (!(InputMemory.isLegacyDataPresent(legacyTable, store))) {
            InputMemory.missionAccomplished(settings);
            return;
        }
        InputMemory.isMigrating = true;
        if (savedValue === 0) {
            if (!InputMemory.migrate(legacyTable, 20, 100000, store)) {
                InputMemory.isMigrating = false;
                return;
            }
            InputMemory.setMigrationValue(settings, 20);
        }
        let upper: number = savedValue === 0 ? 20 : savedValue;
        while (upper > 1) {
            const lower: number = upper - 1;
            if (!InputMemory.migrate(legacyTable, lower, upper, store)) {
                InputMemory.isMigrating = false;
                return;
            }
            InputMemory.setMigrationValue(settings, lower);
            upper = lower;
        }
        if (!InputMemory.migrate(legacyTable, 0, 1, store)) {
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
        const spellMatched = InputMemory.spellMatch(keys, undefined, text, undefined, 6, store)
            .filter((item) => InputMemory.letterText(item.romanization) === text);
        if (spellMatched.length > 0) {
            return InputMemory.timeSort(spellMatched).map((item) => InputMemory.toLexicon(item, -1));
        }
        return InputMemory.anchorsMatch(keys, text, 6, store).map((item) => InputMemory.toLexicon(item, -1));
    }

    static suggest(keys: VirtualInputKey[], segmentation: Segmentation, store: relationalStore.RdbStore, syllableStore: relationalStore.RdbStore): Lexicon[] {
        if (InputMemory.isMigrating) {
            return [];
        }
        const hasApostrophe = keys.some((key) => key.isApostrophe);
        const hasToneInputKey = keys.some((key) => key.isToneEvent);
        if (!hasApostrophe && !hasToneInputKey) {
            return InputMemory.suggestSearch(keys, segmentation, store, syllableStore);
        }
        const syllableKeys = keys.filter((key) => key.isSyllableLetter);
        const candidates = InputMemory.suggestSearch(syllableKeys, segmentation, store, syllableStore);
        const inputText = InputMemory.keysText(keys);
        const text = InputMemory.toneConverted(inputText);
        if (hasApostrophe && hasToneInputKey) {
            return candidates.filter((item) => text.startsWith(item.romanization ?? ""))
                .map((item) => InputMemory.replacedLexicon(item, inputText));
        }
        if (hasToneInputKey) {
            const textTones = text.replace(/[^1-6]/g, "");
            return candidates.flatMap((item): Lexicon[] => {
                const syllableText = (item.romanization ?? "").replace(/ /g, "");
                if (syllableText === text) return [InputMemory.replacedLexicon(item, inputText)];
                const tones = syllableText.replace(/[^1-6]/g, "");
                if (textTones.length === 1 && tones.length === 1) {
                    if (text.length !== item.inputCount + 1 || !/[1-6]$/.test(text) || textTones !== tones) return [];
                    return [InputMemory.replacedLexicon(item, inputText)];
                }
                if (textTones.length === 1 && tones.length === 2) {
                    if (/[1-6]$/.test(text)) {
                        if (!tones.endsWith(textTones) || !/[1-6]/.test(text[item.inputCount] ?? "")) return [];
                    } else if (!tones.startsWith(textTones)) {
                        return [];
                    }
                    return [InputMemory.replacedLexicon(item, inputText)];
                }
                if (textTones.length === 2 && tones.length === 2) {
                    if (!/[1-6]$/.test(text) || textTones !== tones || item.inputCount !== text.length - 2) return [];
                    return [InputMemory.replacedLexicon(item, inputText)];
                }
                return inputText === syllableText ? [InputMemory.replacedLexicon(item, inputText)] : [];
            });
        }
        if (keys[0]?.isApostrophe) return [];
        const isTrailingSeparator = keys[keys.length - 1]?.isApostrophe ?? false;
        const inputSeparatorCount = keys.filter((key) => key.isApostrophe).length;
        const textParts = inputText.split("'").filter((part) => part.length > 0);
        return candidates.flatMap((item): Lexicon[] => {
            const syllables = InputMemory.stripTones(item.romanization ?? "").split(/\s+/).filter((part) => part.length > 0);
            if (syllables.join("\u0000") === textParts.join("\u0000")) return [InputMemory.replacedLexicon(item, inputText)];
            if (inputSeparatorCount === 1 && isTrailingSeparator) {
                return syllables.length === 1 && item.inputCount === keys.length - 1 ? [InputMemory.replacedLexicon(item, inputText)] : [];
            }
            if (inputSeparatorCount === 1) {
                if (syllables.length !== 2) return [];
                const matched = keys.length === 3 || syllables[0] === textParts[0] ||
                    (textParts[0]?.length === 1 && textParts[0] === syllables[0][0] && (textParts[textParts.length - 1]?.startsWith(syllables[1]) ?? false));
                return matched ? [InputMemory.replacedLexicon(item, inputText)] : [];
            }
            if (inputSeparatorCount === 2 && isTrailingSeparator) {
                if (syllables.length !== 2 || item.inputCount !== keys.length - 2) return [];
                const matched = keys.length === 4 || syllables[0] === textParts[0] ||
                    (textParts[0]?.length === 1 && textParts[0] === syllables[0][0] && textParts[textParts.length - 1] === syllables[1]);
                return matched ? [InputMemory.replacedLexicon(item, inputText)] : [];
            }
            if ((inputSeparatorCount === 2 && keys.length === 5 && textParts.length === 3) ||
                (inputSeparatorCount === 3 && keys.length === 6 && textParts.length === 3)) {
                return syllables.length === 3 ? [InputMemory.replacedLexicon(item, inputText)] : [];
            }
            return [];
        });
    }

    private static suggestSearch(keys: VirtualInputKey[], segmentation: Segmentation,
        store: relationalStore.RdbStore, syllableStore: relationalStore.RdbStore): Lexicon[] {
        if (keys.length < 1) {
            return [];
        }
        const tailSyllableCache: Record<string, string> = {};
        const inputLength = keys.length;
        const text = InputMemory.keysText(keys);
        const idealSchemes = segmentation.filter((scheme) => InputMemory.schemeLength(scheme) === inputLength);
        const queried = InputMemory.query(segmentation, idealSchemes, store);
        const anchorsMatched = InputMemory.regularSort(InputMemory.anchorsMatch(keys, text, queried.length < 1 ? 20 : 5, store), true)
            .map((item) => InputMemory.toLexicon(item, -1));
        const idealQueried = InputMemory.regularSort(queried.filter((item) => item.inputCount >= inputLength))
            .map((item) => InputMemory.toLexicon(item, -1));
        const notIdealQueried = InputMemory.nineKeyPeculiarSort(queried.filter((item) => item.inputCount < inputLength))
            .map((item) => InputMemory.toLexicon(item, -2));
        if (idealQueried.length > 0 || anchorsMatched.length > 0) {
            return [...idealQueried, ...anchorsMatched, ...notIdealQueried];
        }
        const partialMatched = InputMemory.partialMatch(keys, text, inputLength, segmentation, idealSchemes, store, syllableStore, tailSyllableCache);
        return [...partialMatched, ...notIdealQueried];
    }

    private static partialMatch(keys: VirtualInputKey[], text: string, inputLength: number, segmentation: Segmentation,
        idealSchemes: Scheme[], store: relationalStore.RdbStore, syllableStore: relationalStore.RdbStore,
        tailSyllableCache: Record<string, string>): Lexicon[] {
        const shouldPartiallyMatch = inputLength > 2 && inputLength <= InputMemory.maxPartialInputLength && (idealSchemes.length < 1 ||
            keys[0] === VirtualInputKey.letterM || keys[inputLength - 1] === VirtualInputKey.letterM);
        if (!shouldPartiallyMatch) {
            return [];
        }
        const prefixMatched: InternalLexicon[] = segmentation.flatMap((scheme) => {
            if (scheme.length < 1 || scheme.length > 9) {
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
            const tailAsAnchorText = tail.map((key) => CharCode.normalizeAnchorKey(key).text).join("");
            const conjoinedMatched = InputMemory.anchorsMatch([...schemeAnchors, ...tail], conjoinedText, InputMemory.partialShortcutLimit, store)
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
            const anchors = [...schemeAnchors, tail[0]] as VirtualInputKey[];
            const anchorsMatched = InputMemory.anchorsMatch(anchors, InputMemory.keysText(anchors), InputMemory.partialShortcutLimit, store)
                .flatMap((item) => {
                    if (!InputMemory.stripTones(item.romanization).startsWith(syllableText)) {
                        return [];
                    }
                    return [InputMemory.replacedInput(item, text, mark)];
                });
            return [...conjoinedMatched, ...anchorsMatched];
        });
        const gainedMatched: InternalLexicon[] = InputMemory.descendingInputLengths(inputLength)
            .filter((length) => length <= 9)
            .flatMap((length) => {
                return InputMemory.anchorsMatch(keys.slice(0, length), undefined, InputMemory.gainedShortcutLimit, store);
            })
            .flatMap((item) => {
                const tail = keys.slice(item.inputCount - 1);
                if (tail.length > 6) {
                    return [];
                }
                const converted = InputMemory.replacedInput(item, text, text);
                if (InputMemory.letterText(item.romanization).startsWith(text)) {
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

    private static query(segmentation: Segmentation, idealSchemes: Scheme[], store: relationalStore.RdbStore): InternalLexicon[] {
        if (segmentation.length < 1) {
            return [];
        }
        if (idealSchemes.length < 1) {
            return segmentation.flatMap((scheme) => InputMemory.perform(scheme, store));
        }
        return idealSchemes.flatMap((scheme) => {
            const queried: InternalLexicon[] = [];
            for (let index = scheme.length; index >= 1; index--) {
                queried.push(...InputMemory.perform(scheme.slice(0, index), store, index === scheme.length ? 20 : 5));
            }
            return queried;
        });
    }

    private static perform(scheme: Scheme, store: relationalStore.RdbStore, limit: number = 5): InternalLexicon[] {
        return InputMemory.spellMatch(
            scheme.flatMap((syllable) => syllable.origin),
            EngineCode.complexity(scheme.map((syllable) => syllable.origin.length)),
            InputMemory.schemeAliasText(scheme),
            InputMemory.schemeMark(scheme),
            limit,
            store
        );
    }

    private static anchorsMatch(keys: VirtualInputKey[], input: string | undefined, limit: number, store: relationalStore.RdbStore): InternalLexicon[] {
        const code = EngineCode.keys(keys.map((key) => CharCode.normalizeAnchorKey(key)));
        const lexicons: InternalLexicon[] = [];
        const command: string = "SELECT word, romanization, frequency, latest FROM memory2608 WHERE anchors = CAST(? AS INTEGER) AND char_count = ? ORDER BY frequency DESC LIMIT ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [code, keys.length, limit]);
            while (res.goToNextRow()) {
                const word = res.getString(0);
                const romanization = res.getString(1);
                const frequency = res.getLong(2);
                const latest = res.getLong(3);
                if (InputMemory.containsNonIdeographic(word)) { continue; }
                lexicons.push(InputMemory.makeInternalLexicon(word, romanization, frequency, latest, input ?? InputMemory.keysText(keys), input ?? InputMemory.keysText(keys)));
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

    private static spellMatch(keys: VirtualInputKey[], complexity: string | undefined, input: string | undefined,
        mark: string | undefined, limit: number, store: relationalStore.RdbStore): InternalLexicon[] {
        const code = EngineCode.keys(keys);
        const lexicons: InternalLexicon[] = [];
        const command: string = complexity === undefined ?
            "SELECT word, romanization, frequency, latest FROM memory2608 WHERE spell = CAST(? AS INTEGER) AND letter_count = ? ORDER BY frequency DESC LIMIT ?;" :
            "SELECT word, romanization, frequency, latest FROM memory2608 WHERE spell = CAST(? AS INTEGER) AND letter_count = ? AND complexity = CAST(? AS INTEGER) ORDER BY frequency DESC LIMIT ?;";
        const parameters: relationalStore.ValueType[] = complexity === undefined ? [code, keys.length, limit] : [code, keys.length, complexity, limit];
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, parameters);
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
                    input ?? InputMemory.keysText(keys),
                    mark ?? InputMemory.stripTones(romanization)
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

    static nineKeySearch(combos: Combo[], segmentation: NineKeySegmentation, store: relationalStore.RdbStore): Lexicon[] {
        if (InputMemory.isMigrating) {
            return [];
        }
        if (combos.length < 1 || combos.some((combo) => combo.isSpecial)) {
            return [];
        }
        const inputLength = combos.length;
        if (inputLength <= 1) {
            return InputMemory.nineKeyAnchorsMatch(combos, store)
                .map((item) => InputMemory.toLexicon(item, -1));
        }
        const anchorsMatched = InputMemory.regularSort(InputMemory.nineKeyAnchorsMatch(combos, store), true);
        const queried = InputMemory.regularSort(InputMemory.nineKeyQuery(inputLength, segmentation, store));
        const fullMatched = InputMemory.regularSort(queried.filter((item) => item.inputCount >= inputLength));
        const ideal = InputMemory.distinctInternalLexicons([
            ...fullMatched.slice(0, 10),
            ...InputMemory.regularSort([...fullMatched, ...anchorsMatched.slice(0, 5)])
        ]).map((item) => InputMemory.toLexicon(item, -1));
        const notIdeal = InputMemory.nineKeyQueriedLexicons(queried.filter((item) => item.inputCount < inputLength));
        return [...ideal, ...notIdeal];
    }

    private static nineKeyQuery(inputLength: number, segmentation: NineKeySegmentation, store: relationalStore.RdbStore): InternalLexicon[] {
        const idealSchemes = segmentation.filter((scheme) => InputMemory.nineKeySchemeLength(scheme) === inputLength);
        if (idealSchemes.length < 1) {
            return segmentation.flatMap((scheme) => InputMemory.nineKeyPerform(scheme, store, 10));
        }
        return idealSchemes.flatMap((scheme) => {
            if (scheme.length === 1) return InputMemory.nineKeyPerform(scheme, store, 20);
            const items: InternalLexicon[] = [];
            for (let index = scheme.length; index >= 1; index--) items.push(...InputMemory.nineKeyPerform(scheme.slice(0, index), store, index === scheme.length ? 30 : 10));
            return items;
        });
    }

    private static nineKeySchemeLength(scheme: NineKeyScheme): number {
        return scheme.reduce((total, syllable) => total + syllable.alias.length, 0);
    }

    private static nineKeyPerform(scheme: NineKeyScheme, store: relationalStore.RdbStore, limit: number): InternalLexicon[] {
        if (scheme.length < 1) return [];
        const complexity = EngineCode.complexity(scheme.map((syllable) => syllable.origin.length));
        if (scheme.some((syllable) => syllable.isIrregular)) {
            return InputMemory.spellMatch(scheme.flatMap((syllable) => syllable.serialOrigin), complexity, undefined, undefined, limit, store);
        }
        return InputMemory.nineKeySpellMatch(scheme.flatMap((syllable) => syllable.origin), complexity, store, limit);
    }

    private static nineKeyAnchorsMatch(combos: Combo[], store: relationalStore.RdbStore, limit: number = 50): InternalLexicon[] {
        if (combos.length < 1) return [];
        const code = EngineCode.combos(combos);
        const lexicons: InternalLexicon[] = [];
        const command: string = "SELECT word, romanization, frequency, latest FROM memory2608 WHERE anchors_9key = CAST(? AS INTEGER) AND char_count = ? ORDER BY frequency DESC LIMIT ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [code, combos.length, limit]);
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

    private static nineKeySpellMatch(digits: number[], complexity: string, store: relationalStore.RdbStore, limit: number = 50): InternalLexicon[] {
        if (digits.length < 1) return [];
        const code = EngineCode.decimalOverflowed(digits).toString();
        const lexicons: InternalLexicon[] = [];
        const command: string = "SELECT word, romanization, frequency, latest FROM memory2608 WHERE spell_9key = CAST(? AS INTEGER) AND letter_count = ? AND complexity = CAST(? AS INTEGER) ORDER BY frequency DESC LIMIT ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [code, digits.length, complexity, limit]);
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
        InputMemory.ensureMemoryTable(store);
        InputMemory.ensureMemoryIndexes(store);
        InputMemory.ensureLegacyLatestColumn(store);
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
        const command: string = "SELECT frequency FROM memory2608 WHERE word = ? AND romanization = ? LIMIT 1;";
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
        const command: string = "UPDATE memory2608 SET frequency = ?, latest = ? WHERE word = ? AND romanization = ?;";
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
        const command: string = "INSERT INTO memory2608 (word, romanization, frequency, latest, char_count, letter_count, complexity, anchors, spell, anchors_9key, spell_9key) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);";
        try {
            store.executeSync(command, [entry.word, entry.romanization, entry.frequency, entry.latest, entry.charCount, entry.letterCount, entry.complexity, entry.anchors, entry.spell, entry.nineKeyAnchors, entry.nineKeySpell]);
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        }
    }
}
