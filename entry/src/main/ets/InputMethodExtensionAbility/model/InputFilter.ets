import { CharCode } from "./CharCode";
import { Lexicon } from "./Lexicon";
import { VirtualInputKey } from "./VirtualInputKey";

/** Swift CoreIME's tone and separator qualification, preserving original input counts. */
export class InputFilter {
    static toneConverted(text: string): string {
        return text.replace(/vv/g, "4").replace(/xx/g, "5").replace(/qq/g, "6").replace(/v/g, "1").replace(/x/g, "2").replace(/q/g, "3");
    }

    static replacedInput(item: Lexicon, input: string): Lexicon {
        return { type: item.type, text: item.text, romanization: item.romanization, input: input, inputCount: input.length, number: item.number, mark: item.mark, note: item.note };
    }

    static filter(keys: VirtualInputKey[], items: Lexicon[]): Lexicon[] {
        const separator = keys.some((key) => key.isApostrophe);
        const tone = keys.some((key) => key.isToneLetter || key.isToneNumber);
        if (!separator && !tone) return items;
        const input = CharCode.keysText(keys);
        const text = InputFilter.toneConverted(input);
        if (separator && tone) return items.filter((item) => text.startsWith(item.romanization ?? "")).map((item) => InputFilter.replacedInput(item, input));
        if (tone) {
            const toneInput = CharCode.keysText(keys.filter((key) => !key.isSyllableLetter));
            const textTones = text.replace(/[^1-6]/g, "");
            return items.flatMap((item): Lexicon[] => {
                const syllableText = (item.romanization ?? "").replace(/ /g, "");
                if (syllableText.startsWith(text)) return [InputFilter.replacedInput(item, input)];
                const tones = syllableText.replace(/[^1-6]/g, "");
                const correctPosition = /^[1-6]$/.test(text[item.inputCount] ?? "");
                const toneLast = /[1-6]$/.test(text);
                let consumed: string | undefined;
                if (textTones.length === 1 && tones.length === 1) {
                    if (textTones === tones && correctPosition) consumed = item.input + toneInput;
                } else if (textTones.length === 1 && tones.length === 2) {
                    if (toneLast) {
                        if (tones.endsWith(textTones) && correctPosition) consumed = input;
                    } else if (tones.startsWith(textTones)) consumed = item.input + toneInput;
                } else if (textTones.length === 2 && tones.length === 1) {
                    if (textTones.startsWith(tones) && correctPosition) {
                        let count = 0;
                        while (count < keys.length && keys[count].isSyllableLetter) count++;
                        while (count < keys.length && !keys[count].isSyllableLetter) count++;
                        consumed = input.slice(0, count);
                    }
                } else if (textTones.length === 2 && tones.length === 2) {
                    if (textTones === tones) {
                        if (toneLast && item.inputCount === text.length - 2) consumed = input;
                        if (!toneLast && text[item.inputCount + 1] === textTones[textTones.length - 1]) consumed = item.input + toneInput;
                    }
                } else if (input.startsWith(syllableText)) consumed = syllableText;
                return consumed === undefined ? [] : [InputFilter.replacedInput(item, consumed)];
            }).sort((a, b) => b.inputCount - a.inputCount);
        }
        return InputFilter.separators(keys, items);
    }

    static separators(keys: VirtualInputKey[], items: Lexicon[]): Lexicon[] {
        const input = CharCode.keysText(keys);
        if (input.startsWith("'")) return [];
        const trailing = input.endsWith("'");
        const count = keys.filter((key) => key.isApostrophe).length;
        const parts = input.split("'").filter((part) => part.length > 0);
        return items.flatMap((item): Lexicon[] => {
            const syllables = (item.romanization ?? "").replace(/[1-6]/g, "").split(" ");
            if (syllables.join("\u0000") === parts.join("\u0000")) return [InputFilter.replacedInput(item, input)];
            let consumed: string | undefined;
            if (count === 1 && trailing) {
                if (syllables.length === 1 && item.inputCount === input.length - 1) consumed = input;
            } else if (count === 1) {
                if (syllables.length === 1 && item.inputCount === parts[0]?.length) consumed = item.input + "'";
                if (syllables.length === 2 && (input.length === 3 || syllables[0] === parts[0] || (parts[0]?.length === 1 && parts[0] === syllables[0][0] && (parts[parts.length - 1]?.startsWith(syllables[1]) ?? false)))) consumed = item.input + "'";
            } else if (count === 2 && trailing) {
                if (syllables.length === 1 && item.inputCount === parts[0]?.length) consumed = item.input + "'";
                if (syllables.length === 2 && item.inputCount === input.length - 2 && (input.length === 4 || syllables[0] === parts[0] || (parts[0]?.length === 1 && parts[0] === syllables[0][0] && parts[parts.length - 1] === syllables[1]))) consumed = input;
            } else if (((count === 2 && input.length === 5) || (count === 3 && input.length === 6)) && parts.length === 3) {
                if (syllables.length === 1 && item.inputCount === 1) consumed = item.input + "'";
                if (syllables.length === 2 && item.inputCount === 2) consumed = item.input + "''";
                if (syllables.length === 3) consumed = input;
            } else if (syllables.length < parts.length && syllables.every((syllable, index) => syllable === parts[index])) {
                consumed = item.input + "'".repeat(Math.max(0, syllables.length - 1));
            }
            return consumed === undefined ? [] : [InputFilter.replacedInput(item, consumed)];
        }).sort((a, b) => b.inputCount - a.inputCount);
    }
}
