import { relationalStore } from "@kit.ArkData";
import { BusinessError } from '@kit.BasicServicesKit';

export class Converter {
    static convert(text: string, simplify: boolean, store: relationalStore.RdbStore): string {
        const newCodes: number[] = [];
        for (let index = 0; index < text.length; index++) {
            const code = text.codePointAt(index) ?? 0;
            const newCode = simplify ? Converter.t2s(code, store) : Converter.s2t(code, store);
            newCodes.push(newCode);
        }
        return String.fromCodePoint(...newCodes);
    }
    private static t2s(code: number, store: relationalStore.RdbStore): number {
        let newCode: number = code;
        const command: string = `SELECT right FROM variant_sim WHERE left = ${code};`;
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
}
