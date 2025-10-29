export interface FanWanUnit {
    readonly word: string;
    readonly romanization: string;
    readonly initial: string;
    readonly final: string;
    readonly yamyeung: string;
    readonly tone: string;
    readonly rhyme: string;
    readonly interpretation: string;
    readonly homophones: string[];
}

export interface FanWanLexicon {
    readonly isEmpty: boolean;
    readonly isNotEmpty: boolean;
    readonly word: string;
    readonly units: FanWanUnit[];
}
