import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { YingWaaLexicon, YingWaaUnit } from './YingWaaUnit';

// yingwaa_table(code INTEGER NOT NULL, word TEXT NOT NULL, romanization TEXT NOT NULL, pronunciation TEXT NOT NULL, note TEXT NOT NULL, interpretation TEXT NOT NULL);

export class YingWaaHelper {
    static search(text: string, store: relationalStore.RdbStore): YingWaaLexicon[] {
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
        const lexicons: YingWaaLexicon[] = [];
        codes.forEach(code => {
            const instance = YingWaaHelper.match(code, store);
            lexicons.push(instance);
        })
        return lexicons.filter(item => item.isNotEmpty);
    }
    static match(code: number, store: relationalStore.RdbStore): YingWaaLexicon {
        const units: YingWaaUnit[] = [];
        const command: string = `SELECT word, romanization, pronunciation, note, interpretation FROM yingwaa_table WHERE code = ${code};`;
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command);
            while (res.goToNextRow()) {
                const word = res.getString(0);
                const romanization = res.getString(1);
                const pronunciation = res.getString(2);
                const note = res.getString(3);
                const interpretation = res.getString(4);
                const instance: YingWaaUnit = {
                    word: word,
                    romanization: romanization,
                    pronunciation: pronunciation,
                    note: note,
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
        const adjustedUnits: YingWaaUnit[] = units.map((unit) => {
            const fetchedHomophones = YingWaaHelper.fetchHomophones(unit.romanization, store).filter(item => item !== word);
            const newInstance: YingWaaUnit = {
                word: unit.word,
                romanization: unit.romanization,
                pronunciation: unit.pronunciation,
                note: (unit.note == "X" ? undefined : unit.note),
                interpretation: (unit.interpretation == "X") ? undefined : unit.interpretation,
                homophones: fetchedHomophones
            };
            return newInstance;
        })
        const lexicon: YingWaaLexicon = {
            isEmpty: adjustedUnits.length < 1,
            isNotEmpty: adjustedUnits.length > 0,
            word: word,
            units: adjustedUnits
        }
        return lexicon;
    }
    private static fetchHomophones(romanization: string, store: relationalStore.RdbStore): string[] {
        const homophones: string[] = [];
        const command: string = "SELECT word FROM yingwaa_table WHERE romanization = ? LIMIT 11;";
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
