import { relationalStore } from "@kit.ArkData";
import { BusinessError } from "@kit.BasicServicesKit";
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
    static schemeLength(scheme: PinyinScheme): number {
        return scheme.reduce((acc, syllable) => acc + syllable.keys.length, 0);
    }

    static schemeMark(scheme: PinyinScheme): string {
        return scheme.map((syllable) => syllable.text).join(" ");
    }

    static segment(keys: VirtualInputKey[], store: relationalStore.RdbStore): PinyinSegmentation {
        const letters = keys.filter((key) => key.isLetter);
        if (letters.length < 1) {
            return [];
        }
        return PinyinSegmenter.split(letters, store);
    }

    private static split(keys: VirtualInputKey[], store: relationalStore.RdbStore): PinyinSegmentation {
        const headSyllables = PinyinSegmenter.splitLeading(keys, store);
        if (headSyllables.length < 1) {
            return [];
        }
        const inputLength = keys.length;
        const segmentation: PinyinSegmentation = [];
        const handled: string[] = [];
        let pending: PinyinScheme[] = headSyllables.map((syllable) => [syllable]);
        while (pending.length > 0) {
            const nextPending: PinyinScheme[] = [];
            for (const scheme of pending) {
                const key = PinyinSegmenter.schemeKey(scheme);
                if (!handled.includes(key)) {
                    handled.push(key);
                    segmentation.push(scheme);
                }
                const handledLength = PinyinSegmenter.schemeLength(scheme);
                if (handledLength >= inputLength) {
                    continue;
                }
                const tailKeys = keys.slice(handledLength);
                const tailSyllables = PinyinSegmenter.splitLeading(tailKeys, store);
                for (const syllable of tailSyllables) {
                    nextPending.push([...scheme, syllable]);
                }
            }
            pending = nextPending;
        }
        return segmentation.sort((lhs, rhs) => {
            const lhsLength = PinyinSegmenter.schemeLength(lhs);
            const rhsLength = PinyinSegmenter.schemeLength(rhs);
            return (lhsLength === rhsLength) ? (lhs.length - rhs.length) : (rhsLength - lhsLength);
        });
    }

    private static splitLeading(keys: VirtualInputKey[], store: relationalStore.RdbStore): PinyinSyllable[] {
        const maxLength = Math.min(keys.length, 6);
        if (maxLength < 1) {
            return [];
        }
        const syllables: PinyinSyllable[] = [];
        for (let length = maxLength; length >= 1; length--) {
            const leadingKeys = keys.slice(0, length);
            const code = leadingKeys.reduce((acc, key) => acc * 100 + key.code, 0);
            const text = PinyinSegmenter.match(code, store);
            if (text === undefined) {
                continue;
            }
            syllables.push(new PinyinSyllable(code, leadingKeys, text));
        }
        return syllables;
    }

    private static match(code: number, store: relationalStore.RdbStore): string | undefined {
        const command = "SELECT syllable FROM pinyin_syllable_table WHERE code = ? LIMIT 1;";
        let res: relationalStore.ResultSet | undefined = undefined;
        try {
            res = store.querySqlSync(command, [code]);
            if (res.goToNextRow()) {
                return res.getString(0);
            }
        } catch (error) {
            const err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            res?.close();
        }
        return undefined;
    }

    private static schemeKey(scheme: PinyinScheme): string {
        return scheme.map((syllable) => syllable.code.toString()).join("-");
    }
}
