import { LexiconType } from "./LexiconType";

export interface Lexicon {
    readonly type: LexiconType;
    readonly text: string;
    readonly romanization?: string;
    readonly input: string;
    readonly inputCount: number;
    readonly number: number;
    readonly mark?: string;
    readonly note?: string;
}
