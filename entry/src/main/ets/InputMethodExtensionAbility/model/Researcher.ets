import { relationalStore } from "@kit.ArkData";
import { BusinessError } from "@kit.BasicServicesKit";
import { VirtualInputKey } from "./VirtualInputKey";
import { Lexicon } from "./Lexicon";
import { LexiconType } from "./LexiconType";
import { Scheme, Segmentation, Segmenter } from "./Segmenter";

export class Researcher {
    private static readonly concatenationStep: number = 1000000;
    private static readonly defaultAnchorsLimit: number = 50;
    private static readonly defaultSpellLimit: number = 50;
    private static readonly defaultStrictLimit: number = 100;
    private static readonly processSliceDepth: number = 6;
    private static readonly processSliceAnchorsLimit: number = 100;
    private static readonly processSliceResultLimit: number = 100;
    private static readonly partialShortcutLimit: number = 300;
    private static readonly gainedShortcutLimit: number = 300;
    private static readonly maxPartialInputLength: number = 10;
    private static readonly maxConcatenatedInputLength: number = 18;

    private static hashCode(str: string): number {
        let hash = 0;
        for (let i = 0; i < str.length; i++) {
            hash = Math.imul(31, hash) + str.charCodeAt(i) | 0;
        }
        return hash;
    }

    private static radix100Combined(numbers: number[]): number {
        if (numbers.length > 8) {
            // Max value: 9007199254740992
            return 0;
        } else {
            return numbers.reduce((acc, num) => acc * 100 + num, 0);
        }
    }

    private static keysText(keys: VirtualInputKey[]): string {
        return keys.map((key) => key.text).join("");
    }

    private static normalizeAnchorKey(key: VirtualInputKey): VirtualInputKey {
        return (key === VirtualInputKey.letterY) ? VirtualInputKey.letterJ : key;
    }

    private static anchorsCode(keys: VirtualInputKey[]): number {
        const codes = keys.map((key) => Researcher.normalizeAnchorKey(key).code);
        return Researcher.radix100Combined(codes);
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
        return Researcher.keysText(scheme.flatMap((syllable) => syllable.alias));
    }

    private static schemeOriginText(scheme: Scheme): string {
        return Researcher.keysText(scheme.flatMap((syllable) => syllable.origin));
    }

    private static schemeMark(scheme: Scheme): string {
        return scheme.map((syllable) => Researcher.keysText(syllable.alias)).join(" ");
    }

