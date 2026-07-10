import { EmojiCategory } from "./EmojiCategory";

export class Emoji {
    readonly category: EmojiCategory;
    readonly identifier: number;
    readonly unicodeVersion: number;
    readonly text: string;
    readonly cantonese: string;
    readonly romanization: string;

    constructor(category: EmojiCategory, identifier: number, unicodeVersion: number, text: string,
        cantonese: string = "", romanization: string = "") {
        this.category = category;
        this.identifier = identifier;
        this.unicodeVersion = unicodeVersion;
        this.text = text;
        this.cantonese = cantonese;
        this.romanization = romanization;
    }

    static frequent(text: string, identifier: number): Emoji {
        return new Emoji(EmojiCategory.Frequent, identifier, 110000, text);
    }

    static fromCodePointText(codePointText: string): string | undefined {
        const codePoints: number[] = [];
        for (const codePoint of codePointText.split(".")) {
            const value = Number.parseInt(codePoint, 16);
            if (Number.isNaN(value)) {
                return undefined;
            }
            codePoints.push(value);
        }
        return codePoints.length > 0 ? String.fromCodePoint(...codePoints) : undefined;
    }

    static codePointText(text: string): string {
        const codePoints: string[] = [];
        for (const character of text) {
            const value = character.codePointAt(0);
            if (value !== undefined) {
                codePoints.push(value.toString(16).toUpperCase());
            }
        }
        return codePoints.join(".");
    }
}
