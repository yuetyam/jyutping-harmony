import { relationalStore } from "@kit.ArkData";
import { BusinessError } from "@kit.BasicServicesKit";
import { Emoji } from "./Emoji";
import { EmojiCategory, EmojiCategoryCompanion } from "./EmojiCategory";

export class EmojiDataHelper {
    static fetchDefaultFrequent(store: relationalStore.RdbStore): Emoji[] {
        const command = "SELECT rowid, unicode_version, code_point, cantonese, romanization FROM symbol_table WHERE category = 0 ORDER BY rowid;";
        return EmojiDataHelper.query(store, command, EmojiCategory.Frequent, 50000);
    }

    static fetchSequence(store: relationalStore.RdbStore): Emoji[] {
        const command = "SELECT rowid, category, unicode_version, code_point, cantonese, romanization FROM symbol_table WHERE category > 0 AND category < 9 ORDER BY rowid;";
        const emojis: Emoji[] = [];
        let result: relationalStore.ResultSet | undefined = undefined;
        try {
            result = store.querySqlSync(command);
            while (result.goToNextRow()) {
                const category = EmojiCategoryCompanion.of(result.getLong(1));
                const text = Emoji.fromCodePointText(result.getString(3));
                if (category !== undefined && text !== undefined) {
                    emojis.push(new Emoji(category, 10000 + result.getLong(0), result.getLong(2), text,
                        result.getString(4), result.getString(5)));
                }
            }
        } catch (error) {
            const err = error as BusinessError;
            console.error(`Failed to fetch emoji sequence, message: ${err.message}, code: ${err.code}`);
        } finally {
            EmojiDataHelper.close(result);
        }
        return EmojiDataHelper.distinct(emojis);
    }

    private static query(store: relationalStore.RdbStore, command: string, category: EmojiCategory, identifierOffset: number): Emoji[] {
        const emojis: Emoji[] = [];
        let result: relationalStore.ResultSet | undefined = undefined;
        try {
            result = store.querySqlSync(command);
            while (result.goToNextRow()) {
                const text = Emoji.fromCodePointText(result.getString(2));
                if (text !== undefined) {
                    emojis.push(new Emoji(category, identifierOffset + result.getLong(0), result.getLong(1), text,
                        result.getString(3), result.getString(4)));
                }
            }
        } catch (error) {
            const err = error as BusinessError;
            console.error(`Failed to fetch default emojis, message: ${err.message}, code: ${err.code}`);
        } finally {
            EmojiDataHelper.close(result);
        }
        return emojis;
    }

    private static distinct(emojis: Emoji[]): Emoji[] {
        const texts: string[] = [];
        return emojis.filter((emoji) => {
            const key = `${emoji.category}:${emoji.text}`;
            if (texts.includes(key)) {
                return false;
            }
            texts.push(key);
            return true;
        });
    }

    private static close(result: relationalStore.ResultSet | undefined): void {
        try {
            result?.close();
        } catch (error) {
            const err = error as BusinessError;
            console.error(`Failed to close emoji query, message: ${err.message}, code: ${err.code}`);
        }
    }
}
