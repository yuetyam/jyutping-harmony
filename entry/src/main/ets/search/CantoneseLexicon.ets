import { Pronunciation } from "./Pronunciation";

export interface CantoneseLexicon {
    readonly text: string;
    readonly pronunciations: Pronunciation[];
    readonly unihanDefinition?: string;
    readonly note?: string;
}
