import { relationalStore } from "@kit.ArkData";
import { BusinessError } from "@kit.BasicServicesKit";
import { Candidate } from "./Candidate";
import { FallbackLexiconHelper } from "./FallbackLexiconHelper";
import { FallbackT2SHelper } from "./FallbackT2SHelper";
import { VirtualInputKey } from "./VirtualInputKey";
import { Lexicon } from "./Lexicon";
import { LexiconType } from "./LexiconType";
import { Segmentation, Scheme, Segmenter } from "./Segmenter";

interface InternalLexicon {
    readonly word: string;
    readonly romanization: string;
    readonly frequency: number;
    readonly latest: number;
    readonly input: string;
    readonly inputCount: number;
    readonly mark: string;
}

export class InputMemory {
    private static readonly recentIntervalMilliseconds: number = 86400000;
    private static readonly defaultSpellLimit: number = 20;
    private static readonly defaultShortcutLimit: number = 20;
    private static readonly defaultStrictLimit: number = 20;
    private static readonly partialShortcutLimit: number = 300;
    private static readonly gainedShortcutLimit: number = 300;
    private static readonly maxPartialInputLength: number = 10;

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
        return keys.map((key) => key.text).join("");
    }

    private static normalizeShortcutText(text: string): string {
        return text.replace(/y/g, "j");
    }

    private static normalizeAnchorKey(key: VirtualInputKey): VirtualInputKey {
        return (key === VirtualInputKey.letterY) ? VirtualInputKey.letterJ : key;
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

    private static memoryHasLatestColumn(store: relationalStore.RdbStore): boolean {
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
            res?.close();
        }
        return false;
    }

    private static ensureLatestColumn(store: relationalStore.RdbStore) {
        if (InputMemory.memoryHasLatestColumn(store)) {
            return;
        }
        const command = "ALTER TABLE memory ADD COLUMN latest INTEGER NOT NULL DEFAULT 0;";
        try {
            store.executeSync(command);
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`error in ensureLatestColumn(), message: ${err.message}, code: ${err.code}`);
        }
    }

    static search(keys: VirtualInputKey[], store: relationalStore.RdbStore): Lexicon[] {
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
        if (fullMatched.length > 0 || idealQueried.length > 0) {
            return [...InputMemory.idealLexicons([...fullMatched, ...idealQueried], inputLength), ...queried];
        }
        const shortcuts = InputMemory.shortcutMatch(text, text, store, 5);
        if (shortcuts.length > 0) {
            return [...InputMemory.idealLexicons(shortcuts, inputLength), ...queried];
        }
        if (!deepSearch) {
            return queried;
        }
        const shouldPartiallyMatch = inputLength <= InputMemory.maxPartialInputLength && (idealSchemes.length < 1 || keys[0] === VirtualInputKey.letterM ||
            keys[inputLength - 1] === VirtualInputKey.letterM);
        if (!shouldPartiallyMatch) {
            return queried;
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
        const partialMatched = InputMemory.distinctInternalLexicons(
            InputMemory.advancedSort([...prefixMatched, ...gainedMatched], inputLength)
        ).slice(0, 5).map((item) => InputMemory.toLexicon(item, -1));
        return [...partialMatched, ...queried];
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
        const command: string = "SELECT word, romanization, frequency, latest FROM memory WHERE shortcut = ? ORDER BY frequency DESC, latest DESC LIMIT ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [code, limit]);
            while (res.goToNextRow()) {
                const word = res.getString(0);
                const romanization = res.getString(1);
                const frequency = res.getLong(2);
                const latest = res.getLong(3);
                lexicons.push(InputMemory.makeInternalLexicon(word, romanization, frequency, latest, input, mark ?? input));
            }
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            res?.close();
        }
        return lexicons;
    }

    private static spellMatch(text: string, input: string, store: relationalStore.RdbStore,
        limit: number = InputMemory.defaultSpellLimit, mark?: string): InternalLexicon[] {
        const code = InputMemory.hashCode(text);
        const lexicons: InternalLexicon[] = [];
        const command: string = "SELECT word, romanization, frequency, latest FROM memory WHERE ping = ? ORDER BY frequency DESC, latest DESC LIMIT ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [code, limit]);
            while (res.goToNextRow()) {
                const word = res.getString(0);
                const romanization = res.getString(1);
                const frequency = res.getLong(2);
                const latest = res.getLong(3);
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
            res?.close();
        }
        return lexicons;
    }

    private static strictMatch(spell: number, shortcut: number, input: string, store: relationalStore.RdbStore,
        mark?: string, limit: number = InputMemory.defaultStrictLimit): InternalLexicon[] {
        const lexicons: InternalLexicon[] = [];
        const command: string = "SELECT word, romanization, frequency, latest FROM memory WHERE ping = ? AND shortcut = ? ORDER BY frequency DESC, latest DESC LIMIT ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [spell, shortcut, limit]);
            while (res.goToNextRow()) {
                const word = res.getString(0);
                const romanization = res.getString(1);
                const frequency = res.getLong(2);
                const latest = res.getLong(3);
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
            res?.close();
        }
        return lexicons;
    }

    static prepare(store: relationalStore.RdbStore) {
        try {
            const command: string = "CREATE TABLE IF NOT EXISTS memory(word TEXT NOT NULL, romanization TEXT NOT NULL, frequency INTEGER NOT NULL, latest INTEGER NOT NULL DEFAULT 0, shortcut INTEGER NOT NULL, ping INTEGER NOT NULL);";
            store.executeSync(command);
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`error in prepare(), message: ${err.message}, code: ${err.code}`)
        }
        InputMemory.ensureLatestColumn(store);
        try {
            const command: string = "CREATE TABLE IF NOT EXISTS fallback(word TEXT NOT NULL, romanization TEXT NOT NULL, shortcut INTEGER NOT NULL, ping INTEGER NOT NULL);";
            store.executeSync(command);
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`error in prepare(), message: ${err.message}, code: ${err.code}`)
        }
        try {
            const command: string = "CREATE TABLE IF NOT EXISTS variant_sim(left INTEGER NOT NULL, right INTEGER NOT NULL);";
            store.executeSync(command);
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`error in prepare(), message: ${err.message}, code: ${err.code}`)
        }
        InputMemory.prepareFallbackTables(store);
    }
    static process(candidates: Candidate[], store: relationalStore.RdbStore) {
        const text: string = candidates.map(item => item.lexicon.text).join("");
        const romanization: string = candidates.map(item => item.lexicon.romanization ?? "").join(" ");
        const concatenated: Lexicon = {
            type: LexiconType.Cantonese,
            text: text,
            romanization: romanization,
            input: "i",
            inputCount: 1,
            number: 0
        }
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
        const command: string = "SELECT frequency FROM memory WHERE word = ? AND romanization = ? LIMIT 1;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [lexicon.text, romanization]);
            if (res.goToNextRow()) {
                frequency = res.getLong(0);
            }
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            res?.close();
        }
        return frequency;
    }
    private static update(lexicon: Lexicon, newFrequency: number, store: relationalStore.RdbStore) {
        const romanization = lexicon.romanization ?? "X";
        const latest = InputMemory.nowMilliseconds();
        const command: string = "UPDATE memory SET frequency = ?, latest = ? WHERE word = ? AND romanization = ?;";
        try {
            store.executeSync(command, [newFrequency, latest, lexicon.text, romanization]);
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        }
    }
    private static insert(lexicon: Lexicon, store: relationalStore.RdbStore) {
        const romanization = lexicon.romanization ?? "X";
        const anchors = romanization.match(/\b(\w)/g)?.join('') ?? "X";
        const shortcutCode = InputMemory.hashCode(anchors);
        const syllableText = romanization.replace(/[\d\s]/g, '');
        const pingCode = InputMemory.hashCode(syllableText);
        const latest = InputMemory.nowMilliseconds();
        const command: string = "INSERT INTO memory (word, romanization, frequency, latest, shortcut, ping) VALUES (?, ?, ?, ?, ?, ?);";
        try {
            store.executeSync(command, [lexicon.text, romanization, 1, latest, shortcutCode, pingCode]);
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
        const range = [...Array(inputLength)].map((value: number, index: number) => index);
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
            res?.close();
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
            if (res.goToNextRow()) {
                const shortcut = res.getLong(0);
                needs = (shortcut != 110);
            }
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            res?.close();
        }
        return needs;
    }
}