    private static schemeSyllableText(scheme: Scheme): string {
        return scheme.map((syllable) => Researcher.keysText(syllable.origin)).join(" ");
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
            number: (lhs.number + Researcher.concatenationStep) + (rhs.number + Researcher.concatenationStep),
            mark: `${lhsMark} ${rhsMark}`.trim(),
        };
    }

    private static lexiconKey(item: Lexicon): string {
        const romanization = item.romanization ?? "";
        return `${item.type}\u0000${item.text}\u0000${romanization}`;
    }

    private static distinctLexicons(items: Lexicon[]): Lexicon[] {
        const handled: string[] = [];
        const results: Lexicon[] = [];
        for (const item of items) {
            const key = Researcher.lexiconKey(item);
            if (handled.includes(key)) {
                continue;
            }
            handled.push(key);
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
        return [...items].sort((lhs, rhs) => Researcher.compareLexicon(lhs, rhs));
    }

    private static sortLexiconsByNumber(items: Lexicon[]): Lexicon[] {
        return [...items].sort((lhs, rhs) => lhs.number - rhs.number);
    }

    private static matchedTailSyllable(keys: VirtualInputKey[], store: relationalStore.RdbStore, cache: Record<string, string>): string | undefined {
        if (keys.length < 1) {
            return undefined;
        }
        const cacheKey = Researcher.keysText(keys);
        const cached = cache[cacheKey];
        if (cached !== undefined) {
            return cached.length > 0 ? cached : undefined;
        }
        const matched = Researcher.queryIdealSingleSyllable(keys, store);
        if (matched === undefined) {
            cache[cacheKey] = "";
            return undefined;
        }
        const originText = Researcher.schemeOriginText(matched);
        cache[cacheKey] = originText;
        return originText;
    }

    private static queryIdealSingleSyllable(keys: VirtualInputKey[], store: relationalStore.RdbStore): Scheme | undefined {
        const segmentation = keys.length < 1 ? [] : Segmenter.segment(keys, store);
        return segmentation.find((scheme: Scheme) => scheme.length === 1 && Researcher.schemeLength(scheme) === keys.length);
    }

    private static modify(item: Lexicon, keys: VirtualInputKey[], text: string, inputLength: number,
        store: relationalStore.RdbStore, tailSyllableCache: Record<string, string>): Lexicon {
        if (inputLength <= 1 || item.inputCount === inputLength) {
            return item;
        }
        const converted = Researcher.replacedInput(item, text, text);
        const romanization = item.romanization ?? "";
        if (Researcher.stripSpacesAndTones(romanization).startsWith(text)) {
            return converted;
        }
        const syllables = Researcher.splitRomanization(romanization);
        const lastSyllable = syllables.length > 0 ? Researcher.stripTones(syllables[syllables.length - 1]) : "";
        if (lastSyllable.length < 1) {
            return item;
        }
        const tail = keys.slice(item.inputCount - 1);
        if (tail.length > 6) {
            return item;
        }
        const tailSyllable = Researcher.matchedTailSyllable(tail, store, tailSyllableCache);
        if (tailSyllable !== undefined) {
            return lastSyllable === tailSyllable ? converted : item;
        }
        const tailText = Researcher.keysText(tail);
        return lastSyllable.startsWith(tailText) ? converted : item;
    }

    private static processSlices(keys: VirtualInputKey[], text: string, store: relationalStore.RdbStore,
        tailSyllableCache: Record<string, string>): Lexicon[] {
        const inputLength = keys.length;
        const items: Lexicon[] = [];
        const maxDepth = Math.min(inputLength, Researcher.processSliceDepth);
        for (let offset = 0; offset < maxDepth; offset++) {
            const leadingKeys = keys.slice(0, inputLength - offset);
            const leadingText = Researcher.keysText(leadingKeys);
            const spellMatched = Researcher.spellMatch(
                leadingText,
                leadingText,
                leadingKeys.length,
                store,
                Researcher.defaultSpellLimit
            ).map((item) => Researcher.modify(item, keys, text, inputLength, store, tailSyllableCache));
            const anchorsMatched = Researcher.sortLexicons(
                Researcher.anchorsMatch(leadingKeys, leadingText, store, Researcher.processSliceAnchorsLimit)
                    .map((item) => Researcher.modify(item, keys, text, inputLength, store, tailSyllableCache))
            ).slice(0, Researcher.processSliceResultLimit);
            items.push(...spellMatched, ...anchorsMatched);
        }
        return Researcher.sortLexicons(Researcher.distinctLexicons(items));
    }

    static async suggest(keys: VirtualInputKey[], segmentation: Segmentation, store: relationalStore.RdbStore): Promise<Lexicon[]> {
        return Researcher.search(keys, segmentation, store);
    }

    private static search(keys: VirtualInputKey[], segmentation: Segmentation, store: relationalStore.RdbStore): Lexicon[] {
        if (keys.length < 1) {
            return [];
        }
        const tailSyllableCache: Record<string, string> = {};
        const inputLength = keys.length;
        const text = Researcher.keysText(keys);
        const spellMatched = Researcher.spellMatch(text, text, inputLength, store, Researcher.defaultSpellLimit);
        const anchorsMatched = Researcher.anchorsMatch(keys, text, store);
        const queried = Researcher.query(inputLength, segmentation, store);
        const hasIdealQueried = queried.some((item) => item.inputCount === inputLength);
        const hasIdealSegmentation = segmentation.some((scheme) => Researcher.schemeLength(scheme) === inputLength);
        const startsOrEndsWithM = keys[0] === VirtualInputKey.letterM || keys[inputLength - 1] === VirtualInputKey.letterM;
        const shouldMatchPrefixes = inputLength > 2 && inputLength <= Researcher.maxPartialInputLength &&
            spellMatched.length < 1 && !hasIdealQueried &&
            (startsOrEndsWithM || !hasIdealSegmentation);
        const prefixMatched: Lexicon[] = shouldMatchPrefixes ? segmentation.flatMap((scheme) => {
            if (scheme.length < 1) {
                return [];
            }
            const handledLength = Researcher.schemeLength(scheme);
            const tail = keys.slice(handledLength);
            const lastAnchor = tail[0];
            if (lastAnchor === undefined) {
                return [];
            }
            const schemeAnchors = Researcher.schemeAliasAnchors(scheme);
            const conjoined = [...schemeAnchors, ...tail];
            const anchors = [...schemeAnchors, lastAnchor];
            const schemeSyllableText = Researcher.schemeSyllableText(scheme);
            const mark = `${Researcher.schemeMark(scheme)} ${Researcher.keysText(tail)}`.trim();
            const tailAsAnchorText = tail.map((key) => Researcher.normalizeAnchorKey(key).text).join("");
            const conjoinedMatched = Researcher.anchorsMatch(conjoined, undefined, store, Researcher.partialShortcutLimit)
                .flatMap((item) => {
                    const romanization = item.romanization ?? "";
                    const toneFreeRomanization = Researcher.stripTones(romanization);
                    if (!toneFreeRomanization.startsWith(schemeSyllableText)) {
                        return [];
                    }
                    const suffixText = toneFreeRomanization.slice(schemeSyllableText.length).trim();
                    const suffixAnchorText = suffixText.length < 1 ? "" :
                        suffixText.split(/\s+/).map((part) => part[0]).join("");
                    if (suffixAnchorText !== tailAsAnchorText) {
                        return [];
                    }
                    return [Researcher.replacedInput(item, text, mark)];
                });
            const transformedTailText = tail.map((key, index) => {
                return index === 0 && key === VirtualInputKey.letterY ? VirtualInputKey.letterJ.text : key.text;
            }).join("");
            const syllables = `${schemeSyllableText} ${transformedTailText}`.trim();
            const leadingAnchorsMatched = Researcher.anchorsMatch(anchors, undefined, store, Researcher.partialShortcutLimit)
                .flatMap((item) => {
                    const romanization = item.romanization ?? "";
                    if (!Researcher.stripTones(romanization).startsWith(syllables)) {
                        return [];
                    }
                    return [Researcher.replacedInput(item, text, mark)];
                });
            return [...conjoinedMatched, ...leadingAnchorsMatched];
        }) : [];
        const gainedMatched: Lexicon[] = shouldMatchPrefixes ? Researcher.descendingInputLengths(inputLength)
            .flatMap((length) => {
                const leadingKeys = keys.slice(0, length);
                const leadingText = Researcher.keysText(leadingKeys);
                return Researcher.anchorsMatch(leadingKeys, leadingText, store, Researcher.gainedShortcutLimit);
            }).flatMap((item) => {
                const tail = keys.slice(item.inputCount - 1);
                if (tail.length > 6) {
                    return [];
                }
                const converted = Researcher.replacedInput(item, text, text);
                const romanization = item.romanization ?? "";
                if (Researcher.stripSpacesAndTones(romanization).startsWith(text)) {
                    return [converted];
                }
                const syllables = Researcher.splitRomanization(romanization);
                const lastSyllable = syllables.length > 0 ? Researcher.stripTones(syllables[syllables.length - 1]) : "";
                if (lastSyllable.length < 1) {
                    return [];
                }
                const tailSyllable = Researcher.matchedTailSyllable(tail, store, tailSyllableCache);
                if (tailSyllable !== undefined) {
                    return lastSyllable === tailSyllable ? [converted] : [];
                }
                const tailText = Researcher.keysText(tail);
                return lastSyllable.startsWith(tailText) ? [converted] : [];
            }) : [];
        const idealQueried = Researcher.distinctLexicons(
            Researcher.sortLexiconsByNumber(queried.filter((item) => item.inputCount === inputLength))
        );
        const notIdealQueried = Researcher.distinctLexicons(
            Researcher.sortLexicons(queried.filter((item) => item.inputCount < inputLength))
        );
        const fullInput = Researcher.distinctLexicons([
            ...spellMatched,
            ...idealQueried,
            ...anchorsMatched,
            ...prefixMatched,
            ...gainedMatched,
        ]);
        const primary = fullInput.slice(0, 10);
        const secondary = Researcher.sortLexicons(fullInput).slice(0, 10);
        const tertiary = notIdealQueried.slice(0, 10);
        const quaternary = Researcher.sortLexiconsByNumber(notIdealQueried).slice(0, 10);
        const fetched = Researcher.distinctLexicons([
            ...primary,
            ...secondary,
            ...tertiary,
            ...quaternary,
            ...fullInput,
            ...notIdealQueried,
        ]);
        const sliceMatched = segmentation.length < 1 ? Researcher.processSlices(keys, text, store, tailSyllableCache) : [];
        if (fetched.length < 1) {
            return sliceMatched;
        }
        const sliceFallback = sliceMatched.filter((item) => item.inputCount < inputLength);
        const mergedFetched = sliceFallback.length < 1 ? fetched : Researcher.distinctLexicons([...fetched, ...sliceFallback]);
        if (mergedFetched[0].inputCount >= inputLength) {
            return mergedFetched;
        }
        if (inputLength > Researcher.maxConcatenatedInputLength) {
            return mergedFetched;
        }
        const headInputLengths = Researcher.distinctNumbers(mergedFetched.map((item) => item.inputCount)).slice(0, 1);
        const concatenated = Researcher.sortLexicons(
            Researcher.distinctLexicons(headInputLengths.flatMap((headLength) => {
                const tailKeys = keys.slice(headLength);
                const tailSegmentation = Segmenter.segment(tailKeys, store);
                const tailLexicon = Researcher.search(tailKeys, tailSegmentation, store)[0];
                const headLexicon = mergedFetched.find((item) => item.inputCount === headLength);
                if (tailLexicon === undefined || headLexicon === undefined) {
                    return [];
                }
                return [Researcher.concatenateLexicons(headLexicon, tailLexicon)];
            }))
        ).slice(0, 1);
        return [...concatenated, ...mergedFetched];
    }

    private static query(inputLength: number, segmentation: Segmentation, store: relationalStore.RdbStore): Lexicon[] {
        const idealSchemes = segmentation.filter((scheme) => Researcher.schemeLength(scheme) === inputLength);
        if (idealSchemes.length < 1) {
            return segmentation.flatMap((scheme) => Researcher.perform(scheme, store));
        } else {
            return idealSchemes.flatMap((scheme) => {
                switch (scheme.length) {
                    case 0:
                        return Array<Lexicon>();
                    case 1:
                        return Researcher.perform(scheme, store);
                    default:
                        return scheme.map((_, index) => scheme.slice(0, scheme.length - index))
                            .flatMap((sliced) => Researcher.perform(sliced, store));
                }
            });
        }
    }

    private static perform(scheme: Scheme, store: relationalStore.RdbStore): Lexicon[] {
        const anchorKeys: VirtualInputKey[] = [];
        for (const syllable of scheme) {
            const anchor = syllable.origin[0];
            if (anchor !== undefined) {
                anchorKeys.push(anchor);
            }
        }
        const anchorsCode = Researcher.anchorsCode(anchorKeys);
        if (anchorsCode < 1) {
            return [];
        }
        const aliasText = Researcher.schemeAliasText(scheme);
        const inputCount = Researcher.schemeLength(scheme);
        const originText = Researcher.schemeOriginText(scheme);
        const spellCode = Researcher.hashCode(originText);
        const mark = Researcher.schemeMark(scheme);
        return Researcher.strictMatch(anchorsCode, spellCode, aliasText, inputCount, store, Researcher.defaultStrictLimit, mark);
    }

    private static anchorsMatch(keys: VirtualInputKey[], input: string | undefined, store: relationalStore.RdbStore, limit: number = Researcher.defaultAnchorsLimit, mark?: string): Lexicon[] {
        const code = Researcher.anchorsCode(keys);
        if (code < 1) {
            return [];
        }
        const text = input ?? Researcher.keysText(keys);
        const inputCount = text.length;
        const lexicons: Lexicon[] = [];
        const command: string = "SELECT rowid, word, romanization FROM core_lexicon WHERE anchors = ? LIMIT ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [code, limit]);
            while (res.goToNextRow()) {
                const rowID = res.getLong(0);
                const word = res.getString(1);
                const romanization = res.getString(2);
                lexicons.push(Researcher.makeLexicon(word, romanization, text, inputCount, rowID, mark ?? text));
            }
        } catch (error) {
            const err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            res?.close();
        }
        return lexicons;
    }

    private static spellMatch(text: string, input: string, inputCount: number, store: relationalStore.RdbStore,
        limit: number = Researcher.defaultSpellLimit, mark?: string): Lexicon[] {
        const lexicons: Lexicon[] = [];
        const code = Researcher.hashCode(text);
        const command: string = "SELECT rowid, word, romanization FROM core_lexicon WHERE spell = ? LIMIT ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [code, limit]);
            while (res.goToNextRow()) {
                const rowID = res.getLong(0);
                const word = res.getString(1);
                const romanization = res.getString(2);
                lexicons.push(Researcher.makeLexicon(word, romanization, input, inputCount, rowID, mark ?? input));
            }
        } catch (error) {
            const err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            res?.close();
        }
        return lexicons;
    }

    private static strictMatch(anchors: number, spell: number, input: string, inputCount: number, store: relationalStore.RdbStore, limit: number = Researcher.defaultStrictLimit, mark?: string): Lexicon[] {
        const lexicons: Lexicon[] = [];
        const command: string = "SELECT rowid, word, romanization FROM core_lexicon WHERE spell = ? AND anchors = ? LIMIT ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [spell, anchors, limit]);
            while (res.goToNextRow()) {
                const rowID = res.getLong(0);
                const word = res.getString(1);
                const romanization = res.getString(2);
                lexicons.push(Researcher.makeLexicon(word, romanization, input, inputCount, rowID, mark ?? input));
            }
        } catch (error) {
            const err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            res?.close();
        }
        return lexicons;
    }

    static test(store: relationalStore.RdbStore): number {
        let num: number = -1;
        const command: string = "SELECT rowid romanization FROM core_lexicon WHERE anchors = 32 LIMIT 1;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command);
            if (res.goToNextRow()) {
                num = res.getLong(0);
            }
        } catch (error) {
            const err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            res?.close();
        }
        return num;
    }
}
