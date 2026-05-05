import { relationalStore } from "@kit.ArkData";
import { BusinessError } from "@kit.BasicServicesKit";
import { Lexicon } from "./Lexicon";

export class Converter {
    private static readonly compoundThreshold: number = 1000000;
    static dispatch(memory: Lexicon[], queried: Lexicon[]): Lexicon[] {
        const idealMemory = memory.filter((item) => item.number === -1);
        const notIdealMemory = memory.filter((item) => item.number === -2);
        let chained: Lexicon[] = idealMemory.length < 1 ?
            [...queried] :
            queried.filter((item) => item.number <= Converter.compoundThreshold);
        for (let index = notIdealMemory.length - 1; index >= 0; index--) {
            const entry = notIdealMemory[index];
            if (entry === undefined) {
                continue;
            }
            const insertIndex = chained.findIndex((item) => item.inputCount <= entry.inputCount);
            if (insertIndex >= 0) {
                chained.splice(insertIndex, 0, entry);
            } else {
                chained.push(entry);
            }
        }
        return Converter.distinctLexicons([
            ...idealMemory.slice(0, 3),
            ...idealMemory,
            ...chained,
        ]);
    }
    static convert(text: string, simplify: boolean, store: relationalStore.RdbStore | undefined): string {
        if (store) {
            const codePoints: number[] = [];
            for (const char of text) {
                const code = char.codePointAt(0);
                if (code) {
                    const newCode = simplify ? Converter.t2s(code, store) : Converter.s2t(code, store);
                    codePoints.push(newCode);
                }
            }
            return String.fromCodePoint(...codePoints);
        } else {
            return text;
        }
    }
    private static t2s(code: number, store: relationalStore.RdbStore): number {
        let newCode: number = code;
        const command: string = `SELECT right FROM variant_sim WHERE left = ${code} LIMIT 1;`;
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command);
            if (res.goToNextRow()) {
                newCode = res.getLong(0);
            }
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            res?.close();
        }
        return newCode;
    }
    private static s2t(code: number, store: relationalStore.RdbStore): number {
        let newCode: number = code;
        const command: string = `SELECT left FROM variant_sim WHERE right = ${code} LIMIT 1;`;
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command);
            if (res.goToNextRow()) {
                newCode = res.getLong(0);
            }
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            res?.close();
        }
        return newCode;
    }
    private static lexiconKey(item: Lexicon): string {
        return `${item.type}\u0000${item.text}\u0000${item.romanization ?? ""}`;
    }
    private static distinctLexicons(items: Lexicon[]): Lexicon[] {
        const handled: string[] = [];
        const results: Lexicon[] = [];
        for (const item of items) {
            const key = Converter.lexiconKey(item);
            if (handled.includes(key)) {
                continue;
            }
            handled.push(key);
            results.push(item);
        }
        return results;
    }
}
