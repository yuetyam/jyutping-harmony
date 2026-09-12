import { relationalStore } from "@kit.ArkData";
import { BusinessError } from "@kit.BasicServicesKit";
import { Combo } from "../ninekey/Combo";
import { EngineCode } from "./EngineCode";
import { EngineLexicon } from "./EngineLexicon";
import { ExtraEntry } from "./ExtraEntry";
import { Lexicon } from "./Lexicon";
import { NineKeyScheme, NineKeySegmentation, NineKeySegmenter } from "./NineKeySegmenter";

export class NineKeyEngine {
    static suggest(combos: Combo[], segmentation: NineKeySegmentation, store: relationalStore.RdbStore, limit: number = -1): Lexicon[] {
        if (combos.length === 0 || combos.some((combo) => combo.isSpecial)) return [];
        if (segmentation.length === 0) return NineKeyEngine.slices(combos, store, limit);
        if (combos.length === 1) return NineKeyEngine.anchors(combos, store, limit);
        const ideal = segmentation.filter((scheme) => NineKeyEngine.schemeLength(scheme) === combos.length);
        const schemes: NineKeyScheme[] = ideal.length === 0 ? segmentation : ideal.flatMap((scheme) => scheme.map((_, index) => scheme.slice(0, scheme.length - index)));
        const queried = schemes.flatMap((scheme) => NineKeyEngine.perform(scheme, store, limit));
        const full = EngineLexicon.distinct(queried.filter((item) => item.inputCount === combos.length).sort((a, b) => a.number - b.number));
        const partial = EngineLexicon.distinct(queried.filter((item) => item.inputCount < combos.length).sort(EngineLexicon.compare));
        const fetched = EngineLexicon.distinct([...full, ...(full.length === 0 ? ExtraEntry.nineKeySearch(combos) : []), ...NineKeyEngine.anchors(combos, store, limit).slice(0, 4), ...partial]);
        if (fetched.length === 0) return NineKeyEngine.slices(combos, store, limit);
        const head = fetched[0];
        if (head.inputCount >= combos.length) return fetched;
        const tailCombos = combos.slice(head.inputCount);
        const tails = NineKeyEngine.suggest(tailCombos, NineKeySegmenter.segment(tailCombos, store), store, 20);
        const compounds = tails.map((tail) => EngineLexicon.concatenate(head, tail)).sort(EngineLexicon.compare).slice(0, 1);
        return [...compounds, ...fetched];
    }

    private static schemeLength(scheme: NineKeyScheme): number {
        return scheme.reduce((total, syllable) => total + syllable.alias.length, 0);
    }

    private static slices(combos: Combo[], store: relationalStore.RdbStore, limit: number): Lexicon[] {
        const items: Lexicon[] = [];
        for (let length = Math.min(9, combos.length); length >= 1; length--) items.push(...NineKeyEngine.anchors(combos.slice(0, length), store, limit));
        return items;
    }

    private static anchors(combos: Combo[], store: relationalStore.RdbStore, limit: number): Lexicon[] {
        if (combos.length > 9) return [];
        return NineKeyEngine.query("anchors_9key", EngineCode.combos(combos), "char_count", combos.length.toString(), store, limit < 0 ? 100 : limit, true);
    }

    private static perform(scheme: NineKeyScheme, store: relationalStore.RdbStore, limit: number): Lexicon[] {
        if (scheme.length === 0 || scheme.length > 9) return [];
        const complexity = EngineCode.complexity(scheme.map((syllable) => syllable.origin.length));
        const irregular = scheme.some((syllable) => syllable.isIrregular);
        const code = irregular ? EngineCode.keys(scheme.flatMap((syllable) => syllable.serialOrigin)) : EngineCode.decimalOverflowed(scheme.flatMap((syllable) => syllable.origin)).toString();
        return NineKeyEngine.query(irregular ? "spell" : "spell_9key", code, "complexity", complexity, store, limit, false);
    }

    private static query(column: string, code: string, constraint: string, count: string, store: relationalStore.RdbStore, limit: number, anchors: boolean): Lexicon[] {
        const items: Lexicon[] = [];
        let result: relationalStore.ResultSet | undefined;
        try {
            result = store.querySqlSync(`SELECT rowid, word, romanization FROM lexicon_core WHERE ${column} = CAST(? AS INTEGER) AND ${constraint} = CAST(? AS INTEGER) ORDER BY rowid LIMIT ?;`, [code, count, limit]);
            while (result.goToNextRow()) {
                const romanization = result.getString(2);
                const mark = anchors ? romanization.split(" ").map((syllable) => syllable[0]).join("") : romanization.replace(/[1-6]/g, "");
                items.push(EngineLexicon.make(result.getString(1), romanization, mark.replace(/ /g, ""), result.getLong(0), mark));
            }
        } catch (error) {
            console.error(`Nine-key lookup failed: ${(error as BusinessError).message}`);
        } finally {
            try {
                result?.close();
            } catch (error) {
                console.error(`Failed to close engine result: ${(error as BusinessError).message}`);
            }
        }
        return items;
    }
}
