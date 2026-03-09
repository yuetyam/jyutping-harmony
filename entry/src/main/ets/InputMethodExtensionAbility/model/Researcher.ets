import { relationalStore } from "@kit.ArkData";
import { BusinessError } from '@kit.BasicServicesKit';
import { VirtualInputKey } from "./VirtualInputKey";
import { Lexicon } from "./Lexicon";
import { LexiconType } from "./LexiconType";
import { Scheme, Segmentation } from "./Segmenter";

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
    static async suggest(keys: VirtualInputKey[], segmentation: Segmentation, store: relationalStore.RdbStore): Promise<Lexicon[]> {
        if (segmentation.length < 1) {
            return Researcher.processSlices(keys, store);
        }
        const inputLength = keys.length;
        const text = keys.map((key) => key.text).join("");
        const spellMatched = Researcher.hashMatch(text, store);
        const anchorsMatched = Researcher.anchorsMatch(keys, text, store);
        const queried = Researcher.query(inputLength, segmentation, store);
        const shouldProcessSlices: boolean = (spellMatched.length < 1) && (anchorsMatched.length < 1) && (queried.length < 1);
        if (shouldProcessSlices) {
            return Researcher.processSlices(keys, store);
        } else {
            return [...spellMatched, ...anchorsMatched, ...queried];
        }
    }
    private static query(inputLength: number, segmentation: Segmentation, store: relationalStore.RdbStore): Lexicon[] {
        const idealSchemes = segmentation.filter((scheme) => scheme.flatMap((syllable) => syllable.alias).length === inputLength);
        if (idealSchemes.length < 1) {
            return segmentation.flatMap((scheme) => Researcher.perform(scheme, store));
        } else {
            return idealSchemes.flatMap((scheme) => {
                switch (scheme.length) {
                    case 0: return Array<Lexicon>();
                    case 1: return Researcher.perform(scheme, store);
                    default:
                        return scheme.map((_, index) => scheme.slice(0, scheme.length - index)).flatMap((sliced) => Researcher.perform(sliced, store));
                }
            })
        }
    }
    private static perform(scheme: Scheme, store: relationalStore.RdbStore): Lexicon[] {
        const anchorKeys = scheme.flatMap((syllable) => syllable.origin[0]);
        const anchorsCode = Researcher.anchorsCode(anchorKeys);
        const aliasKeys = scheme.flatMap((syllable) => syllable.alias);
        const aliasText = aliasKeys.map((key) => key.text).join("");
        const inputCount = aliasKeys.length;
        const originKeys = scheme.flatMap((syllable) => syllable.origin);
        const originText = originKeys.map((key) => key.text).join("");
        const spellCode = Researcher.hashCode(originText);
        return Researcher.strictMatch(anchorsCode, spellCode, aliasText, inputCount, store);
    }
    private static anchorsMatch(keys: VirtualInputKey[], text: string, store: relationalStore.RdbStore): Lexicon[] {
        const code = Researcher.anchorsCode(keys);
        if (code === 0) { return []; }
        const inputCount = keys.length;
        const lexicons: Lexicon[] = [];
        const limit = 50;
        const command: string = "SELECT rowid, word, romanization FROM core_lexicon WHERE anchors = ? LIMIT ?;";
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
                    input: text,
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
                const rowID = res.getLong(0);
                const word = res.getString(1);
                const romanization = res.getString(2);
                const instance: Lexicon = {
                    type: LexiconType.Cantonese,
                    text: word,
                    romanization: romanization,
                    input: text,
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
    private static strictMatch(anchors: number, spell: number, input: string, inputCount: number, store: relationalStore.RdbStore): Lexicon[] {
        const lexicons: Lexicon[] = [];
        const limit = -1;
        const command: string = "SELECT rowid, word, romanization FROM core_lexicon WHERE spell = ? AND anchors = ? LIMIT ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [spell, anchors, limit]);
            while (res.goToNextRow()) {
                const num = res.getLong(0);
                const word = res.getString(1);
                const romanization = res.getString(2);
                const instance: Lexicon = {
                    type: LexiconType.Cantonese,
                    text: word,
                    romanization: romanization,
                    input: input,
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
