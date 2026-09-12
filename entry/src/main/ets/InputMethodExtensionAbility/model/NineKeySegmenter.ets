import { relationalStore } from "@kit.ArkData";
import { BusinessError } from "@kit.BasicServicesKit";
import { CharCode } from "./CharCode";
import { Combo } from "../ninekey/Combo";
import { VirtualInputKey } from "./VirtualInputKey";
import { SegmentationGraph } from "./SegmentationGraph";

export class NineKeySyllable {
    alias: number[];
    origin: number[];
    serialOrigin: VirtualInputKey[];
    isIrregular: boolean;
    constructor(alias: number, origin: number, serialOrigin: number) {
        this.alias = Array.from(alias.toString()).map((digit) => Number(digit));
        this.origin = Array.from(origin.toString()).map((digit) => Number(digit));
        this.serialOrigin = CharCode.matchedInputKeys(serialOrigin);
        this.isIrregular = alias !== origin;
    }
}

export type NineKeyScheme = NineKeySyllable[];
export type NineKeySegmentation = NineKeyScheme[];

export class NineKeySegmenter {
    private static store: relationalStore.RdbStore | undefined;
    private static syllables: Map<number, NineKeySyllable> = new Map();

    static segment(combos: Combo[], store: relationalStore.RdbStore): NineKeySegmentation {
        if (NineKeySegmenter.store !== store) {
            NineKeySegmenter.syllables = new Map();
            NineKeySegmenter.store = undefined;
            const syllables: Map<number, NineKeySyllable> = new Map();
            let result: relationalStore.ResultSet | undefined;
            try {
                result = store.querySqlSync("SELECT alias_9key_code, origin_9key_code, origin_code FROM syllable_9key_table ORDER BY rowid;");
                while (result.goToNextRow()) {
                    const alias = result.getLong(0);
                    const syllable = new NineKeySyllable(alias, result.getLong(1), result.getLong(2));
                    const existing = syllables.get(alias);
                    if (existing === undefined || (existing.isIrregular && !syllable.isIrregular)) syllables.set(alias, syllable);
                }
                NineKeySegmenter.syllables = syllables;
                NineKeySegmenter.store = store;
            } catch (error) {
                console.error(`Failed to prepare nine-key syllables: ${(error as BusinessError).message}`);
            } finally {
                try {
                    result?.close();
                } catch (error) {
                    console.error(`Failed to close engine result: ${(error as BusinessError).message}`);
                }
            }
        }
        return SegmentationGraph.split(combos.map((combo) => combo.digit), 10, NineKeySegmenter.syllables);
    }
}
