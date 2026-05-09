import { relationalStore } from "@kit.ArkData";
import { BusinessError } from "@kit.BasicServicesKit";
import { Lexicon } from "./Lexicon";
import { LexiconType } from "./LexiconType";
import { NineKeyCombo } from "../ninekey/NineKeyCombo";

class NineKeyPinyinLexicon {
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

class NineKeyRomanizationMatch {
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

class NineKeyReverseLookupLexicon implements Lexicon {
    readonly type: LexiconType;
    readonly text: string;
    readonly romanization?: string;
    readonly input: string;
    readonly inputCount: number;
    readonly number: number;
    readonly mark?: string;
    readonly note?: string;

    constructor(text: string, romanization: string, input: string, number: number, mark: string) {
        this.type = LexiconType.Cantonese;
        this.text = text;
        this.romanization = romanization;
        this.input = input;
        this.inputCount = input.length;
        this.number = number;
        this.mark = mark;
    }
}

export class NineKeyPinyinResearcher {
    private static readonly concatenationStep: number = 1000000;

    static suggest(combos: NineKeyCombo[], store: relationalStore.RdbStore): Lexicon[] {
        if (combos.length < 1 || combos.some((combo) => combo.isSpecial)) {
            return [];
        }
        const queried = NineKeyPinyinResearcher.search(combos, store);
        return NineKeyPinyinResearcher.distinctLexicons(
            queried.flatMap((item) => NineKeyPinyinResearcher.reverseLookup(item.text, item.input, item.mark, item.order, store))
        );
    }

    private static search(combos: NineKeyCombo[], store: relationalStore.RdbStore): NineKeyPinyinLexicon[] {
        const inputLength = combos.length;
        const fullCode = NineKeyPinyinResearcher.codeText(combos);
        if (inputLength < 2) {
            return NineKeyPinyinResearcher.distinctPinyinLexicons([
                ...NineKeyPinyinResearcher.codeMatch(fullCode, -1, store),
                ...NineKeyPinyinResearcher.anchorsMatch(fullCode, 100, store)
            ]);
        }
        const fullMatched = NineKeyPinyinResearcher.codeMatch(fullCode, -1, store);
        const idealAnchorsMatched = NineKeyPinyinResearcher.anchorsMatch(fullCode, 4, store);
        const codeMatched = NineKeyPinyinResearcher.descendingTailCounts(inputLength).flatMap((tailCount) => {
            const code = NineKeyPinyinResearcher.codeText(combos.slice(0, inputLength - tailCount));
            return NineKeyPinyinResearcher.codeMatch(code, -1, store);
        });
        const anchorsMatched = NineKeyPinyinResearcher.trailingInclusiveTailCounts(inputLength).flatMap((tailCount) => {
            const code = NineKeyPinyinResearcher.codeText(combos.slice(0, inputLength - tailCount));
            return NineKeyPinyinResearcher.anchorsMatch(code, -1, store);
        });
        const queried = NineKeyPinyinResearcher.distinctPinyinLexicons([
            ...fullMatched,
            ...idealAnchorsMatched,
            ...codeMatched,
            ...anchorsMatched
        ]);
        const head = queried[0];
        if (head === undefined || head.inputCount >= inputLength) {
            return queried;
        }
        const tailCombos = combos.slice(head.inputCount);
        const tailCode = NineKeyPinyinResearcher.codeText(tailCombos);
        if (tailCode.length < 1) {
            return queried;
        }
        const tailLexicons = [
            ...NineKeyPinyinResearcher.codeMatch(tailCode, 20, store),
            ...NineKeyPinyinResearcher.anchorsMatch(tailCode, 20, store)
        ];
        const tail = tailLexicons[0];
        if (tail === undefined) {
            return queried;
        }
        const compound = NineKeyPinyinResearcher.concatenateLexicons(head, tail);
        return NineKeyPinyinResearcher.distinctPinyinLexicons([compound, ...queried]);
    }

    private static descendingTailCounts(length: number): number[] {
        const values: number[] = [];
        for (let number = 1; number < length; number++) {
            values.push(number);
        }
        return values;
    }

    private static trailingInclusiveTailCounts(length: number): number[] {
        const values: number[] = [];
        for (let number = 0; number < length; number++) {
            values.push(number);
        }
        return values;
    }

    private static codeText(combos: NineKeyCombo[]): string {
        return combos.map((combo) => combo.digit).join("");
    }

    private static makePinyinLexicon(text: string, pinyin: string, input: string, mark: string, order: number): NineKeyPinyinLexicon {
        return new NineKeyPinyinLexicon(text, pinyin, input, mark, order);
    }

    private static concatenateLexicons(lhs: NineKeyPinyinLexicon, rhs: NineKeyPinyinLexicon): NineKeyPinyinLexicon {
        const input = lhs.input + rhs.input;
        return NineKeyPinyinResearcher.makePinyinLexicon(
            lhs.text + rhs.text,
            `${lhs.pinyin} ${rhs.pinyin}`.trim(),
            input,
            `${lhs.mark} ${rhs.mark}`.trim(),
            (lhs.order + NineKeyPinyinResearcher.concatenationStep) + (rhs.order + NineKeyPinyinResearcher.concatenationStep)
        );
    }

