import { relationalStore } from "@kit.ArkData";
import { BusinessError } from '@kit.BasicServicesKit';
import { InputKeyEvent } from "./InputKeyEvent";
import { Lexicon } from "./Lexicon";
import { LexiconType } from "./LexiconType";

export class Researcher {
    private static hashCode(str: string): number {
        let hash = 0;
        for (let i = 0; i < str.length; i++) {
            hash = Math.imul(31, hash) + str.charCodeAt(i) | 0;
        }
        return hash;
    }
    static search(events: InputKeyEvent[], store: relationalStore.RdbStore): Lexicon[] {
        const text = events.map((item) => item.text).join("");
        return Researcher.hashMatch(text, store);
    }
    private static hashMatch(text: string, store: relationalStore.RdbStore): Lexicon[] {
        const inputCount = text.length;
        const lexicons: Lexicon[] = [];
        const code = Researcher.hashCode(text);
        const limit = -1;
        const command: string = "SELECT rowid, word, romanization FROM lexicontable WHERE ping = ? LIMIT ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [code, limit]);
            while (res.goToNextRow()) {
                const number = res.getLong(0);
                const word = res.getString(1);
                const romanization = res.getString(2);
                const instance: Lexicon = {
                    type: LexiconType.Cantonese,
                    text: word,
                    romanization: romanization,
                    input: text,
                    inputCount: inputCount,
                    number: number,
                };
                lexicons.push(instance);
            }
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            res?.close();
        }
        return lexicons;
    }
}
