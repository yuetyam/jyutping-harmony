import { relationalStore } from "@kit.ArkData";
import { BusinessError } from "@kit.BasicServicesKit";
import { Combo } from "../ninekey/Combo";
import { EngineCode } from "./EngineCode";
import { CharCode } from "./CharCode";
import { Lexicon } from "./Lexicon";
import { LexiconType } from "./LexiconType";
import { VirtualInputKey } from "./VirtualInputKey";

export class PlainText {
    static search(keys: VirtualInputKey[], store: relationalStore.RdbStore): Lexicon[] {
        const input = CharCode.keysText(keys);
        if (input.length < 1) {
            return [];
        }
        const spell = EngineCode.keys(keys);
        const items: Lexicon[] = [];
        const command = "SELECT word FROM plain_text_table WHERE spell = CAST(? AS INTEGER) AND letter_count = ? ORDER BY rowid;";
        let resultSet: relationalStore.ResultSet | undefined = undefined;
        try {
            resultSet = store.querySqlSync(command, [spell, keys.length]);
            while (resultSet.goToNextRow()) {
                items.push(PlainText.makeLexicon(resultSet.getString(0), input, input));
            }
        } catch (error) {
            PlainText.logError(error);
        } finally {
            PlainText.closeResultSet(resultSet);
        }
        return items;
    }

    static queryNineKey(combos: Combo[], store: relationalStore.RdbStore): Lexicon[] {
        const code = EngineCode.combos(combos);
        if (combos.length < 1) {
            return [];
        }
        const items: Lexicon[] = [];
        const command = "SELECT input, word FROM plain_text_table WHERE spell_9key = CAST(? AS INTEGER) AND letter_count = ? ORDER BY rowid;";
        let resultSet: relationalStore.ResultSet | undefined = undefined;
        try {
            resultSet = store.querySqlSync(command, [code, combos.length]);
            while (resultSet.goToNextRow()) {
                const input = resultSet.getString(0);
                const mark = resultSet.getString(1);
                items.push(PlainText.makeLexicon(mark, input, input));
            }
        } catch (error) {
            PlainText.logError(error);
        } finally {
            PlainText.closeResultSet(resultSet);
        }
        return items;
    }

    private static makeLexicon(text: string, input: string, romanization: string): Lexicon {
        return {
            type: LexiconType.Text,
            text: text,
            romanization: romanization,
            input: input,
            inputCount: input.length,
            number: 0,
            mark: input
        };
    }

    private static closeResultSet(resultSet: relationalStore.ResultSet | undefined) {
        try {
            resultSet?.close();
        } catch (error) {
            PlainText.logError(error);
        }
    }

    private static logError(error: Object) {
        const err: BusinessError = error as BusinessError;
        console.error(`message: ${err.message}, code: ${err.code}`);
    }
}