    private static anchorsMatch(code: string, limit: number, store: relationalStore.RdbStore): NineKeyPinyinLexicon[] {
        if (code.length < 1) {
            return [];
        }
        const items: NineKeyPinyinLexicon[] = [];
        const command = "SELECT rowid, word, romanization FROM pinyin_lexicon " +
            "WHERE nine_key_anchors = CAST(? AS INTEGER) ORDER BY rowid LIMIT ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [code, limit]);
            while (res.goToNextRow()) {
                const pinyin = res.getString(2);
                const anchors = pinyin.split(/\s+/).filter((part) => part.length > 0).map((part) => part[0]).join("");
                items.push(NineKeyPinyinResearcher.makePinyinLexicon(res.getString(1), pinyin, anchors, anchors, res.getLong(0)));
            }
        } catch (error) {
            const err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            res?.close();
        }
        return items;
    }

    private static codeMatch(code: string, limit: number, store: relationalStore.RdbStore): NineKeyPinyinLexicon[] {
        if (code.length < 1) {
            return [];
        }
        const items: NineKeyPinyinLexicon[] = [];
        const command = "SELECT rowid, word, romanization FROM pinyin_lexicon " +
            "WHERE nine_key_code = CAST(? AS INTEGER) ORDER BY rowid LIMIT ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [code, limit]);
            while (res.goToNextRow()) {
                const pinyin = res.getString(2);
                const mark = pinyin.replace(/\d/g, "");
                const input = mark.replace(/\s/g, "");
                items.push(NineKeyPinyinResearcher.makePinyinLexicon(res.getString(1), pinyin, input, mark, res.getLong(0)));
            }
        } catch (error) {
            const err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            res?.close();
        }
        return items;
    }

    private static reverseLookup(text: string, input: string, mark: string, order: number, store: relationalStore.RdbStore): Lexicon[] {
        return NineKeyPinyinResearcher.lookup(text, store).map((item, index) => {
            return new NineKeyReverseLookupLexicon(text, item.romanization, input, order + index, mark);
        });
    }

    private static lookup(text: string, store: relationalStore.RdbStore): NineKeyRomanizationMatch[] {
        if (text.length < 1) {
            return [];
        }
        const matched = NineKeyPinyinResearcher.matchWord(text, store);
        if (matched.length > 0) {
            return matched;
        }
        if (text.length === 1) {
            return [];
        }
        let remaining = text;
        const fetches: string[] = [];
        while (remaining.length > 0) {
            const leading = NineKeyPinyinResearcher.fetchLeading(remaining, store);
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
        return [new NineKeyRomanizationMatch(fetches.join(" "), Number.MAX_SAFE_INTEGER)];
    }

    private static fetchLeading(word: string, store: relationalStore.RdbStore): LeadingRomanizationMatch {
        let chars = word;
        while (chars.length > 0) {
            const matched = NineKeyPinyinResearcher.matchWord(chars, store);
            if (matched.length > 0) {
                return new LeadingRomanizationMatch(chars.length, matched[0].romanization);
            }
            chars = chars.slice(0, -1);
        }
        return new LeadingRomanizationMatch(0);
    }

    private static matchWord(text: string, store: relationalStore.RdbStore): NineKeyRomanizationMatch[] {
        const matches: NineKeyRomanizationMatch[] = [];
        const command = "SELECT rowid, romanization FROM core_lexicon WHERE word = ? ORDER BY rowid;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [text]);
            while (res.goToNextRow()) {
                matches.push(new NineKeyRomanizationMatch(res.getString(1), res.getLong(0)));
            }
        } catch (error) {
            const err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            res?.close();
        }
        return matches;
    }

    private static pinyinLexiconKey(item: NineKeyPinyinLexicon): string {
        return `${item.text}\u0000${item.pinyin}`;
    }

    private static distinctPinyinLexicons(items: NineKeyPinyinLexicon[]): NineKeyPinyinLexicon[] {
        const handled: string[] = [];
        const results: NineKeyPinyinLexicon[] = [];
        for (const item of items) {
            const key = NineKeyPinyinResearcher.pinyinLexiconKey(item);
            if (handled.includes(key)) {
                continue;
            }
            handled.push(key);
            results.push(item);
        }
        return results;
    }

    private static lexiconKey(item: Lexicon): string {
        return `${item.type}\u0000${item.text}\u0000${item.romanization ?? ""}`;
    }

    private static distinctLexicons(items: Lexicon[]): Lexicon[] {
        const handled: string[] = [];
        const results: Lexicon[] = [];
        for (const item of items) {
            const key = NineKeyPinyinResearcher.lexiconKey(item);
            if (handled.includes(key)) {
                continue;
            }
            handled.push(key);
            results.push(item);
        }
        return results;
    }
}
