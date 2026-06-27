import { relationalStore } from "@kit.ArkData";
import { BusinessError } from "@kit.BasicServicesKit";
import { CharCode } from "./CharCode";
import { Lexicon } from "./Lexicon";
import { LexiconType } from "./LexiconType";
import { Scheme, Segmentation } from "./Segmenter";
import { VirtualInputKey } from "./VirtualInputKey";

class StructureMatch {
    readonly text: string;
    readonly romanization: string;
    readonly order: number;

    constructor(text: string, romanization: string, order: number) {
        this.text = text;
        this.romanization = romanization;
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

class LeadingRomanizationMatch {
    readonly romanization: string | undefined;
    readonly charCount: number;

    constructor(charCount: number, romanization?: string) {
        this.romanization = romanization;
        this.charCount = charCount;
    }
}

class StructureReverseLookupLexicon implements Lexicon {
    readonly type: LexiconType;
    readonly text: string;
    readonly romanization?: string;
    readonly input: string;
    readonly inputCount: number;
    readonly number: number;
    readonly mark?: string;
    readonly note?: string;

    constructor(text: string, romanization: string, input: string, number: number) {
        this.type = LexiconType.Cantonese;
        this.text = text;
        this.romanization = romanization;
        this.input = input;
        this.inputCount = input.length;
        this.number = number;
        this.mark = input;
    }
}

export class StructureResearcher {
    static suggest(keys: VirtualInputKey[], segmentation: Segmentation, store: relationalStore.RdbStore): Lexicon[] {
        if (keys.length < 1) {
            return [];
        }
        const markFreeText = keys.filter((key) => key.isSyllableLetter).map((key) => key.text).join("");
        const searched = StructureResearcher.search(markFreeText, segmentation, store);
        if (searched.length < 1) {
            return [];
        }
        const inputText = StructureResearcher.keysText(keys);
        const hasApostrophe = keys.some((key) => key.isApostrophe);
        const hasToneLetter = keys.some((key) => key.isToneLetter);
        if (hasApostrophe && hasToneLetter) {
            const text = StructureResearcher.toneConvertedText(inputText);
            const textTones = StructureResearcher.toneDigits(text);
            if (textTones.length !== 1) {
                return [];
            }
            const isToneInTail = StructureResearcher.isToneDigit(text[text.length - 1] ?? "");
            const filtered = searched.filter((item) => {
                const tones = StructureResearcher.toneDigits(item.romanization);
                return isToneInTail ? tones.endsWith(textTones) : tones.startsWith(textTones);
            });
            return StructureResearcher.reverseLookupMatches(filtered, inputText, store);
        }
        if (!hasApostrophe && hasToneLetter) {
            const text = StructureResearcher.toneConvertedText(inputText);
            const textTones = StructureResearcher.toneDigits(text);
            switch (textTones.length) {
                case 1: {
                    const isToneInTail = StructureResearcher.isToneDigit(text[text.length - 1] ?? "");
                    const filtered = searched.filter((item) => {
                        if (StructureResearcher.stripSpaces(item.romanization).startsWith(text)) {
                            return true;
                        }
                        const tones = StructureResearcher.toneDigits(item.romanization);
                        return isToneInTail ? tones.endsWith(textTones) : tones.startsWith(textTones);
                    });
                    return StructureResearcher.reverseLookupMatches(filtered, inputText, store);
                }
                case 2: {
                    const filtered = searched.filter((item) => {
                        if (StructureResearcher.stripSpaces(item.romanization).startsWith(text)) {
                            return true;
                        }
                        return textTones === StructureResearcher.toneDigits(item.romanization);
                    });
                    return StructureResearcher.reverseLookupMatches(filtered, inputText, store);
                }
                default: {
                    const filtered = searched.filter((item) => {
                        return StructureResearcher.stripSpaces(item.romanization).startsWith(text);
                    });
                    return StructureResearcher.reverseLookupMatches(filtered, inputText, store);
                }
            }
        }
        if (hasApostrophe && !hasToneLetter) {
            const textParts = inputText.split("'").filter((part) => part.length > 0);
            const filtered = searched.filter((item) => {
                const syllables = StructureResearcher.splitRomanization(StructureResearcher.stripTones(item.romanization));
                return StructureResearcher.equalStrings(syllables, textParts);
            });
            return StructureResearcher.reverseLookupMatches(filtered, inputText, store);
        }
        return StructureResearcher.reverseLookupMatches(searched, inputText, store);
    }

    private static search(text: string, segmentation: Segmentation, store: relationalStore.RdbStore): StructureMatch[] {
        const matched = StructureResearcher.match(text, store);
        const queried = segmentation
            .filter((scheme) => StructureResearcher.schemeLength(scheme) === text.length)
            .flatMap((scheme) => StructureResearcher.match(StructureResearcher.schemeOriginText(scheme), store));
        return [...matched, ...queried];
    }

    private static match(text: string, store: relationalStore.RdbStore): StructureMatch[] {
        if (text.length < 1) {
            return [];
        }
        const items: StructureMatch[] = [];
        const command = "SELECT rowid, word, romanization FROM structure_table WHERE spell = ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [StructureResearcher.hashCode(text)]);
            while (res.goToNextRow()) {
                items.push(new StructureMatch(res.getString(1), res.getString(2), res.getLong(0)));
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
        return items;
    }

    private static reverseLookupMatches(matches: StructureMatch[], input: string, store: relationalStore.RdbStore): Lexicon[] {
        return StructureResearcher.distinctLexicons(matches.flatMap((item) => {
            return StructureResearcher.reverseLookup(item.text, input, item.order, store);
        }));
    }

    private static reverseLookup(text: string, input: string, order: number, store: relationalStore.RdbStore): Lexicon[] {
        return StructureResearcher.lookup(text, store).map((item, index): Lexicon => {
            return new StructureReverseLookupLexicon(text, item.romanization, input, order + index);
        });
    }

    private static lookup(text: string, store: relationalStore.RdbStore): RomanizationMatch[] {
        if (text.length < 1) {
            return [];
        }
        const matched = StructureResearcher.matchWord(text, store);
        if (matched.length > 0) {
            return matched;
        }
        if (text.length === 1) {
            return [];
        }
        let remaining = text;
        const fetches: string[] = [];
        while (remaining.length > 0) {
            const leading = StructureResearcher.fetchLeading(remaining, store);
            if (leading.romanization === undefined) {
                fetches.length = 0;
                break;
            }
            fetches.push(leading.romanization);
            remaining = remaining.slice(Math.max(1, leading.charCount));
        }
        if (fetches.length < 1) {
            return [];
        }
        return [new RomanizationMatch(fetches.join(" "), Number.MAX_SAFE_INTEGER)];
    }

    private static fetchLeading(word: string, store: relationalStore.RdbStore): LeadingRomanizationMatch {
        let chars = word;
        while (chars.length > 0) {
            const matched = StructureResearcher.matchWord(chars, store);
            if (matched.length > 0) {
                return new LeadingRomanizationMatch(chars.length, matched[0].romanization);
            }
            chars = chars.slice(0, -1);
        }
        return new LeadingRomanizationMatch(0);
    }

    private static matchWord(text: string, store: relationalStore.RdbStore): RomanizationMatch[] {
        const matches: RomanizationMatch[] = [];
        const command = "SELECT rowid, romanization FROM core_lexicon WHERE word = ? ORDER BY rowid;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [text]);
            while (res.goToNextRow()) {
                matches.push(new RomanizationMatch(res.getString(1), res.getLong(0)));
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
        return matches;
    }

    private static hashCode(str: string): number {
        let hash = 0;
        for (let i = 0; i < str.length; i++) {
            hash = Math.imul(31, hash) + str.charCodeAt(i) | 0;
        }
        return hash;
    }

    private static keysText(keys: VirtualInputKey[]): string {
        return CharCode.keysText(keys);
    }

    private static schemeLength(scheme: Scheme): number {
        return scheme.reduce((acc, syllable) => acc + syllable.alias.length, 0);
    }

    private static schemeOriginText(scheme: Scheme): string {
        return CharCode.keysText(scheme.flatMap((syllable) => syllable.origin));
    }

    private static toneConvertedText(text: string): string {
        return text
            .replace(/vv/g, "4")
            .replace(/xx/g, "5")
            .replace(/qq/g, "6")
            .replace(/v/g, "1")
            .replace(/x/g, "2")
            .replace(/q/g, "3");
    }

    private static toneDigits(text: string): string {
        return text.replace(/[^1-6]/g, "");
    }

    private static isToneDigit(text: string): boolean {
        return /^[1-6]$/.test(text);
    }

    private static stripTones(text: string): string {
        return text.replace(/[1-6]/g, "");
    }

    private static stripSpaces(text: string): string {
        return text.replace(/\s/g, "");
    }

    private static splitRomanization(text: string): string[] {
        return text.trim().split(/\s+/).filter((part) => part.length > 0);
    }

    private static equalStrings(lhs: string[], rhs: string[]): boolean {
        if (lhs.length !== rhs.length) {
            return false;
        }
        for (let index = 0; index < lhs.length; index++) {
            if (lhs[index] !== rhs[index]) {
                return false;
            }
        }
        return true;
    }

    private static lexiconKey(item: Lexicon): string {
        return `${item.type}\u0000${item.text}\u0000${item.romanization ?? ""}`;
    }

    private static distinctLexicons(items: Lexicon[]): Lexicon[] {
        const handled: Set<string> = new Set();
        const results: Lexicon[] = [];
        for (const item of items) {
            const key = StructureResearcher.lexiconKey(item);
            if (handled.has(key)) {
                continue;
            }
            handled.add(key);
            results.push(item);
        }
        return results;
    }
}
