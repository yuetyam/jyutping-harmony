import { relationalStore } from "@kit.ArkData";
import { BusinessError } from '@kit.BasicServicesKit';
import { Candidate } from "./Candidate";
import { FallbackLexiconHelper } from "./FallbackLexiconHelper";
import { FallbackT2SHelper } from "./FallbackT2SHelper";
import { VirtualInputKey } from "./VirtualInputKey";
import { Lexicon } from "./Lexicon";
import { LexiconType } from "./LexiconType";
import { Segmentation, Scheme } from "./Segmenter";

export class InputMemory {
    private static hashCode(str: string): number {
        let hash = 0;
        for (let i = 0; i < str.length; i++) {
            hash = Math.imul(31, hash) + str.charCodeAt(i) | 0;
        }
        return hash;
    }

    static search(keys: VirtualInputKey[], store: relationalStore.RdbStore): Lexicon[] {
        const text = keys.map((key) => key.text).join("")
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

    static suggest(keys: VirtualInputKey[], segmentation: Segmentation, store: relationalStore.RdbStore): Lexicon[] {
        const inputLength = keys.length;
        const text = keys.map((key) => key.text).join("");
        const pingCode = InputMemory.hashCode(text);
        const spellMatched = InputMemory.pingMatch(pingCode, text, inputLength, store);
        const anchorsMatched = InputMemory.shortcutMatch(keys, text, store);
        const queried = segmentation
            .filter((scheme) => scheme.flatMap((syllable) => syllable.alias).length === inputLength)
            .flatMap((scheme) => InputMemory.perform(scheme, text, inputLength, store));
        return [...spellMatched, ...anchorsMatched, ...queried];
    }
    private static perform(scheme: Scheme, input: string, inputLength: number, store: relationalStore.RdbStore): Lexicon[] {
        const originKeys = scheme.flatMap((syllable) => syllable.origin);
        const originText = originKeys.map((key) => key.text).join("");
        const code = InputMemory.hashCode(originText);
        return InputMemory.pingMatch(code, input, inputLength, store);
    }
    private static pingMatch(code: number, input: string, inputCount: number, store: relationalStore.RdbStore): Lexicon[] {
        const lexicons: Lexicon[] = [];
        const limit = -1;
        const command: string = "SELECT rowid, word, romanization FROM memory WHERE ping = ? ORDER BY frequency DESC LIMIT ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [code, limit]);
            while (res.goToNextRow()) {
                const rowID = res.getLong(0);
                const word = res.getString(1);
                const romanization = res.getString(2);
                const instance: Lexicon = {
                    type: LexiconType.Cantonese,
                    text: word,
                    romanization: romanization,
                    input: input,
                    inputCount: inputCount,
                    number: rowID,
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
    private static shortcutMatch(keys: VirtualInputKey[], input: string, store: relationalStore.RdbStore): Lexicon[] {
        const anchorsText = keys.map((key) => (key === VirtualInputKey.letterY) ? VirtualInputKey.letterJ.text : key.text).join("");
        const code = InputMemory.hashCode(anchorsText);
        if (code < 1) { return []; }
        const inputCount = keys.length;
        const lexicons: Lexicon[] = [];
        const limit = 5;
        const command: string = "SELECT rowid, word, romanization FROM memory WHERE shortcut = ? ORDER BY frequency DESC LIMIT ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [code, limit]);
            while (res.goToNextRow()) {
                const rowID = res.getLong(0);
                const word = res.getString(1);
                const romanization = res.getString(2);
                const instance: Lexicon = {
                    type: LexiconType.Cantonese,
                    text: word,
                    romanization: romanization,
                    input: input,
                    inputCount: inputCount,
                    number: rowID,
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
        try {
            const command: string = "CREATE TABLE IF NOT EXISTS memory(word TEXT NOT NULL, romanization TEXT NOT NULL, frequency INTEGER NOT NULL, shortcut INTEGER NOT NULL, ping INTEGER NOT NULL);";
            store.executeSync(command);
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`error in prepare(), message: ${err.message}, code: ${err.code}`)
        }
        try {
            const command: string = "CREATE TABLE IF NOT EXISTS fallback(word TEXT NOT NULL, romanization TEXT NOT NULL, shortcut INTEGER NOT NULL, ping INTEGER NOT NULL);";
            store.executeSync(command);
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`error in prepare(), message: ${err.message}, code: ${err.code}`)
        }
        try {
            const command: string = "CREATE TABLE IF NOT EXISTS variant_sim(left INTEGER NOT NULL, right INTEGER NOT NULL);";
            store.executeSync(command);
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`error in prepare(), message: ${err.message}, code: ${err.code}`)
        }
        InputMemory.prepareFallbackTables(store);
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


    // Fallback searching

    static fallbackSearch(keys: VirtualInputKey[], store: relationalStore.RdbStore): Lexicon[] {
        return InputMemory.fallBackProcessSlices(keys, store);
    }
    private static fallBackProcessSlices(keys: VirtualInputKey[], store: relationalStore.RdbStore): Lexicon[] {
        const inputLength: number = keys.length;
        const range = [...Array(inputLength)].map((value: number, index: number) => index);
        let items: Lexicon[] = range.flatMap(num => {
            const leadingKeys = keys.slice(0, inputLength - num);
            const leadingText = leadingKeys.map((key) => key.text).join("")
            const code = InputMemory.hashCode(leadingText);
            return InputMemory.fallBackMatch(leadingText, code, store);
        })
        return items;
    }
    private static fallBackMatch(text: string, code: number, store: relationalStore.RdbStore): Lexicon[] {
        const inputCount = text.length;
        const lexicons: Lexicon[] = [];
        const limit = 50;
        const command: string = "SELECT rowid, word, romanization FROM fallback WHERE ping = ? OR shortcut = ? LIMIT ?;";
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


    // Fallback tables preparation

    private static prepareFallbackTables(store: relationalStore.RdbStore) {
        const needs = InputMemory.needsFallbackInsertion(store);
        if (needs) {
            InputMemory.fallbackInsert(store);
            InputMemory.t2sInsert(store);
        }
    }
    private static fallbackInsert(store: relationalStore.RdbStore) {
        const valuesText = FallbackLexiconHelper.generate();
        const leadingText: string = "INSERT INTO fallback (word, romanization, shortcut, ping) VALUES ";
        const trailingText: string = `;`;
        const command: string = leadingText + valuesText + trailingText;
        try {
            store.executeSync(command);
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        }
    }
    private static t2sInsert(store: relationalStore.RdbStore) {
        const valuesText = FallbackT2SHelper.generate();
        const leadingText: string = "INSERT INTO variant_sim (left, right) VALUES ";
        const trailingText: string = `;`;
        const command: string = leadingText + valuesText + trailingText;
        try {
            store.executeSync(command);
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        }
    }
    private static needsFallbackInsertion(store: relationalStore.RdbStore): boolean {
        let needs: boolean = true;
        const command: string = "SELECT shortcut FROM fallback WHERE ping = 109014 LIMIT 1;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command);
            if (res.goToNextRow()) {
                const shortcut = res.getLong(0);
                needs = (shortcut != 110);
            }
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            res?.close();
        }
        return needs;
    }
}
