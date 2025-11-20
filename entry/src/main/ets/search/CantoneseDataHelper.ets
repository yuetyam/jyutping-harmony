import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { CantoneseLexicon } from './CantoneseLexicon';
import { Pronunciation } from './Pronunciation';

export class CantoneseDataHelper {
    static search(text: string, store: relationalStore.RdbStore): CantoneseLexicon[] {
        if (text.length < 1) {
            return [];
        }
        const primary = CantoneseDataHelper.match(text, store);
        let characters = Array.from(text);
        let otherLexicons = characters.map((item) => CantoneseDataHelper.match(item, store))
        return [primary, ...otherLexicons];
    }
    private static match(text: string, store: relationalStore.RdbStore): CantoneseLexicon {
        const romanizations = CantoneseDataHelper.fetchRomanizations(text, store);
        const pronunciations: Pronunciation[] = romanizations.map( (romanization) => {
            const homophones = CantoneseDataHelper.fetchHomophones(romanization, store).filter(item => item !== text);
            const collocations = CantoneseDataHelper.fetchCollocations(text, romanization, store);
            const descriptions = CantoneseDataHelper.fetchDescriptions(text, romanization, store);
            let pronunciation: Pronunciation = {
                romanization: romanization,
                homophones: homophones,
                collocations: collocations,
                descriptions: descriptions
            }
            return pronunciation;
        })
        const definition = CantoneseDataHelper.fetchDefinition(text, store);
        const lexicon: CantoneseLexicon = {
            text: text,
            pronunciations: pronunciations,
            unihanDefinition: definition
        }
        return lexicon
    }
    private static fetchRomanizations(text: string, store: relationalStore.RdbStore): string[] {
        const items: string[] = [];
        const command: string = "SELECT romanization FROM jyutpingtable WHERE word = ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [text]);
            while (res.goToNextRow()) {
                const item = res.getString(0);
                items.push(item);
            }
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            res?.close();
        }
        return items;
    }
    private static fetchHomophones(romanization: string, store: relationalStore.RdbStore): string[] {
        const items: string[] = [];
        const command: string = "SELECT word FROM jyutpingtable WHERE romanization = ? LIMIT 11;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [romanization]);
            while (res.goToNextRow()) {
                const item = res.getString(0);
                items.push(item);
            }
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            res?.close();
        }
        return items;
    }
    private static fetchCollocations(word: string, romanization: string, store: relationalStore.RdbStore): string[] {
        let rowText: string | undefined = undefined;
        const command: string = "SELECT collocation FROM collocationtable WHERE word = ? AND romanization = ? LIMIT 1;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [word, romanization]);
            if (res.goToNextRow()) {
                rowText = res.getString(0);
            }
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            res?.close();
        }
        if (rowText === "X") {
            return [];
        } else {
            const items = rowText?.split(";").map((item) => item.trim());
            return items ?? [];
        }
    }
    private static fetchDescriptions(word: string, romanization: string, store: relationalStore.RdbStore): string[] {
        const items: string[] = [];
        const command: string = "SELECT description FROM dictionarytable WHERE word = ? AND romanization = ?;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [word, romanization]);
            while (res.goToNextRow()) {
                const item = res.getString(0);
                items.push(item);
            }
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            res?.close();
        }
        return items;
    }
    private static fetchDefinition(text: string, store: relationalStore.RdbStore): string | undefined {
        let definition: string | undefined = undefined;
        if (text.length != 1) {
            return definition;
        }
        const code = text.codePointAt(0);
        const command: string = `SELECT definition FROM definitiontable WHERE code = ${code} LIMIT 1;`;
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command);
            if (res.goToNextRow()) {
                definition = res.getString(0);
            }
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            res?.close();
        }
        return definition;
    }

    static test(store: relationalStore.RdbStore): number {
        let num: number = -1;
        const command: string = "SELECT rowid FROM jyutpingtable WHERE romanization = 'm4' LIMIT 1;";
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
