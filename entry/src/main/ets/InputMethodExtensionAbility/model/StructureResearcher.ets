import { Lookup } from "./Lookup";
import { EngineCode } from "./EngineCode";
import { relationalStore } from "@kit.ArkData";
import { BusinessError } from "@kit.BasicServicesKit";
import { CharCode } from "./CharCode";
import { Lexicon } from "./Lexicon";
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
        return segmentation.filter((scheme) => StructureResearcher.schemeLength(scheme) === text.length).flatMap((scheme) => StructureResearcher.match(StructureResearcher.schemeOriginText(scheme), store, EngineCode.complexity(scheme.map((syllable) => syllable.origin.length))));
    }

    private static match(text: string, store: relationalStore.RdbStore, complexity: string): StructureMatch[] {
        if (text.length < 1) {
            return [];
        }
        const items: StructureMatch[] = [];
        const command = "SELECT rowid, word, romanization FROM structure_table WHERE spell = CAST(? AS INTEGER) AND complexity = CAST(? AS INTEGER) ORDER BY rowid;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [EngineCode.text(text), complexity]);
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
            return Lookup.reverse(item.text, input, store);
        }));
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
