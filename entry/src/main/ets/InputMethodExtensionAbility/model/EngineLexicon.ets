import { Lexicon } from "./Lexicon";
import { LexiconType } from "./LexiconType";

export class EngineLexicon {
    static make(text: string, romanization: string, input: string, number: number = 0, mark?: string): Lexicon {
        return { type: LexiconType.Cantonese, text: text, romanization: romanization, input: input, inputCount: input.length, number: number, mark: mark ?? romanization.replace(/[1-6]/g, "") };
    }

    static distinct(items: Lexicon[]): Lexicon[] {
        const seen: Set<string> = new Set();
        return items.filter((item) => {
            const key = `${item.type}\u0000${item.text}\u0000${item.romanization ?? ""}`;
            if (seen.has(key)) return false;
            seen.add(key);
            return true;
        });
    }

    static compare(a: Lexicon, b: Lexicon): number {
        return b.inputCount - a.inputCount || a.number - b.number;
    }

    static concatenate(a: Lexicon, b: Lexicon): Lexicon {
        return EngineLexicon.make(a.text + b.text, `${a.romanization ?? ""} ${b.romanization ?? ""}`, a.input + b.input, a.number + b.number + 2000000, `${a.mark ?? a.input} ${b.mark ?? b.input}`);
    }
}
