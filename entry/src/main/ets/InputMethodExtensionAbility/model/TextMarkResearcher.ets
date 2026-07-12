import { relationalStore } from "@kit.ArkData";
import { BusinessError } from "@kit.BasicServicesKit";
import { Combo } from "../ninekey/Combo";
import { CharCode } from "./CharCode";
import { Lexicon } from "./Lexicon";
import { LexiconType } from "./LexiconType";
import { VirtualInputKey } from "./VirtualInputKey";

export class TextMarkResearcher {
    static search(keys: VirtualInputKey[], store: relationalStore.RdbStore): Lexicon[] {
        const input = CharCode.keysText(keys);
        if (input.length < 1) {
            return [];
        }
        const spell = TextMarkResearcher.javaStringHashCode(input);
        const items: Lexicon[] = [];
        const command = "SELECT mark FROM mark_table WHERE spell = ? ORDER BY rowid;";
        let resultSet: relationalStore.ResultSet | undefined = undefined;
        try {
            resultSet = store.querySqlSync(command, [spell]);
            while (resultSet.goToNextRow()) {
                items.push(TextMarkResearcher.makeLexicon(resultSet.getString(0), input, input));
            }
        } catch (error) {
            TextMarkResearcher.logError(error);
        } finally {
            TextMarkResearcher.closeResultSet(resultSet);
        }
        return items;
    }

    static queryNineKey(combos: Combo[], store: relationalStore.RdbStore): Lexicon[] {
        const code = CharCode.comboCode(combos);
        if (code < 1) {
            return [];
        }
        const items: Lexicon[] = [];
        const command = "SELECT input, mark FROM mark_table WHERE nine_key_code = ? ORDER BY rowid;";
        let resultSet: relationalStore.ResultSet | undefined = undefined;
        try {
            resultSet = store.querySqlSync(command, [code]);
            while (resultSet.goToNextRow()) {
                const input = resultSet.getString(0);
                const mark = resultSet.getString(1);
                items.push(TextMarkResearcher.makeLexicon(mark, input, mark));
            }
        } catch (error) {
            TextMarkResearcher.logError(error);
        } finally {
            TextMarkResearcher.closeResultSet(resultSet);
        }
        return items;
    }

    private static javaStringHashCode(text: string): number {
        let hash = 0;
        for (let index = 0; index < text.length; index++) {
            hash = ((hash * 31) + text.charCodeAt(index)) | 0;
        }
        return hash;
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
            TextMarkResearcher.logError(error);
        }
    }

    private static logError(error: Object) {
        const err: BusinessError = error as BusinessError;
        console.error(`message: ${err.message}, code: ${err.code}`);
    }
}
