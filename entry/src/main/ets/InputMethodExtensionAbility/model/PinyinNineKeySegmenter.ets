import { relationalStore } from "@kit.ArkData";
import { BusinessError } from "@kit.BasicServicesKit";
import { Combo } from "../ninekey/Combo";
import { SegmentationGraph } from "./SegmentationGraph";

export class PinyinNineKeySyllable {
    readonly origin: number[];
    readonly alias: number[];
    constructor(code: number) {
        this.origin = Array.from(code.toString()).map((digit) => Number(digit));
        this.alias = this.origin;
    }
}

export type PinyinNineKeySegmentation = PinyinNineKeySyllable[][];

export class PinyinNineKeySegmenter {
    private static store: relationalStore.RdbStore | undefined;
    private static syllables: Map<number, PinyinNineKeySyllable> = new Map();

    static segment(combos: Combo[], store: relationalStore.RdbStore): PinyinNineKeySegmentation {
        if (PinyinNineKeySegmenter.store !== store) {
            PinyinNineKeySegmenter.syllables = new Map();
            PinyinNineKeySegmenter.store = undefined;
            const syllables: Map<number, PinyinNineKeySyllable> = new Map();
            let result: relationalStore.ResultSet | undefined;
            try {
                result = store.querySqlSync("SELECT DISTINCT code_9key FROM syllable_pinyin_table ORDER BY code_9key;");
                while (result.goToNextRow()) {
                    const code = result.getLong(0);
                    syllables.set(code, new PinyinNineKeySyllable(code));
                }
                PinyinNineKeySegmenter.syllables = syllables;
                PinyinNineKeySegmenter.store = store;
            } catch (error) {
                console.error(`Failed to prepare Pinyin nine-key syllables: ${(error as BusinessError).message}`);
            } finally {
                try {
                    result?.close();
                } catch (error) {
                    console.error(`Failed to close engine result: ${(error as BusinessError).message}`);
                }
            }
        }
        return SegmentationGraph.split(combos.map((combo) => combo.digit), 10, PinyinNineKeySegmenter.syllables);
    }
}
