import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { GwongWanLexicon, GwongWanUnit } from './GwongWanUnit';

// gwongwantable(code INTEGER NOT NULL, word TEXT NOT NULL, rhyme TEXT NOT NULL, subrhyme TEXT NOT NULL, subrhymeserial INTEGER NOT NULL, subrhymenumber INTEGER NOT NULL, upper TEXT NOT NULL, lower TEXT NOT NULL, initial TEXT NOT NULL, rounding TEXT NOT NULL, division TEXT NOT NULL, rhymeclass TEXT NOT NULL, repeating TEXT NOT NULL, tone TEXT NOT NULL, interpretation TEXT NOT NULL)

export class GwongWanHelper {
    static search(text: string, store: relationalStore.RdbStore): GwongWanLexicon[] {
        if (text.length > 0) {
            const codes = new Set<number>();
            for (let index = 0; index < text.length; index++) {
                const code = text.codePointAt(index);
                if (code) {
                    codes.add(code);
                }
            }
            const lexicons: GwongWanLexicon[] = [];
            codes.forEach(code => {
                const instance = GwongWanHelper.match(code, store);
                lexicons.push(instance);
            })
            return lexicons.filter(item => item.isNotEmpty);
        } else {
            return [];
        }
    }
    static match(code: number, store: relationalStore.RdbStore): GwongWanLexicon {
        const units: GwongWanUnit[] = [];
        const command: string = `SELECT * FROM gwongwantable WHERE code = ${code};`;
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command);
            while (res.goToNextRow()) {
                // const code = res.getLong(0);
                const word: string = res.getString(1);
                const rhyme: string = res.getString(2);
                const subRime: string = res.getString(3);
                const subRhymeSerial: number = res.getLong(4);
                const subRhymeNumber: number = res.getLong(5);
                const upper: string = res.getString(6);
                const lower: string = res.getString(7);
                const initial: string = res.getString(8);
                const rounding: string = res.getString(9);
                const division: string = res.getString(10);
                const rhymeClass: string = res.getString(11);
                const repeating: string = res.getString(12);
                const tone: string = res.getString(13);
                const interpretation: string = res.getString(14);
                const instance: GwongWanUnit = {
                    word: word,
                    rhyme: rhyme,
                    subRhyme: subRime,
                    subRhymeSerial: subRhymeSerial,
                    subRhymeNumber: subRhymeNumber,
                    upper: upper,
                    lower: lower,
                    initial: initial,
                    rounding: rounding,
                    division: division,
                    rhymeClass: rhymeClass,
                    repeating: repeating,
                    tone: tone,
                    interpretation: interpretation,
                };
                units.push(instance);
            }
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            res?.close();
        }
        const word: string = (units.length > 0) ? units[0].word : "?";
        const lexicon: GwongWanLexicon = {
            isEmpty: units.length < 1,
            isNotEmpty: units.length > 0,
            word: word,
            units: units
        }
        return lexicon;
    }
}
