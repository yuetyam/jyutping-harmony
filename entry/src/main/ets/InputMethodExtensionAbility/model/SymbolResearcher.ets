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
        const symbols = SymbolResearcher.match(input, input, store);
        const idealSchemes = segmentation.filter((scheme) => SymbolResearcher.schemeLength(scheme) === keys.length);
        for (const scheme of idealSchemes) {
            const originText = scheme.flatMap((syllable) => syllable.origin).map((key) => key.text).join("");
            symbols.push(...SymbolResearcher.match(originText, input, store));
        }
        return SymbolResearcher.distinct(symbols);
    }

    static searchNineKey(combos: Combo[], store: relationalStore.RdbStore): Lexicon[] {
        const code = CharCode.comboCode(combos);
        if (code < 1) {
            return [];
        }
        const input = combos.map((combo) => combo.leadingLetter).join("");
        return SymbolResearcher.query(
            "SELECT category, code_point, cantonese, romanization FROM symbol_table " +
                "WHERE nine_key_code = ? ORDER BY rowid;", [code], input, store);
    }

    private static match(text: string, input: string, store: relationalStore.RdbStore): Lexicon[] {
        if (text.length < 1) {
            return [];
        }
        const spell = SymbolResearcher.javaStringHashCode(text);
        return SymbolResearcher.query(
            "SELECT category, code_point, cantonese, romanization FROM symbol_table WHERE spell = ? ORDER BY rowid;",
            [spell], input, store);
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
        let target: string | undefined = undefined;
        let resultSet: relationalStore.ResultSet | undefined = undefined;
        try {
            resultSet = store.querySqlSync("SELECT target FROM emoji_skin_map WHERE source = ? LIMIT 1;", [source]);
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

    private static javaStringHashCode(text: string): number {
        let hash = 0;
        for (let index = 0; index < text.length; index++) {
            hash = ((hash * 31) + text.charCodeAt(index)) | 0;
        }
        return hash;
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
