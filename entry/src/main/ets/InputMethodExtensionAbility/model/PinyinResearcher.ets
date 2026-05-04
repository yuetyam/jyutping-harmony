import { relationalStore } from "@kit.ArkData";
import { BusinessError } from "@kit.BasicServicesKit";
import { Lexicon } from "./Lexicon";
import { LexiconType } from "./LexiconType";
import { PinyinScheme, PinyinSegmentation, PinyinSegmenter } from "./PinyinSegmenter";
import { VirtualInputKey } from "./VirtualInputKey";

class PinyinLexicon {
    readonly text: string;
    readonly pinyin: string;
    readonly input: string;
    readonly inputCount: number;
    readonly mark: string;
    readonly order: number;

    constructor(text: string, pinyin: string, input: string, mark: string, order: number) {
        this.text = text;
        this.pinyin = pinyin;
        this.input = input;
        this.inputCount = input.length;
        this.mark = mark;
        this.order = order;
    }
}

class RomanizationMatch {
    readonly romanization: string;
    readonly order: number;

    constructor(romanization: string, order: number) {
        this.romanization = romanization;
        this.order = order;
    }
}

class ReverseLookupLexicon implements Lexicon {
    readonly type: LexiconType;
    readonly text: string;
    readonly romanization?: string;
    readonly input: string;
    readonly inputCount: number;
    readonly number: number;
    readonly mark?: string;
    readonly note?: string;

    constructor(text: string, romanization: string, input: string, inputCount: number, number: number, mark: string) {
        this.type = LexiconType.Cantonese;
        this.text = text;
        this.romanization = romanization;
        this.input = input;
        this.inputCount = inputCount;
        this.number = number;
        this.mark = mark;
    }
}

class LeadingRomanizationMatch {
    readonly romanization: string | undefined;
    readonly charCount: number;

    constructor(charCount: number, romanization?: string) {
        this.romanization = romanization;
        this.charCount = charCount;
    }
}

export class PinyinResearcher {
    private static readonly defaultAnchorsLimit: number = 100;
    private static readonly defaultPrefixLimit: number = 500;
    private static readonly defaultGainedLimit: number = 300;
    private static readonly processSliceAnchorsLimit: number = 300;
    private static readonly processSliceResultLimit: number = 72;
    private static readonly maxConcatenatedInputLength: number = 18;

    static suggest(keys: VirtualInputKey[], segmentation: PinyinSegmentation, store: relationalStore.RdbStore): Lexicon[] {
        if (keys.length < 1 || keys.some((key) => !key.isLetter)) {
            return [];
        }
        const matched = segmentation.length > 0 ?
            PinyinResearcher.search(keys, segmentation, store) :
            PinyinResearcher.processSlices(keys, PinyinResearcher.keysText(keys), store);
        return PinyinResearcher.distinctLexicons(
            matched.flatMap((item) => PinyinResearcher.reverseLookup(item.text, item.input, item.mark, item.order, store))
        );
    }

    private static reverseLookup(text: string, input: string, mark: string, order: number,
        store: relationalStore.RdbStore): Lexicon[] {
        return PinyinResearcher.lookup(text, store).map((item, index): Lexicon => {
            return PinyinResearcher.makeLexicon(text, item.romanization, input, input.length, order + index, mark);
        });
    }

    private static lookup(text: string, store: relationalStore.RdbStore): RomanizationMatch[] {
        if (text.length < 1) {
            return [];
        }
        const matched = PinyinResearcher.matchWord(text, store);
        if (matched.length > 0) {
            return matched;
        }
        if (text.length === 1) {
            return [];
        }
        let remaining = text;
        const fetches: string[] = [];
        while (remaining.length > 0) {
            const leading = PinyinResearcher.fetchLeading(remaining, store);
            if (leading.romanization !== undefined) {
                fetches.push(leading.romanization);
                remaining = remaining.slice(Math.max(1, leading.charCount));
            } else {
                fetches.push("?");
                remaining = remaining.slice(1);
            }
        }
        if (fetches.length < 1) {
            return [];
        }
        return [PinyinResearcher.makeRomanizationMatch(fetches.join(" "), Number.MAX_SAFE_INTEGER)];
    }

    private static fetchLeading(word: string, store: relationalStore.RdbStore): LeadingRomanizationMatch {
        let chars = word;
        while (chars.length > 0) {
            const matched = PinyinResearcher.matchWord(chars, store);
            if (matched.length > 0) {
                return new LeadingRomanizationMatch(chars.length, matched[0].romanization);
            }
            chars = chars.slice(0, -1);
        }
        return new LeadingRomanizationMatch(0);
    }

