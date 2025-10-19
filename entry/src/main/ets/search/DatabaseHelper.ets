import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { CantoneseLexicon } from './CantoneseLexicon';
import { Pronunciation } from './Pronunciation';

export class DatabaseHelper {
    static search(text: string, store: relationalStore.RdbStore): CantoneseLexicon {
        const romanizations = DatabaseHelper.fetchRomanizations(text, store);
        const pronunciations: Pronunciation[] = romanizations.map( (romanization) => {
            const homophones = DatabaseHelper.fetchHomophones(romanization, store);
            const collocations = DatabaseHelper.fetchCollocations(text, romanization, store);
            const descriptions = DatabaseHelper.fetchDescriptions(text, romanization, store);
            let pronunciation: Pronunciation = {
                romanization: romanization,
                homophones: homophones,
                collocations: collocations,
                descriptions: descriptions
            }
            return pronunciation;
        })
        const definition = DatabaseHelper.fetchDefinition(text, store);
        const lexicon: CantoneseLexicon = {
            text: text,
            pronunciations: pronunciations,
            unihanDefinition: definition
        }
        return lexicon
    }
    static fetchRomanizations(text: string, store: relationalStore.RdbStore): string[] {
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
    static fetchHomophones(romanization: string, store: relationalStore.RdbStore): string[] {
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
    static fetchCollocations(word: string, romanization: string, store: relationalStore.RdbStore): string[] {
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
            const items = rowText?.split(";").map((item) => item.trim())
            return items ?? [];
        }
    }
    static fetchDescriptions(word: string, romanization: string, store: relationalStore.RdbStore): string[] {
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
    static fetchDefinition(text: string, store: relationalStore.RdbStore): string | undefined {
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
}
