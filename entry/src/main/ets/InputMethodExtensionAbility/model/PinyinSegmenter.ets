import { SegmentationGraph } from "./SegmentationGraph";
import { relationalStore } from "@kit.ArkData";
import { BusinessError } from "@kit.BasicServicesKit";
import { CharCode } from "./CharCode";
import { VirtualInputKey } from "./VirtualInputKey";

export class PinyinSyllable {
    readonly code: number;
    readonly keys: VirtualInputKey[];
    readonly text: string;

    constructor(code: number, keys: VirtualInputKey[], text: string) {
        this.code = code;
        this.keys = keys;
        this.text = text;
    }
}

export type PinyinScheme = PinyinSyllable[];
export type PinyinSegmentation = PinyinScheme[];

export class PinyinSegmenter {
    private static store: relationalStore.RdbStore | undefined;
    private static syllables: Map<number, PinyinSyllable> = new Map();

    static schemeLength(scheme: PinyinScheme): number {
        return scheme.reduce((total, syllable) => total + syllable.keys.length, 0);
    }

    static schemeMark(scheme: PinyinScheme): string {
        return scheme.map((syllable) => syllable.text).join(" ");
    }

    static segment(keys: VirtualInputKey[], store: relationalStore.RdbStore): PinyinSegmentation {
        if (PinyinSegmenter.store !== store) {
            PinyinSegmenter.syllables = new Map();
            PinyinSegmenter.store = undefined;
            const syllables: Map<number, PinyinSyllable> = new Map();
            let result: relationalStore.ResultSet | undefined;
            try {
                result = store.querySqlSync("SELECT code, syllable FROM syllable_pinyin_table;");
                while (result.goToNextRow()) {
                    const code = result.getLong(0);
                    syllables.set(code, new PinyinSyllable(code, CharCode.matchedInputKeys(code), result.getString(1)));
                }
                PinyinSegmenter.syllables = syllables;
                PinyinSegmenter.store = store;
            } catch (error) {
                console.error(`Failed to prepare Pinyin syllables: ${(error as BusinessError).message}`);
            } finally {
                try {
                    result?.close();
                } catch (error) {
                    console.error(`Failed to close engine result: ${(error as BusinessError).message}`);
                }
            }
        }
        return SegmentationGraph.split(keys.filter((key) => key.isLetter).map((key) => key.code), 100, PinyinSegmenter.syllables);
    }
}