    private static matchWord(text: string, store: relationalStore.RdbStore): RomanizationMatch[] {
        const matches: RomanizationMatch[] = [];
        const command = "SELECT rowid, romanization FROM core_lexicon WHERE word = ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [text]);
            while (res.goToNextRow()) {
                matches.push(PinyinResearcher.makeRomanizationMatch(res.getString(1), res.getLong(0)));
            }
        } catch (error) {
            const err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            res?.close();
        }
        return matches;
    }

    private static processSlices(keys: VirtualInputKey[], text: string, store: relationalStore.RdbStore): PinyinLexicon[] {
        const inputLength = keys.length;
        const items: PinyinLexicon[] = [];
        for (let offset = 0; offset < inputLength; offset++) {
            const leadingKeys = keys.slice(0, inputLength - offset);
            const leadingText = PinyinResearcher.keysText(leadingKeys);
            const spellMatched = PinyinResearcher.spellMatch(leadingText, store)
                .map((item) => PinyinResearcher.modify(item, text, inputLength));
            const anchorsMatched = PinyinResearcher.sortPinyinLexicons(
                PinyinResearcher.anchorsMatch(leadingKeys, leadingText, store, PinyinResearcher.processSliceAnchorsLimit)
                    .map((item) => PinyinResearcher.modify(item, text, inputLength))
            ).slice(0, PinyinResearcher.processSliceResultLimit);
            items.push(...spellMatched, ...anchorsMatched);
        }
        return PinyinResearcher.sortPinyinLexicons(PinyinResearcher.distinctPinyinLexicons(items));
    }

    private static modify(item: PinyinLexicon, text: string, textLength: number): PinyinLexicon {
        if (item.inputCount === textLength) {
            return item;
        }
        const converted = PinyinResearcher.replacedInput(item, text, text);
        if (item.pinyin.replace(/\s/g, "").startsWith(text)) {
            return converted;
        }
        const syllables = PinyinResearcher.splitRomanization(item.pinyin);
        const lastSyllable = syllables.length > 0 ? syllables[syllables.length - 1] : "";
        if (lastSyllable.length < 1 || !text.endsWith(lastSyllable)) {
            return item;
        }
        const isMatched = ((syllables.length - 1) + lastSyllable.length) === textLength;
        return isMatched ? converted : item;
    }

    private static search(keys: VirtualInputKey[], segmentation: PinyinSegmentation, store: relationalStore.RdbStore): PinyinLexicon[] {
        const inputLength = keys.length;
        const text = PinyinResearcher.keysText(keys);
        const spellMatched = PinyinResearcher.spellMatch(text, store);
        const anchorsMatched = PinyinResearcher.anchorsMatch(keys, text, store);
        const queried = PinyinResearcher.query(inputLength, segmentation, store);
        const shouldMatchPrefixes = spellMatched.length < 1 &&
            queried.every((item) => item.inputCount !== inputLength) &&
            segmentation.every((scheme) => PinyinSegmenter.schemeLength(scheme) !== inputLength);
        const prefixMatched = shouldMatchPrefixes ? segmentation.flatMap((scheme) => {
            const handledLength = PinyinSegmenter.schemeLength(scheme);
            const tail = keys.slice(handledLength);
            const lastAnchor = tail[0];
            if (lastAnchor === undefined) {
                return [];
            }
            const schemeAnchors: VirtualInputKey[] = [];
            for (const syllable of scheme) {
                const anchor = syllable.keys[0];
                if (anchor !== undefined) {
                    schemeAnchors.push(anchor);
                }
            }
            const conjoined = [...schemeAnchors, ...tail];
            const anchors = [...schemeAnchors, lastAnchor];
            const schemeMark = PinyinSegmenter.schemeMark(scheme);
            const mark = `${schemeMark} ${PinyinResearcher.keysText(tail)}`.trim();
            const tailAnchorText = tail.map((key) => key.text[0]).join("");
            const conjoinedMatched = PinyinResearcher.anchorsMatch(conjoined, undefined, store, PinyinResearcher.defaultPrefixLimit)
                .flatMap((item) => {
                    if (!item.pinyin.startsWith(schemeMark)) {
                        return [];
                    }
                    const suffixText = item.pinyin.slice(schemeMark.length).trim();
                    const suffixAnchors = suffixText.length < 1 ? "" : suffixText.split(/\s+/).map((part) => part[0]).join("");
                    if (suffixAnchors !== tailAnchorText) {
                        return [];
                    }
                    return [PinyinResearcher.makePinyinLexicon(item.text, item.pinyin, text, mark, item.order)];
                });
            const leadingAnchorsMatched = PinyinResearcher.anchorsMatch(anchors, undefined, store, PinyinResearcher.defaultPrefixLimit)
                .flatMap((item) => {
                    if (!item.pinyin.startsWith(mark)) {
                        return [];
                    }
                    return [PinyinResearcher.makePinyinLexicon(item.text, item.pinyin, text, mark, item.order)];
                });
            return [...conjoinedMatched, ...leadingAnchorsMatched];
        }) : [];
        const gainedMatched = shouldMatchPrefixes ? PinyinResearcher.descendingInputLengths(inputLength).flatMap((length) => {
            const leadingKeys = keys.slice(0, length);
            const leadingText = PinyinResearcher.keysText(leadingKeys);
            return PinyinResearcher.anchorsMatch(leadingKeys, leadingText, store, PinyinResearcher.defaultGainedLimit);
        }).flatMap((item) => {
            const converted = PinyinResearcher.replacedInput(item, text, text);
            if (item.pinyin.replace(/\s/g, "").startsWith(text)) {
                return [converted];
            }
            const syllables = PinyinResearcher.splitRomanization(item.pinyin);
            const lastSyllable = syllables.length > 0 ? syllables[syllables.length - 1] : "";
            if (lastSyllable.length < 1 || !text.endsWith(lastSyllable)) {
                return [];
            }
            const isMatched = ((syllables.length - 1) + lastSyllable.length) === inputLength;
            return isMatched ? [converted] : [];
        }) : [];
        const idealQueried = PinyinResearcher.distinctPinyinLexicons(
            PinyinResearcher.sortPinyinLexiconsByOrder(queried.filter((item) => item.inputCount === inputLength))
        );
        const notIdealQueried = PinyinResearcher.distinctPinyinLexicons(
            PinyinResearcher.sortPinyinLexicons(queried.filter((item) => item.inputCount < inputLength))
        );
        const fullInput = PinyinResearcher.distinctPinyinLexicons([
            ...spellMatched,
            ...idealQueried,
            ...anchorsMatched,
            ...prefixMatched,
            ...gainedMatched,
        ]);
        const fetched = PinyinResearcher.distinctPinyinLexicons([
            ...fullInput.slice(0, 10),
            ...PinyinResearcher.sortPinyinLexicons(fullInput).slice(0, 10),
            ...notIdealQueried.slice(0, 10),
            ...PinyinResearcher.sortPinyinLexiconsByOrder(notIdealQueried).slice(0, 10),
            ...fullInput,
            ...notIdealQueried,
        ]);
        if (fetched.length < 1) {
            return PinyinResearcher.processSlices(keys, text, store);
        }
        if (fetched[0].inputCount >= inputLength) {
            return fetched;
        }
        if (inputLength > PinyinResearcher.maxConcatenatedInputLength) {
            return fetched;
        }
        const headInputLengths = PinyinResearcher.distinctNumbers(fetched.map((item) => item.inputCount));
        const concatenated = PinyinResearcher.sortPinyinLexicons(
            PinyinResearcher.distinctPinyinLexicons(headInputLengths.flatMap((headLength) => {
                const tailKeys = keys.slice(headLength);
                const tailSegmentation = PinyinSegmenter.segment(tailKeys, store);
                const tailLexicon = PinyinResearcher.search(tailKeys, tailSegmentation, store)[0];
                const headLexicon = fetched.find((item) => item.inputCount === headLength);
                if (tailLexicon === undefined || headLexicon === undefined) {
                    return [];
                }
                return [PinyinResearcher.concatenate(headLexicon, tailLexicon)];
            }))
        ).slice(0, 1);
        return [...concatenated, ...fetched];
    }

    private static query(inputLength: number, segmentation: PinyinSegmentation, store: relationalStore.RdbStore): PinyinLexicon[] {
        const idealSchemes = segmentation.filter((scheme) => PinyinSegmenter.schemeLength(scheme) === inputLength);
        if (idealSchemes.length < 1) {
            return segmentation.flatMap((scheme) => {
                return PinyinResearcher.spellMatch(scheme.map((syllable) => syllable.text).join(""), store);
            });
        }
        return idealSchemes.flatMap((scheme) => {
            if (scheme.length < 1) {
                return [];
            }
            const prefixes: PinyinScheme[] = [];
            for (let index = scheme.length; index >= 1; index--) {
                prefixes.push(scheme.slice(0, index));
            }
            return prefixes.flatMap((slice) => {
                return PinyinResearcher.spellMatch(slice.map((syllable) => syllable.text).join(""), store);
            });
        });
    }

    private static spellMatch(text: string, store: relationalStore.RdbStore): PinyinLexicon[] {
        const lexicons: PinyinLexicon[] = [];
        const command = "SELECT rowid, word, romanization FROM pinyin_lexicon WHERE spell = ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [PinyinResearcher.hashCode(text)]);
            while (res.goToNextRow()) {
                lexicons.push(PinyinResearcher.makePinyinLexicon(
                    res.getString(1),
                    res.getString(2),
                    text,
                    res.getString(2),
                    res.getLong(0)
                ));
            }
        } catch (error) {
            const err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            res?.close();
        }
        return lexicons;
    }

    private static anchorsMatch(keys: VirtualInputKey[], input: string | undefined, store: relationalStore.RdbStore,
        limit: number = PinyinResearcher.defaultAnchorsLimit): PinyinLexicon[] {
        const code = keys.reduce((acc, key) => acc * 100 + key.code, 0);
        if (code < 1) {
            return [];
        }
        const lexicons: PinyinLexicon[] = [];
        const command = "SELECT rowid, word, romanization FROM pinyin_lexicon WHERE anchors = ? LIMIT ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [code, limit]);
            const inputText = input ?? PinyinResearcher.keysText(keys);
            while (res.goToNextRow()) {
                lexicons.push(PinyinResearcher.makePinyinLexicon(
                    res.getString(1),
                    res.getString(2),
                    inputText,
                    inputText,
                    res.getLong(0)
                ));
            }
        } catch (error) {
            const err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            res?.close();
        }
        return lexicons;
    }

    private static hashCode(str: string): number {
        let hash = 0;
        for (let i = 0; i < str.length; i++) {
            hash = Math.imul(31, hash) + str.charCodeAt(i) | 0;
        }
        return hash;
    }

    private static keysText(keys: VirtualInputKey[]): string {
        return keys.map((key) => key.text).join("");
    }

    private static splitRomanization(text: string): string[] {
        return text.split(/\s+/).filter((part) => part.length > 0);
    }

    private static descendingInputLengths(inputLength: number): number[] {
        const lengths: number[] = [];
        for (let index = inputLength - 1; index >= 1; index--) {
            lengths.push(index);
        }
        return lengths;
    }

    private static makePinyinLexicon(text: string, pinyin: string, input: string, mark: string, order: number): PinyinLexicon {
        return new PinyinLexicon(text, pinyin, input, mark, order);
    }

    private static makeLexicon(text: string, romanization: string, input: string, inputCount: number,
        number: number, mark: string): Lexicon {
        return new ReverseLookupLexicon(text, romanization, input, inputCount, number, mark);
    }

    private static makeRomanizationMatch(romanization: string, order: number): RomanizationMatch {
        return new RomanizationMatch(romanization, order);
    }

    private static replacedInput(item: PinyinLexicon, input: string, mark: string): PinyinLexicon {
        return PinyinResearcher.makePinyinLexicon(item.text, item.pinyin, input, mark, item.order);
    }

    private static concatenate(lhs: PinyinLexicon, rhs: PinyinLexicon): PinyinLexicon {
        const text = lhs.text + rhs.text;
        const pinyin = `${lhs.pinyin} ${rhs.pinyin}`;
        const input = lhs.input + rhs.input;
        const mark = `${lhs.mark} ${rhs.mark}`;
        return PinyinResearcher.makePinyinLexicon(text, pinyin, input, mark, 0);
    }

    private static lexiconKey(item: Lexicon): string {
        return `${item.text}\u0000${item.romanization ?? ""}`;
    }

    private static distinctLexicons(items: Lexicon[]): Lexicon[] {
        const handled: string[] = [];
        const results: Lexicon[] = [];
        for (const item of items) {
            const key = PinyinResearcher.lexiconKey(item);
            if (handled.includes(key)) {
                continue;
            }
            handled.push(key);
            results.push(item);
        }
        return results;
    }

    private static pinyinKey(item: PinyinLexicon): string {
        return `${item.text}\u0000${item.pinyin}`;
    }

    private static distinctPinyinLexicons(items: PinyinLexicon[]): PinyinLexicon[] {
        const handled: string[] = [];
        const results: PinyinLexicon[] = [];
        for (const item of items) {
            const key = PinyinResearcher.pinyinKey(item);
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

    private static comparePinyinLexicon(lhs: PinyinLexicon, rhs: PinyinLexicon): number {
        if (lhs.inputCount !== rhs.inputCount) {
            return rhs.inputCount - lhs.inputCount;
        }
        return lhs.order - rhs.order;
    }

    private static sortPinyinLexicons(items: PinyinLexicon[]): PinyinLexicon[] {
        return [...items].sort((lhs, rhs) => PinyinResearcher.comparePinyinLexicon(lhs, rhs));
    }

    private static sortPinyinLexiconsByOrder(items: PinyinLexicon[]): PinyinLexicon[] {
        return [...items].sort((lhs, rhs) => lhs.order - rhs.order);
    }
}
