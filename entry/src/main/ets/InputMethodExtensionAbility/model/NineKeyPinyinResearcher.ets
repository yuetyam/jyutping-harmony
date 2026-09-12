import { Lookup } from "./Lookup";
import { EngineCode } from "./EngineCode";
import { PinyinNineKeySegmenter } from "./PinyinNineKeySegmenter";
import { relationalStore } from "@kit.ArkData";
import { BusinessError } from "@kit.BasicServicesKit";
import { Lexicon } from "./Lexicon";
import { Combo } from "../ninekey/Combo";

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

export class NineKeyPinyinResearcher {

    static suggest(combos: Combo[], store: relationalStore.RdbStore): Lexicon[] {
        if (combos.length < 1 || combos.some((combo) => combo.isSpecial)) {
            return [];
        }
        const queried = NineKeyPinyinResearcher.search(combos, store);
        return NineKeyPinyinResearcher.distinctLexicons(
            queried.flatMap((item) => Lookup.reverse(item.text, item.input, store, item.mark))
        );
    }

    private static search(combos: Combo[], store: relationalStore.RdbStore, limit: number = -1): NineKeyPinyinLexicon[] {
        if (combos.length === 0) return [];
        const segmentation = PinyinNineKeySegmenter.segment(combos, store);
        if (segmentation.length === 0) return NineKeyPinyinResearcher.slices(combos, store, limit);
        const ideal = segmentation.filter((scheme) => scheme.reduce((total, syllable) => total + syllable.alias.length, 0) === combos.length);
        const schemes = ideal.length === 0 ? segmentation : ideal.flatMap((scheme) => scheme.map((_, index) => scheme.slice(0, scheme.length - index)));
        const queried = schemes.flatMap((scheme) => {
            if (scheme.length === 0 || scheme.length > 9) return [] as NineKeyPinyinLexicon[];
            const code = EngineCode.decimalOverflowed(scheme.flatMap((syllable) => syllable.origin)).toString();
            return NineKeyPinyinResearcher.codeMatch(code, limit, store, EngineCode.complexity(scheme.map((syllable) => syllable.origin.length)));
        });
        const anchors = NineKeyPinyinResearcher.anchorsMatch(EngineCode.combos(combos), limit < 0 ? 30 : limit, store, combos.length);
        const fetched = NineKeyPinyinResearcher.ordered([...queried, ...anchors], combos.length);
        if (fetched.length === 0) return NineKeyPinyinResearcher.slices(combos, store, limit);
        if (fetched[0].inputCount >= combos.length) return fetched;
        const lengths = Array.from(new Set(fetched.map((item) => item.inputCount)));
        const compounds = lengths.flatMap((length): NineKeyPinyinLexicon[] => {
            const head = fetched.find((item) => item.inputCount === length);
            const tail = NineKeyPinyinResearcher.search(combos.slice(length), store, 20)[0];
            return head === undefined || tail === undefined ? [] : [NineKeyPinyinResearcher.concatenateLexicons(head, tail)];
        }).sort((a, b) => b.inputCount - a.inputCount || a.order - b.order).slice(0, 1);
        return [...compounds, ...fetched];
    }

    private static ordered(items: NineKeyPinyinLexicon[], length: number): NineKeyPinyinLexicon[] {
        const full = NineKeyPinyinResearcher.distinctPinyinLexicons(items.filter((item) => item.inputCount === length).sort((a, b) => a.order - b.order));
        const partial = NineKeyPinyinResearcher.distinctPinyinLexicons(items.filter((item) => item.inputCount !== length).sort((a, b) => b.inputCount - a.inputCount || a.order - b.order));
        return NineKeyPinyinResearcher.distinctPinyinLexicons([...full.slice(0, 15), ...partial.slice(0, 10), ...[...partial].sort((a, b) => a.order - b.order).slice(0, 7), ...full, ...partial]);
    }

    private static slices(combos: Combo[], store: relationalStore.RdbStore, limit: number): NineKeyPinyinLexicon[] {
        const items: NineKeyPinyinLexicon[] = [];
        for (let length = combos.length; length >= 1; length--) {
            const code = EngineCode.combos(combos.slice(0, length));
            items.push(...NineKeyPinyinResearcher.codeMatch(code, limit, store, length.toString()), ...NineKeyPinyinResearcher.anchorsMatch(code, limit < 0 ? 30 : limit, store, length));
        }
        return NineKeyPinyinResearcher.ordered(items, combos.length);
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
            0
        );
    }

    private static anchorsMatch(code: string, limit: number, store: relationalStore.RdbStore, count: number): NineKeyPinyinLexicon[] {
        const items: NineKeyPinyinLexicon[] = [];
        const command = "SELECT rowid, word, romanization FROM pinyin_lexicon WHERE anchors_9key = CAST(? AS INTEGER) AND char_count = ? ORDER BY rowid LIMIT ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [code, count, limit]);
            while (res.goToNextRow()) {
                const pinyin = res.getString(2);
                const anchors = pinyin.split(/\s+/).filter((part) => part.length > 0).map((part) => part[0]).join("");
                items.push(NineKeyPinyinResearcher.makePinyinLexicon(res.getString(1), pinyin, anchors, anchors, res.getLong(0)));
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

    private static codeMatch(code: string, limit: number, store: relationalStore.RdbStore, complexity: string): NineKeyPinyinLexicon[] {
        const items: NineKeyPinyinLexicon[] = [];
        const command = "SELECT rowid, word, romanization FROM pinyin_lexicon WHERE spell_9key = CAST(? AS INTEGER) AND complexity = CAST(? AS INTEGER) ORDER BY rowid LIMIT ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [code, complexity, limit]);
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
            try {
                res?.close();
            } catch (error) {
                const err: BusinessError = error as BusinessError;
                console.error(`message: ${err.message}, code: ${err.code}`);
            }
        }
        return items;
    }

    private static distinctPinyinLexicons(items: NineKeyPinyinLexicon[]): NineKeyPinyinLexicon[] {
        const handled: Set<string> = new Set();
        const results: NineKeyPinyinLexicon[] = [];
        for (const item of items) {
            const key = `${item.text}\u0000${item.pinyin}`;
            if (handled.has(key)) {
                continue;
            }
            handled.add(key);
            results.push(item);
        }
        return results;
    }

    private static lexiconKey(item: Lexicon): string {
        return `${item.type}\u0000${item.text}\u0000${item.romanization ?? ""}`;
    }

    private static distinctLexicons(items: Lexicon[]): Lexicon[] {
        const handled: Set<string> = new Set();
        const results: Lexicon[] = [];
        for (const item of items) {
            const key = `${item.text}\u0000${item.romanization ?? ""}`;
            if (handled.has(key)) {
                continue;
            }
            handled.add(key);
            results.push(item);
        }
        return results;
    }
}
