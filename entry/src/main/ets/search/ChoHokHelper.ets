import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { ChoHokLexicon, ChoHokUnit } from './ChoHokUnit';

// chohok_table(code INTEGER NOT NULL, word TEXT NOT NULL, romanization TEXT NOT NULL, initial TEXT NOT NULL, final TEXT NOT NULL, tone TEXT NOT NULL, faancit TEXT NOT NULL);

export class ChoHokHelper {
    static search(text: string, store: relationalStore.RdbStore): ChoHokLexicon[] {
        if (text.length < 1) {
            return [];
        }
        const codes = new Set<number>();
        for (const char of text) {
            const code = char.codePointAt(0);
            if (code) {
                codes.add(code);
            }
        }
        const lexicons: ChoHokLexicon[] = [];
        codes.forEach(code => {
            const instance = ChoHokHelper.match(code, store);
            lexicons.push(instance);
        })
        return lexicons.filter(item => item.isNotEmpty);
    }
    static match(code: number, store: relationalStore.RdbStore): ChoHokLexicon {
        const units: ChoHokUnit[] = [];
        const command: string = `SELECT * FROM chohok_table WHERE code = ${code};`;
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command);
            while (res.goToNextRow()) {
                // const code = res.getLong(0);
                const word = res.getString(1);
                const romanization = res.getString(2);
                const initial = res.getString(3);
                const final = res.getString(4);
                const tone = res.getString(5);
                const faancit = res.getString(6);
                const instance: ChoHokUnit = {
                    word: word,
                    romanization: romanization,
                    pronunciation: ChoHokHelper.pronunciationFrom(initial, final),
                    tone: tone,
                    faancit: (faancit + "切"),
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
        const adjustedUnits: ChoHokUnit[] = units.map((unit) => {
            const fetchedHomophones = ChoHokHelper.fetchHomophones(unit.romanization, store).filter(item => item !== word);
            const newInstance: ChoHokUnit = {
                word: unit.word,
                romanization: unit.romanization,
                pronunciation: unit.pronunciation,
                tone: unit.tone,
                faancit: unit.faancit,
                homophones: fetchedHomophones
            };
            return newInstance;
        })
        const lexicon: ChoHokLexicon = {
            isEmpty: adjustedUnits.length < 1,
            isNotEmpty: adjustedUnits.length > 0,
            word: word,
            units: adjustedUnits
        }
        return lexicon;
    }
    private static fetchHomophones(romanization: string, store: relationalStore.RdbStore): string[] {
        const homophones: string[] = [];
        const command: string = "SELECT word FROM chohok_table WHERE romanization = ? LIMIT 11;";
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
    private static pronunciationFrom(initial: string, final: string): string {
        const convertedInitial: string = (initial === "X") ? "" : initial;
        const convertedFinal: string = (final === "X") ? "" : final;
        return convertedInitial + convertedFinal;
    }
}
