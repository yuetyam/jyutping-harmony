import { relationalStore } from "@kit.ArkData";
import { BusinessError } from '@kit.BasicServicesKit';
import { Candidate } from "./Candidate";
import { InputKeyEvent } from "./InputKeyEvent";
import { Lexicon } from "./Lexicon";
import { LexiconType } from "./LexiconType";

export class InputMemory {
    private static hashCode(str: string): number {
        let hash = 0;
        for (let i = 0; i < str.length; i++) {
            hash = Math.imul(31, hash) + str.charCodeAt(i) | 0;
        }
        return hash;
    }

    static async search(events: InputKeyEvent[], store: relationalStore.RdbStore): Promise<Lexicon[]> {
        const text = events.map((event) => event.text).join("")
        const code = InputMemory.hashCode(text);
        return InputMemory.match(text, code, store);
    }
    private static match(text: string, code: number, store: relationalStore.RdbStore): Lexicon[] {
        const inputCount = text.length;
        const lexicons: Lexicon[] = [];
        const limit = 6;
        const command: string = "SELECT rowid, word, romanization FROM memory WHERE ping = ? OR shortcut = ? ORDER BY frequency DESC LIMIT ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [code, code, limit]);
            while (res.goToNextRow()) {
                const num = res.getLong(0);
                const word = res.getString(1);
                const romanization = res.getString(2);
                const instance: Lexicon = {
                    type: LexiconType.Cantonese,
                    text: word,
                    romanization: romanization,
                    input: text,
                    inputCount: inputCount,
                    number: num,
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

    static prepare(store: relationalStore.RdbStore) {
        const command: string = "CREATE TABLE IF NOT EXISTS memory(word TEXT NOT NULL, romanization TEXT NOT NULL, frequency INTEGER NOT NULL, shortcut INTEGER NOT NULL, ping INTEGER NOT NULL);";
        try {
            store.executeSync(command);
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`error in prepare(), message: ${err.message}, code: ${err.code}`)
        }
    }
    static process(candidates: Candidate[], store: relationalStore.RdbStore) {
        const text: string = candidates.map(item => item.lexicon.text).join("");
        const romanization: string = candidates.map(item => item.lexicon.romanization ?? "").join(" ");
        const concatenated: Lexicon = {
            type: LexiconType.Cantonese,
            text: text,
            romanization: romanization,
            input: "i",
            inputCount: 1,
            number: 0
        }
        InputMemory.handle(concatenated, store);
    }
    private static handle(lexicon: Lexicon, store: relationalStore.RdbStore) {
        const frequency = InputMemory.find(lexicon, store);
        if (frequency > 0) {
            const newFrequency = frequency + 1;
            InputMemory.update(lexicon, newFrequency, store);
        } else {
            InputMemory.insert(lexicon, store);
        }
    }
    private static find(lexicon: Lexicon, store: relationalStore.RdbStore): number {
        let frequency: number = 0;
        const romanization = lexicon.romanization ?? "X";
        const command: string = "SELECT frequency FROM memory WHERE word = ? AND romanization = ? LIMIT 1;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [lexicon.text, romanization]);
            if (res.goToNextRow()) {
                frequency = res.getLong(0);
            }
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            res?.close();
        }
        return frequency;
    }
    private static update(lexicon: Lexicon, newFrequency: number, store: relationalStore.RdbStore) {
        const romanization = lexicon.romanization ?? "X";
        const command: string = `UPDATE memory SET frequency = ${newFrequency} WHERE word = ? AND romanization = ?;`;
        try {
            store.executeSync(command, [lexicon.text, romanization]);
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        }
    }
    private static insert(lexicon: Lexicon, store: relationalStore.RdbStore) {
        const romanization = lexicon.romanization ?? "X";
        const anchors = romanization.match(/\b(\w)/g)?.join('') ?? "X";
        const shortcutCode = InputMemory.hashCode(anchors);
        const syllableText = romanization.replace(/[\d\s]/g, '');
        const pingCode = InputMemory.hashCode(syllableText);
        const leadingText: string = "INSERT INTO memory (word, romanization, frequency, shortcut, ping) VALUES (";
        const trailingText: string = `'${lexicon.text}', '${romanization}', 1, ${shortcutCode}, ${pingCode});`;
        const command: string = leadingText + trailingText;
        try {
            store.executeSync(command);
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        }
    }
}
