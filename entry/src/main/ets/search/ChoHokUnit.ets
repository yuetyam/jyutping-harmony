export interface ChoHokUnit {
    readonly word: string;
    readonly romanization: string;
    readonly pronunciation: string;
    readonly tone: string;
    readonly faancit: string;
    readonly homophones: string[];
}

export interface ChoHokLexicon {
    readonly isEmpty: boolean;
    readonly isNotEmpty: boolean;
    readonly word: string;
    readonly units: ChoHokUnit[];
}
