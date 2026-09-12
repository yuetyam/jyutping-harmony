import { SegmentationGraph } from "./SegmentationGraph";
import { BusinessError } from "@kit.BasicServicesKit";
import { relationalStore } from "@kit.ArkData";
import { CharCode } from "./CharCode";
import { VirtualInputKey } from "./VirtualInputKey";

export class Syllable {
    readonly aliasCode: number;
    readonly originCode: number;
    readonly alias: VirtualInputKey[];
    readonly origin: VirtualInputKey[];
    constructor(aliasCode: number, originCode: number) {
        this.aliasCode = aliasCode;
        this.originCode = originCode;
        this.alias = CharCode.matchedInputKeys(aliasCode);
        this.origin = CharCode.matchedInputKeys(originCode);
    }
    equals(other: Object | null | undefined): boolean {
        if (this === other) return true;
        if (!(other instanceof Syllable)) return false;
        return this.aliasCode === other.aliasCode && this.originCode === other.originCode;
    }
}

export type Scheme = Syllable[];
export type Segmentation = Scheme[];

export class Segmenter {
    private static store: relationalStore.RdbStore | undefined;
    private static syllables: Map<number, Syllable> = new Map();

    private static prepare(store: relationalStore.RdbStore): void {
        if (Segmenter.store === store) return;
        Segmenter.syllables = new Map();
        Segmenter.store = undefined;
        const syllables: Map<number, Syllable> = new Map();
        let result: relationalStore.ResultSet | undefined;
        try {
            result = store.querySqlSync("SELECT alias_code, origin_code FROM syllable_core_table;");
            while (result.goToNextRow()) {
                const alias = result.getLong(0);
                syllables.set(alias, new Syllable(alias, result.getLong(1)));
            }
            Segmenter.syllables = syllables;
            Segmenter.store = store;
        } catch (error) {
            console.error(`Failed to prepare Cantonese syllables: ${(error as BusinessError).message}`);
        } finally {
            try {
                result?.close();
            } catch (error) {
                console.error(`Failed to close engine result: ${(error as BusinessError).message}`);
            }
        }
    }

    static syllableText(keys: VirtualInputKey[], store: relationalStore.RdbStore): string | undefined {
        if (keys.length > 6) return undefined;
        Segmenter.prepare(store);
        const syllable = Segmenter.syllables.get(CharCode.keysCode(keys));
        return syllable === undefined ? undefined : CharCode.keysText(syllable.origin);
    }

    static segment(keys: VirtualInputKey[], store: relationalStore.RdbStore): Segmentation {
        Segmenter.prepare(store);
        const letters = keys.filter((key) => key.isSyllableLetter);
        if (keys.length === 1) {
            switch (letters[0]) {
                case VirtualInputKey.letterA: return [[new Syllable(20, 2020)]];
                case VirtualInputKey.letterO: return [[new Syllable(34, 34)]];
                case VirtualInputKey.letterM: return [[new Syllable(32, 32)]];
                default: return [];
            }
        }
        return SegmentationGraph.split(letters.map((key) => key.code), 100, Segmenter.syllables);
    }
}
