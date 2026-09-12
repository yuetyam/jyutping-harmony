import { relationalStore } from "@kit.ArkData";
import { BusinessError } from "@kit.BasicServicesKit";
import { EngineLexicon } from "./EngineLexicon";
import { Lexicon } from "./Lexicon";

export class Lookup {
    static reverse(text: string, input: string, store: relationalStore.RdbStore, mark: string = input): Lexicon[] {
        return Lookup.romanizations(text, store).map((romanization) => EngineLexicon.make(text, romanization, input, 0, mark));
    }

    static romanizations(text: string, store: relationalStore.RdbStore): string[] {
        if (text.length === 0) return [];
        const matched = Lookup.match(text, store);
        if (matched.length > 0) return matched;
        let remaining = Array.from(text);
        if (remaining.length === 1) return [];
        const parts: string[] = [];
        while (remaining.length > 0) {
            let consumed = remaining.length;
            let reading: string | undefined;
            while (consumed > 0) {
                reading = Lookup.match(remaining.slice(0, consumed).join(""), store)[0];
                if (reading !== undefined) break;
                consumed--;
            }
            if (reading === undefined) return [];
            parts.push(reading);
            remaining = remaining.slice(consumed);
        }
        return [parts.join(" ")];
    }

    private static match(text: string, store: relationalStore.RdbStore): string[] {
        const items: string[] = [];
        let result: relationalStore.ResultSet | undefined;
        try {
            result = store.querySqlSync("SELECT romanization FROM lexicon_core WHERE word = ? ORDER BY rowid;", [text]);
            while (result.goToNextRow()) items.push(result.getString(0));
        } catch (error) {
            console.error(`Romanization lookup failed: ${(error as BusinessError).message}`);
        } finally {
            try {
                result?.close();
            } catch (error) {
                console.error(`Failed to close engine result: ${(error as BusinessError).message}`);
            }
        }
        return items;
    }
}
