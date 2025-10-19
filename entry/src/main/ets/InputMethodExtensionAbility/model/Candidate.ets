import { CandidateType } from "./CandidateType";
import { Lexicon } from "./Lexicon";

export interface Candidate {
    readonly type: CandidateType;
    readonly text: string;
    readonly comment?: string;
    readonly lexicon: Lexicon;
}
