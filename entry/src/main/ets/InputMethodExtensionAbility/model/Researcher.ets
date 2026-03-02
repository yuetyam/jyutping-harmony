import { relationalStore } from "@kit.ArkData";
import { BusinessError } from '@kit.BasicServicesKit';
import { VirtualInputKey } from "./VirtualInputKey";
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
    private static radix100Combined(numbers: number[]): number {
        if (numbers.length > 8) {
            // Max value: 9007199254740992
            return 0;
        } else {
            return numbers.reduce((acc, num) => acc * 100 + num, 0);
        }
    }
    private static anchorsCode(keys: VirtualInputKey[]): number {
        const codes = keys.map((key) => (key === VirtualInputKey.letterY) ? VirtualInputKey.letterJ.code : key.code)
        return Researcher.radix100Combined(codes);
    }

    static async search(keys: VirtualInputKey[], store: relationalStore.RdbStore): Promise<Lexicon[]> {
        return Researcher.processSlices(keys, store);
    }
    private static processSlices(keys: VirtualInputKey[], store: relationalStore.RdbStore): Lexicon[] {
        const inputLength: number = keys.length;
        const range = [...Array(inputLength)].map((value: number, index: number) => index);
        let items: Lexicon[] = range.flatMap(num => {
            const leadingKeys = keys.slice(0, inputLength - num);
            const leadingText = leadingKeys.map((key) => key.text).join("")
            const spellMatched = Researcher.hashMatch(leadingText, store);
            const anchorsMatched = Researcher.anchorsMatch(leadingKeys, leadingText, store);
            return [...spellMatched, ...anchorsMatched];
        })
        return items;
    }

    private static anchorsMatch(keys: VirtualInputKey[], text: string, store: relationalStore.RdbStore): Lexicon[] {
        const code = Researcher.anchorsCode(keys);
        if (code === 0) {
            return [];
        }
        const inputCount = keys.length;
        const lexicons: Lexicon[] = [];
        const limit = 50;
        const command: string = "SELECT rowid, word, romanization FROM core_lexicon WHERE anchors = ? LIMIT ?;";
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
    private static hashMatch(text: string, store: relationalStore.RdbStore): Lexicon[] {
        const inputCount = text.length;
        const lexicons: Lexicon[] = [];
        const code = Researcher.hashCode(text);
        const limit = -1;
        const command: string = "SELECT rowid, word, romanization FROM core_lexicon WHERE spell = ? LIMIT ?;";
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
    static test(store: relationalStore.RdbStore): number {
        let num: number = -1;
        const command: string = "SELECT rowid romanization FROM core_lexicon WHERE anchors = 32 LIMIT 1;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command);
            if (res.goToNextRow()) {
                num = res.getLong(0);
            }
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            res?.close();
        }
        return num;
    }
}
