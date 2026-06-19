export interface YingWaaUnit {
    readonly word: string;
    readonly romanization: string;
    readonly pronunciation: string;
    readonly note?: string;
    readonly interpretation?: string;
    readonly homophones: string[];
}

export interface YingWaaLexicon {
    readonly isEmpty: boolean;
    readonly isNotEmpty: boolean;
    readonly word: string;
    readonly units: YingWaaUnit[];
}
