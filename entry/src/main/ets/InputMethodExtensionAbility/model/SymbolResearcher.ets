import { EngineCode } from "./EngineCode";
import { NineKeySegmenter } from "./NineKeySegmenter";
import { relationalStore } from "@kit.ArkData";
import { BusinessError } from "@kit.BasicServicesKit";
import { Emoji } from "../emoji/Emoji";
import { Combo } from "../ninekey/Combo";
import { CharCode } from "./CharCode";
import { Lexicon } from "./Lexicon";
import { LexiconType } from "./LexiconType";
import { Scheme, Segmentation } from "./Segmenter";
import { VirtualInputKey } from "./VirtualInputKey";

export class SymbolResearcher {
    static search(keys: VirtualInputKey[], segmentation: Segmentation, store: relationalStore.RdbStore): Lexicon[] {
        const input = CharCode.keysText(keys);
        const length = keys.filter((key) => key.isSyllableLetter).length;
        const command = "SELECT category, code_point, cantonese, romanization FROM symbol_table WHERE spell = CAST(? AS INTEGER) AND complexity = CAST(? AS INTEGER) ORDER BY rowid;";
        return SymbolResearcher.distinct(segmentation.filter((scheme) => SymbolResearcher.schemeLength(scheme) === length).flatMap((scheme) => {
            return SymbolResearcher.query(command, [EngineCode.keys(scheme.flatMap((syllable) => syllable.origin)), EngineCode.complexity(scheme.map((syllable) => syllable.origin.length))], input, store);
        }));
    }

    static searchNineKey(combos: Combo[], store: relationalStore.RdbStore): Lexicon[] {
        const segmentation = NineKeySegmenter.segment(combos, store);
        const command = "SELECT category, code_point, cantonese, romanization FROM symbol_table WHERE spell_9key = CAST(? AS INTEGER) AND complexity = CAST(? AS INTEGER) ORDER BY rowid;";
        const letters: string[] = ["", "r", "a", "d", "g", "j", "m", "p", "t", "w"];
        return SymbolResearcher.distinct(segmentation.filter((scheme) => scheme.reduce((total, syllable) => total + syllable.alias.length, 0) === combos.length).flatMap((scheme) => {
            const digits = scheme.flatMap((syllable) => syllable.origin);
            return SymbolResearcher.query(command, [EngineCode.decimalOverflowed(digits).toString(), EngineCode.complexity(scheme.map((syllable) => syllable.origin.length))], digits.map((digit) => letters[digit]).join(""), store);
        }));
    }

    private static query(command: string, bindArgs: relationalStore.ValueType[], input: string,
        store: relationalStore.RdbStore): Lexicon[] {
        const items: Lexicon[] = [];
        let resultSet: relationalStore.ResultSet | undefined = undefined;
        try {
            resultSet = store.querySqlSync(command, bindArgs);
            while (resultSet.goToNextRow()) {
                const category = resultSet.getLong(0);
                const source = resultSet.getString(1);
                const codePointText = (category === 1 || category === 4) ?
                    SymbolResearcher.skinToneTarget(source, store) ?? source : source;
                const text = Emoji.fromCodePointText(codePointText);
                if (text === undefined) {
                    continue;
                }
                items.push({
                    type: category < 10 ? LexiconType.Emoji : LexiconType.Symbol,
                    text: text,
                    romanization: resultSet.getString(3),
                    input: input,
                    inputCount: input.length,
                    number: 0,
                    mark: input,
                    note: resultSet.getString(2)
                });
            }
        } catch (error) {
            SymbolResearcher.logError(error);
        } finally {
            SymbolResearcher.closeResultSet(resultSet);
        }
        return items;
    }

    private static skinToneTarget(source: string, store: relationalStore.RdbStore): string | undefined {
        const command: string = "SELECT target FROM emoji_skin_map WHERE source = ? LIMIT 1;";
        let target: string | undefined = undefined;
        let resultSet: relationalStore.ResultSet | undefined = undefined;
        try {
            resultSet = store.querySqlSync(command, [source]);
            if (resultSet.goToFirstRow()) {
                target = resultSet.getString(0);
            }
        } catch (error) {
            SymbolResearcher.logError(error);
        } finally {
            SymbolResearcher.closeResultSet(resultSet);
        }
        return target;
    }

    private static schemeLength(scheme: Scheme): number {
        return scheme.reduce((total, syllable) => total + syllable.alias.length, 0);
    }

    private static distinct(items: Lexicon[]): Lexicon[] {
        const handled: string[] = [];
        return items.filter((item) => {
            const key = item.text;
            if (handled.includes(key)) {
                return false;
            }
            handled.push(key);
            return true;
        });
    }

    private static closeResultSet(resultSet: relationalStore.ResultSet | undefined): void {
        try {
            resultSet?.close();
        } catch (error) {
            SymbolResearcher.logError(error);
        }
    }

    private static logError(error: Object): void {
        const err: BusinessError = error as BusinessError;
        console.error(`message: ${err.message}, code: ${err.code}`);
    }
}
