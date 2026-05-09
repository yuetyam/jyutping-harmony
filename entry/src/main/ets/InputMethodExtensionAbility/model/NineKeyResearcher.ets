import { relationalStore } from "@kit.ArkData";
import { BusinessError } from "@kit.BasicServicesKit";
import { Lexicon } from "./Lexicon";
import { LexiconType } from "./LexiconType";
import { Combo } from "../ninekey/Combo";

class NineKeyCandidateLexicon implements Lexicon {
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

export class NineKeyResearcher {
    private static readonly concatenationStep: number = 1000000;

    static suggest(combos: Combo[], store: relationalStore.RdbStore): Lexicon[] {
        if (combos.length < 1 || combos.some((combo) => combo.isSpecial)) {
            return [];
        }
        const queried = NineKeyResearcher.search(combos, store);
        const head = queried[0];
        if (head === undefined || head.inputCount >= combos.length) {
            return queried;
        }
        const tailCombos = combos.slice(head.inputCount);
        const tailCode = NineKeyResearcher.combinedCode(tailCombos);
        if (tailCode < 1) {
            return queried;
        }
        const tailLexicons = [
            ...NineKeyResearcher.codeMatch(tailCode, 20, store),
            ...NineKeyResearcher.anchorsMatch(tailCode, 20, store)
        ];
        const tail = tailLexicons[0];
        if (tail === undefined) {
            return queried;
        }
        const compound = NineKeyResearcher.concatenateLexicons(head, tail);
        return NineKeyResearcher.distinctLexicons([compound, ...queried]);
    }

    private static search(combos: Combo[], store: relationalStore.RdbStore): Lexicon[] {
        const inputLength = combos.length;
        const fullCode = NineKeyResearcher.combinedCode(combos);
        if (inputLength < 2) {
            return NineKeyResearcher.distinctLexicons([
                ...NineKeyResearcher.codeMatch(fullCode, -1, store),
                ...NineKeyResearcher.anchorsMatch(fullCode, 100, store)
            ]);
        }
        const fullMatched = NineKeyResearcher.codeMatch(fullCode, -1, store);
        const idealAnchorsMatched = NineKeyResearcher.anchorsMatch(fullCode, 4, store);
        const codeMatched = NineKeyResearcher.descendingTailCounts(inputLength).flatMap((tailCount) => {
            const code = NineKeyResearcher.combinedCode(combos.slice(0, inputLength - tailCount));
            return NineKeyResearcher.codeMatch(code, -1, store);
        });
        const anchorsMatched = NineKeyResearcher.trailingInclusiveTailCounts(inputLength).flatMap((tailCount) => {
            const code = NineKeyResearcher.combinedCode(combos.slice(0, inputLength - tailCount));
            return NineKeyResearcher.anchorsMatch(code, -1, store);
        });
        return NineKeyResearcher.distinctLexicons([
            ...fullMatched,
            ...idealAnchorsMatched,
            ...codeMatched,
            ...anchorsMatched
        ]);
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

    private static combinedCode(combos: Combo[]): number {
        if (combos.length > 15) {
            return 0;
        } else {
            return combos.reduce((acc, combo) => acc * 10 + combo.digit, 0);
        }
    }

    private static makeLexicon(text: string, romanization: string, input: string, number: number, mark: string): Lexicon {
        return new NineKeyCandidateLexicon(text, romanization, input, number, mark);
    }

    private static concatenateLexicons(lhs: Lexicon, rhs: Lexicon): Lexicon {
        const lhsRomanization = lhs.romanization ?? "";
        const rhsRomanization = rhs.romanization ?? "";
        const lhsMark = lhs.mark ?? lhs.input;
        const rhsMark = rhs.mark ?? rhs.input;
        const input = lhs.input + rhs.input;
        return NineKeyResearcher.makeLexicon(
            lhs.text + rhs.text,
            `${lhsRomanization} ${rhsRomanization}`.trim(),
            input,
            (lhs.number + NineKeyResearcher.concatenationStep) + (rhs.number + NineKeyResearcher.concatenationStep),
            `${lhsMark} ${rhsMark}`.trim()
        );
    }

    private static anchorsMatch(code: number, limit: number, store: relationalStore.RdbStore): Lexicon[] {
        if (code < 1) {
            return [];
        }
        const items: Lexicon[] = [];
        const command = "SELECT rowid, word, romanization FROM core_lexicon WHERE nine_key_anchors = ? LIMIT ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [code, limit]);
            while (res.goToNextRow()) {
                const romanization = res.getString(2);
                const anchors = romanization.split(/\s+/).filter((part) => part.length > 0).map((part) => part[0]).join("");
                items.push(NineKeyResearcher.makeLexicon(res.getString(1), romanization, anchors, res.getLong(0), anchors));
            }
        } catch (error) {
            const err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            res?.close();
        }
        return items;
    }

    private static codeMatch(code: number, limit: number, store: relationalStore.RdbStore): Lexicon[] {
        if (code < 1) {
            return [];
        }
        const items: Lexicon[] = [];
        const command = "SELECT rowid, word, romanization FROM core_lexicon WHERE nine_key_code = ? LIMIT ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [code, limit]);
            while (res.goToNextRow()) {
                const romanization = res.getString(2);
                const mark = romanization.replace(/\d/g, "");
                const input = mark.replace(/\s/g, "");
                items.push(NineKeyResearcher.makeLexicon(res.getString(1), romanization, input, res.getLong(0), mark));
            }
        } catch (error) {
            const err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            res?.close();
        }
        return items;
    }

    private static lexiconKey(item: Lexicon): string {
        return `${item.type}\u0000${item.text}\u0000${item.romanization ?? ""}`;
    }

    private static distinctLexicons(items: Lexicon[]): Lexicon[] {
        const handled: string[] = [];
        const results: Lexicon[] = [];
        for (const item of items) {
            const key = NineKeyResearcher.lexiconKey(item);
            if (handled.includes(key)) {
                continue;
            }
            handled.push(key);
            results.push(item);
        }
        return results;
    }
}
