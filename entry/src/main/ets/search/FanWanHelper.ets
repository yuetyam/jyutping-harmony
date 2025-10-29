import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { FanWanLexicon, FanWanUnit } from './FanWanUnit';

// fanwantable(code INTEGER NOT NULL, word TEXT NOT NULL, romanization TEXT NOT NULL, initial TEXT NOT NULL, final TEXT NOT NULL, yamyeung TEXT NOT NULL, tone TEXT NOT NULL, rhyme TEXT NOT NULL, interpretation TEXT NOT NULL);

export class FanWanHelper {
    static search(text: string, store: relationalStore.RdbStore): FanWanLexicon[] {
        if (text.length > 0) {
            const codes = new Set<number>();
            for (let index = 0; index < text.length; index++) {
                const code = text.codePointAt(index);
                if (code) {
                    codes.add(code);
                }
            }
            const lexicons: FanWanLexicon[] = [];
            codes.forEach(code => {
                const instance = FanWanHelper.match(code, store);
                lexicons.push(instance);
            })
            return lexicons.filter(item => item.isNotEmpty);
        } else {
            return [];
        }
    }
    static match(code: number, store: relationalStore.RdbStore): FanWanLexicon {
        const units: FanWanUnit[] = [];
        const command: string = `SELECT * FROM fanwantable WHERE code = ${code};`;
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command);
            while (res.goToNextRow()) {
                // const code = res.getLong(0);
                const word = res.getString(1);
                const romanization = res.getString(2);
                const initial = res.getString(3);
                const final = res.getString(4);
                const yamyeung = res.getString(5);
                const tone = res.getString(6);
                const rhyme = res.getString(7);
                const interpretation = res.getString(8);
                const instance: FanWanUnit = {
                    word: word,
                    romanization: romanization,
                    initial: initial,
                    final: final,
                    yamyeung: yamyeung,
                    tone: tone,
                    rhyme: rhyme,
                    interpretation: interpretation,
                    homophones: []
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
        const adjustedUnits: FanWanUnit[] = units.map((unit) => {
            const fetchedHomophones = FanWanHelper.fetchHomophones(unit.romanization, store).filter(item => item !== word);
            const newInstance: FanWanUnit = {
                word: unit.word,
                romanization: unit.romanization.replace("7", "1").replace("8", "3").replace("9", "6"),
                initial: unit.initial,
                final: unit.final,
                yamyeung: unit.yamyeung,
                tone: unit.tone,
                rhyme: unit.rhyme,
                interpretation: unit.interpretation,
                homophones: fetchedHomophones
            };
            return newInstance;
        })
        const lexicon: FanWanLexicon = {
            isEmpty: adjustedUnits.length < 1,
            isNotEmpty: adjustedUnits.length > 0,
            word: word,
            units: adjustedUnits
        }
        return lexicon;
    }
    private static fetchHomophones(romanization: string, store: relationalStore.RdbStore): string[] {
        const homophones: string[] = [];
        const command: string = "SELECT word FROM chohoktable WHERE romanization = ? LIMIT 11;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [romanization]);
            while (res.goToNextRow()) {
                const word = res.getString(0);
                homophones.push(word);
            }
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            res?.close();
        }
        return homophones;
    }
}
