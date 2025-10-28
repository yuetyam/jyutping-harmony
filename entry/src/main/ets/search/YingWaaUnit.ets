export interface YingWaaUnit {
    readonly word: string;
    readonly romanization: string;
    readonly pronunciation: string;
    readonly pronunciationMark?: string;
    readonly interpretation?: string;
    readonly homophones: string[];
}

export interface YingWaaLexicon {
    readonly isNotEmpty: boolean;
    readonly word: string;
    readonly units: YingWaaUnit[];
}
