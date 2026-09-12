import { relationalStore } from "@kit.ArkData";
import { BusinessError } from "@kit.BasicServicesKit";
import { VirtualInputKey } from "./VirtualInputKey";
import { Lexicon } from "./Lexicon";
import { LexiconType } from "./LexiconType";
import { Scheme, Segmentation, Segmenter } from "./Segmenter";
import { CharCode } from "./CharCode";

import { EngineCode } from "./EngineCode";
import { ExtraEntry } from "./ExtraEntry";
import { InputFilter } from "./InputFilter";

export class Engine {
    private static readonly concatenationStep: number = 1000000;
    private static readonly defaultAnchorsLimit: number = 100;
    private static readonly defaultSpellLimit: number = -1;
    private static readonly gainedShortcutLimit: number = 300;

    private static keysText(keys: VirtualInputKey[]): string {
        return CharCode.keysText(keys);
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

    private static schemeLength(scheme: Scheme): number {
        return scheme.reduce((acc, syllable) => acc + syllable.alias.length, 0);
    }

    private static schemeAliasText(scheme: Scheme): string {
        return Engine.keysText(scheme.flatMap((syllable) => syllable.alias));
    }

    private static schemeOriginText(scheme: Scheme): string {
        return Engine.keysText(scheme.flatMap((syllable) => syllable.origin));
    }

    private static schemeMark(scheme: Scheme): string {
        return scheme.map((syllable) => Engine.keysText(syllable.alias)).join(" ");
    }

    private static schemeSyllableText(scheme: Scheme): string {
        return scheme.map((syllable) => Engine.keysText(syllable.origin)).join(" ");
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

    private static makeLexicon(text: string, romanization: string, input: string, inputCount: number, number: number, mark?: string): Lexicon {
        return {
            type: LexiconType.Cantonese,
            text: text,
            romanization: romanization,
            input: input,
            inputCount: inputCount,
            number: number,
            mark: mark,
        };
    }

    private static replacedInput(item: Lexicon, input: string, mark?: string): Lexicon {
        return {
            type: item.type,
            text: item.text,
            romanization: item.romanization,
            input: input,
            inputCount: input.length,
            number: item.number,
            mark: mark,
            note: item.note,
        };
    }

    private static concatenateLexicons(lhs: Lexicon, rhs: Lexicon): Lexicon {
        const lhsRomanization = lhs.romanization ?? "";
        const rhsRomanization = rhs.romanization ?? "";
        const lhsMark = lhs.mark ?? lhs.input;
        const rhsMark = rhs.mark ?? rhs.input;
        const input = lhs.input + rhs.input;
        return {
            type: LexiconType.Cantonese,
            text: lhs.text + rhs.text,
            romanization: `${lhsRomanization} ${rhsRomanization}`.trim(),
            input: input,
            inputCount: input.length,
            number: (lhs.number + Engine.concatenationStep) + (rhs.number + Engine.concatenationStep),
            mark: `${lhsMark} ${rhsMark}`.trim(),
        };
    }

    private static lexiconKey(item: Lexicon): string {
        const romanization = item.romanization ?? "";
        return `${item.type}\u0000${item.text}\u0000${romanization}`;
    }

    private static distinctLexicons(items: Lexicon[]): Lexicon[] {
        const handled: Set<string> = new Set();
        const results: Lexicon[] = [];
        for (const item of items) {
            const key = Engine.lexiconKey(item);
            if (handled.has(key)) {
                continue;
            }
            handled.add(key);
            results.push(item);
        }
        return results;
    }

    private static distinctNumbers(values: number[]): number[] {
        const results: number[] = [];
        for (const value of values) {
            if (!results.includes(value)) {
                results.push(value);
            }
        }
        return results;
    }

    private static descendingInputLengths(inputLength: number): number[] {
        const lengths: number[] = [];
        for (let index = inputLength - 1; index >= 1; index--) {
            lengths.push(index);
        }
        return lengths;
    }

    private static compareLexicon(lhs: Lexicon, rhs: Lexicon): number {
        if (lhs.inputCount !== rhs.inputCount) {
            return rhs.inputCount - lhs.inputCount;
        }
        return lhs.number - rhs.number;
    }

    private static sortLexicons(items: Lexicon[]): Lexicon[] {
        return [...items].sort((lhs, rhs) => Engine.compareLexicon(lhs, rhs));
    }

    private static sortLexiconsByNumber(items: Lexicon[]): Lexicon[] {
        return [...items].sort((lhs, rhs) => lhs.number - rhs.number);
    }

    private static matchedTailSyllable(keys: VirtualInputKey[], store: relationalStore.RdbStore, cache: Record<string, string>): string | undefined {
        if (keys.length < 1) {
            return undefined;
        }
        const cacheKey = Engine.keysText(keys);
        const cached = cache[cacheKey];
        if (cached !== undefined) {
            return cached.length > 0 ? cached : undefined;
        }
        const matched = Segmenter.syllableText(keys, store);
        cache[cacheKey] = matched ?? "";
        return matched;
    }

    private static modify(item: Lexicon, keys: VirtualInputKey[], text: string, inputLength: number,
        store: relationalStore.RdbStore, tailSyllableCache: Record<string, string>): Lexicon {
        if (inputLength <= 1 || item.inputCount === inputLength) {
            return item;
        }
        const converted = Engine.replacedInput(item, text, text);
        const romanization = item.romanization ?? "";
        if (Engine.stripSpacesAndTones(romanization).startsWith(text)) {
            return converted;
        }
        const syllables = Engine.splitRomanization(romanization);
        const lastSyllable = syllables.length > 0 ? Engine.stripTones(syllables[syllables.length - 1]) : "";
        if (lastSyllable.length < 1) {
            return item;
        }
        const tail = keys.slice(item.inputCount - 1);
        if (tail.length > 6) {
            return item;
        }
        const tailSyllable = Engine.matchedTailSyllable(tail, store, tailSyllableCache);
        if (tailSyllable !== undefined) {
            return lastSyllable === tailSyllable ? converted : item;
        }
        const tailText = Engine.keysText(tail);
        return lastSyllable.startsWith(tailText) ? converted : item;
    }

    private static processSlices(keys: VirtualInputKey[], text: string, store: relationalStore.RdbStore, tailSyllableCache: Record<string, string>, limit: number = -1): Lexicon[] {
        const items: Lexicon[] = [];
        for (let length = Math.min(keys.length, 9); length >= 1; length--) {
            const matched = Engine.anchorsMatch(keys.slice(0, length), undefined, store, limit < 0 ? 300 : 100).map((item) => Engine.modify(item, keys, text, keys.length, store, tailSyllableCache));
            items.push(...Engine.sortLexicons(matched).slice(0, 50));
        }
        return Engine.sortLexicons(Engine.distinctLexicons(items));
    }

    static suggest(keys: VirtualInputKey[], segmentation: Segmentation, store: relationalStore.RdbStore): Lexicon[] {
        if (keys.length === 0) return [];
        if (keys.length === 1) {
            const text = keys[0].text;
            if (text === "a") return [...Engine.spellMatch("a", text, 1, store), ...Engine.spellMatch("aa", text, 1, store), ...Engine.anchorsMatch(keys, text, store)];
            if (text === "o" || text === "m") return [...Engine.spellMatch(text, text, 1, store), ...Engine.anchorsMatch(keys, text, store)];
            return Engine.anchorsMatch(keys, text, store);
        }
        const letters = keys.filter((key) => key.isSyllableLetter);
        const firstLength = segmentation[0]?.[0]?.alias.length ?? 0;
        let items: Lexicon[];
        if (firstLength === 0) {
            items = [...ExtraEntry.search(keys), ...Engine.processSlices(letters, CharCode.keysText(letters), store, {})];
        } else {
            items = Engine.search(letters, segmentation, store);
            if ((firstLength === 1 && letters.length > 1) || letters.length !== keys.length) items.push(...Engine.processSlices(letters, CharCode.keysText(letters), store, {}));
        }
        const filtered = InputFilter.filter(keys, items);
        if (filtered.length > 0 || !keys.some((key) => key.isApostrophe) || keys.some((key) => key.isToneLetter || key.isToneNumber) || keys[0].isApostrophe) return filtered;
        const parts = CharCode.keysText(keys).split("'").filter((part) => part.length > 0);
        const anchors = parts.map((part) => VirtualInputKey.matchVirtualKey(CharCode.interCode(part[0]) ?? 0)).filter((key) => key !== undefined) as VirtualInputKey[];
        return Engine.anchorsMatch(anchors, undefined, store).filter((item) => {
            const syllables = (item.romanization ?? "").replace(/[1-6]/g, "").split(" ");
            return syllables.length === parts.length && parts.every((part, index) => part.length === 1 ? syllables[index].startsWith(part) : syllables[index] === part);
        }).map((item) => Engine.replacedInput(item, CharCode.keysText(keys)));
    }

    private static search(keys: VirtualInputKey[], segmentation: Segmentation, store: relationalStore.RdbStore, limit: number = -1): Lexicon[] {
        if (keys.length < 1) {
            return [];
        }
        const tailSyllableCache: Record<string, string> = {};
        const inputLength = keys.length;
        const text = Engine.keysText(keys);
        const anchorsMatched = Engine.anchorsMatch(keys, text, store, limit < 0 ? 100 : limit);
        const queried = Engine.query(inputLength, segmentation, store, limit);
        const hasIdealQueried = queried.some((item) => item.inputCount === inputLength);
        const hasIdealSegmentation = segmentation.some((scheme) => Engine.schemeLength(scheme) === inputLength);
        const startsOrEndsWithM = keys[0] === VirtualInputKey.letterM || keys[inputLength - 1] === VirtualInputKey.letterM;
        const shouldMatchPrefixes = inputLength > 2 && inputLength < 25 && (startsOrEndsWithM || (!hasIdealQueried && !hasIdealSegmentation));
        const prefixMatched: Lexicon[] = shouldMatchPrefixes ? segmentation.flatMap((scheme) => {
            if (scheme.length < 1 || scheme.length > 9) {
                return [];
            }
            const handledLength = Engine.schemeLength(scheme);
            const tail = keys.slice(handledLength);
            const lastAnchor = tail[0];
            if (lastAnchor === undefined) {
                return [];
            }
            const schemeAnchors = Engine.schemeAliasAnchors(scheme);
            const conjoined = [...schemeAnchors, ...tail];
            const anchors = [...schemeAnchors, lastAnchor];
            const schemeSyllableText = Engine.schemeSyllableText(scheme);
            const mark = `${Engine.schemeMark(scheme)} ${Engine.keysText(tail)}`.trim();
            const tailAsAnchorText = tail.map((key) => Engine.normalizeAnchorKey(key).text).join("");
            const conjoinedMatched = Engine.anchorsMatch(conjoined, undefined, store, limit < 0 ? 500 : 200)
                .flatMap((item) => {
                    const romanization = item.romanization ?? "";
                    const toneFreeRomanization = Engine.stripTones(romanization);
                    if (!toneFreeRomanization.startsWith(schemeSyllableText)) {
                        return [];
                    }
                    const suffixText = toneFreeRomanization.slice(schemeSyllableText.length).trim();
                    const suffixAnchorText = suffixText.length < 1 ? "" :
                        suffixText.split(/\s+/).map((part) => part[0]).join("");
                    if (suffixAnchorText !== tailAsAnchorText) {
                        return [];
                    }
                    return [Engine.replacedInput(item, text, mark)];
                });
            const transformedTailText = tail.map((key, index) => {
                return index === 0 && key === VirtualInputKey.letterY ? VirtualInputKey.letterJ.text : key.text;
            }).join("");
            const syllables = `${schemeSyllableText} ${transformedTailText}`.trim();
            const leadingAnchorsMatched = Engine.anchorsMatch(anchors, undefined, store, limit < 0 ? 500 : 200)
                .flatMap((item) => {
                    const romanization = item.romanization ?? "";
                    if (!Engine.stripTones(romanization).startsWith(syllables)) {
                        return [];
                    }
                    return [Engine.replacedInput(item, text, mark)];
                });
            return [...conjoinedMatched, ...leadingAnchorsMatched];
        }) : [];
        const gainedMatched: Lexicon[] = shouldMatchPrefixes ? Engine.descendingInputLengths(inputLength)
            .flatMap((length) => {
                const leadingKeys = keys.slice(0, length);
                const leadingText = Engine.keysText(leadingKeys);
                return Engine.anchorsMatch(leadingKeys, leadingText, store, Engine.gainedShortcutLimit);
            }).flatMap((item) => {
                const tail = keys.slice(item.inputCount - 1);
                if (tail.length > 6) {
                    return [];
                }
                const converted = Engine.replacedInput(item, text, text);
                const romanization = item.romanization ?? "";
                if (Engine.stripSpacesAndTones(romanization).startsWith(text)) {
                    return [converted];
                }
                const syllables = Engine.splitRomanization(romanization);
                const lastSyllable = syllables.length > 0 ? Engine.stripTones(syllables[syllables.length - 1]) : "";
                if (lastSyllable.length < 1) {
                    return [];
                }
                const tailSyllable = Engine.matchedTailSyllable(tail, store, tailSyllableCache);
                if (tailSyllable !== undefined) {
                    return lastSyllable === tailSyllable ? [converted] : [];
                }
                const tailText = Engine.keysText(tail);
                return lastSyllable.startsWith(tailText) ? [converted] : [];
            }) : [];
        const idealQueried = Engine.distinctLexicons(
            Engine.sortLexiconsByNumber(queried.filter((item) => item.inputCount === inputLength))
        );
        const notIdealQueried = Engine.distinctLexicons(
            Engine.sortLexicons(queried.filter((item) => item.inputCount < inputLength))
        );
        const fullInput = Engine.distinctLexicons([
            ...idealQueried,
            ...(idealQueried.length === 0 ? ExtraEntry.search(keys) : []),
            ...anchorsMatched,
            ...prefixMatched,
            ...gainedMatched,
        ]);
        const primary = fullInput.slice(0, 10);
        const secondary = Engine.sortLexicons(fullInput).slice(0, 10);
        const tertiary = notIdealQueried.slice(0, 10);
        const quaternary = Engine.sortLexiconsByNumber(notIdealQueried).slice(0, 10);
        const fetched = Engine.distinctLexicons([
            ...primary,
            ...secondary,
            ...tertiary,
            ...quaternary,
            ...fullInput,
            ...notIdealQueried,
        ]);
        if (fetched.length === 0) return Engine.processSlices(keys, text, store, tailSyllableCache, limit);
        const mergedFetched = fetched;
        if (fetched[0].inputCount >= inputLength) return fetched;
        const headInputLengths = Engine.distinctNumbers(fetched.map((item) => item.inputCount));
        const concatenated = Engine.sortLexicons(
            Engine.distinctLexicons(headInputLengths.flatMap((headLength) => {
                const tailKeys = keys.slice(headLength);
                const tailSegmentation = Segmenter.segment(tailKeys, store);
                const tailLexicon = Engine.search(tailKeys, tailSegmentation, store, 50)[0];
                const headLexicon = mergedFetched.find((item) => item.inputCount === headLength);
                if (tailLexicon === undefined || headLexicon === undefined) {
                    return [];
                }
                return [Engine.concatenateLexicons(headLexicon, tailLexicon)];
            }))
        ).slice(0, 1);
        return [...concatenated, ...mergedFetched];
    }

    private static query(inputLength: number, segmentation: Segmentation, store: relationalStore.RdbStore, limit: number): Lexicon[] {
        const idealSchemes = segmentation.filter((scheme) => Engine.schemeLength(scheme) === inputLength);
        if (idealSchemes.length < 1) {
            return segmentation.flatMap((scheme) => Engine.perform(scheme, store, limit));
        } else {
            return idealSchemes.flatMap((scheme) => {
                switch (scheme.length) {
                    case 0:
                        return Array<Lexicon>();
                    case 1:
                        return Engine.perform(scheme, store, limit);
                    default:
                        return scheme.map((_, index) => scheme.slice(0, scheme.length - index))
                            .flatMap((sliced) => Engine.perform(sliced, store, limit));
                }
            });
        }
    }

    private static perform(scheme: Scheme, store: relationalStore.RdbStore, limit: number): Lexicon[] {
        if (scheme.length === 0 || scheme.length > 9) return [];
        return Engine.spellMatch(Engine.schemeOriginText(scheme), Engine.schemeAliasText(scheme), Engine.schemeLength(scheme), store, limit, Engine.schemeMark(scheme), EngineCode.complexity(scheme.map((syllable) => syllable.origin.length)));
    }

    private static anchorsMatch(keys: VirtualInputKey[], input: string | undefined, store: relationalStore.RdbStore, limit: number = Engine.defaultAnchorsLimit, mark?: string): Lexicon[] {
        const code = EngineCode.keys(keys.map((key) => CharCode.normalizeAnchorKey(key)));
        if (keys.length === 0 || keys.length > 9) {
            return [];
        }
        const text = input ?? Engine.keysText(keys);
        const inputCount = text.length;
        const lexicons: Lexicon[] = [];
        const command: string = "SELECT rowid, word, romanization FROM lexicon_core WHERE anchors = CAST(? AS INTEGER) AND char_count = ? ORDER BY rowid LIMIT ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [code, keys.length, limit]);
            while (res.goToNextRow()) {
                const rowID = res.getLong(0);
                const word = res.getString(1);
                const romanization = res.getString(2);
                lexicons.push(Engine.makeLexicon(word, romanization, text, inputCount, rowID, mark ?? text));
            }
        } catch (error) {
            const err: BusinessError = error as BusinessError;
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

    private static spellMatch(text: string, input: string, inputCount: number, store: relationalStore.RdbStore,
        limit: number = Engine.defaultSpellLimit, mark?: string, complexity?: string): Lexicon[] {
        const lexicons: Lexicon[] = [];
        const code = EngineCode.text(text);
        const command: string = "SELECT rowid, word, romanization FROM lexicon_core WHERE spell = CAST(? AS INTEGER) AND complexity = CAST(? AS INTEGER) ORDER BY rowid LIMIT ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [code, complexity ?? text.length.toString(), limit]);
            while (res.goToNextRow()) {
                const rowID = res.getLong(0);
                const word = res.getString(1);
                const romanization = res.getString(2);
                const markText: string = mark ?? Engine.stripTones(romanization);
                lexicons.push(Engine.makeLexicon(word, romanization, input, inputCount, rowID, markText));
            }
        } catch (error) {
            const err: BusinessError = error as BusinessError;
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

    static test(store: relationalStore.RdbStore): number {
        let num: number = -1;
        const command: string = "SELECT rowid FROM lexicon_core WHERE anchors = 32 AND char_count = 1 ORDER BY rowid LIMIT 1;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command);
            if (res.goToFirstRow()) {
                num = res.getLong(0);
            }
        } catch (error) {
            const err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            try {
                res?.close();
            } catch (error) {
                const err: BusinessError = error as BusinessError;
                console.error(`message: ${err.message}, code: ${err.code}`);
            }
        }
        return num;
    }
}
