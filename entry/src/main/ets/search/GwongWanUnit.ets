// 字頭,韻目,小韻,小韻號,小韻內序,反切上字,反切下字,聲母,呼,等,韻系,重紐,聲調,釋義

export interface GwongWanUnit {
    /** 字頭 */
    readonly word: string;

    /** 韻目 */
    readonly rhyme: string;

    /** 小韻 */
    readonly subRhyme: string;

    /** 小韻號 */
    readonly subRhymeSerial: number;

    /** 小韻內字序 */
    readonly subRhymeNumber: number;

    /** 反切上字 */
    readonly upper: string;

    /** 反切下字 */
    readonly lower: string;

    /** 聲母 */
    readonly initial: string;

    /** 呼. 開／合／X */
    readonly rounding: string;

    /** 等. 一二三四X */
    readonly division: string;

    /** 韻系 */
    readonly rhymeClass: string;

    /** 重紐. A / B / X */
    readonly repeating: string;

    /** 聲調. 平上去入 */
    readonly tone: string;

    /** 釋義. Definition. Description. */
    readonly interpretation: string;
}

export interface GwongWanLexicon {
    readonly isEmpty: boolean;
    readonly isNotEmpty: boolean;
    readonly word: string;
    readonly units: GwongWanUnit[];
}
