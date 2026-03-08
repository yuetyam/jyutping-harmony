import { BusinessError } from '@kit.BasicServicesKit';
import { relationalStore } from "@kit.ArkData";
import { VirtualInputKey } from "./VirtualInputKey";

export class Syllable {
    readonly aliasCode: number;
    readonly originCode: number;
    readonly alias: VirtualInputKey[];
    readonly origin: VirtualInputKey[];
    constructor(aliasCode: number, originCode: number) {
        this.aliasCode = aliasCode;
        this.originCode = originCode;
        this.alias = this.matchedInputKeys(aliasCode);
        this.origin = this.matchedInputKeys(originCode);
    }
    equals(other: Object | null | undefined): boolean {
        if (this === other) return true;
        if (!(other instanceof Syllable)) return false;
        return this.aliasCode === other.aliasCode && this.originCode === other.originCode;
    }
    private matchedInputKeys(value: number): VirtualInputKey[] {
        let num = value;
        const codes: number[] = [];
        while (num > 0) {
            codes.push(num % 100);
            num = Math.floor(num / 100);
        }
        return codes.reverse().map((code) => VirtualInputKey.matchVirtualKey(code)).filter(Boolean) as VirtualInputKey[];
    }
}

export type Scheme = Syllable[];
export type Segmentation = Scheme[];

export class Segmenter {
    private static match(code: number, store: relationalStore.RdbStore): number | undefined {
        const command: string = `SELECT origin_code FROM syllable_table WHERE alias_code = ${code} LIMIT 1;`;
        let res: relationalStore.ResultSet | undefined = undefined;
        let originCode: number | undefined = undefined;
        try {
            res = store.querySqlSync(command);
            if (res.goToNextRow()) {
                originCode = res.getLong(0);
            }
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            res?.close();
        }
        return originCode;
    }
    private static splitLeading(keys: VirtualInputKey[], store: relationalStore.RdbStore): Syllable[] {
        const maxLength = Math.min(keys.length, 6);
        if (maxLength === 0) {
            return [];
        }
        const syllables: Syllable[] = [];
        for (let num = maxLength; num >= 1; num--) {
            const code = keys.slice(0, num).reduce((acc, event) => acc * 100 + event.code, 0);
            const originCode: number = Segmenter.match(code, store) ?? 0;
            if (originCode > 0) {
                const syllable = new Syllable(code, originCode);
                syllables.push(syllable);
            }
        }
        return syllables;
    }
    private static split(keys: VirtualInputKey[], store: relationalStore.RdbStore): Segmentation {
        const headSyllables = Segmenter.splitLeading(keys, store);
        if (headSyllables.length === 0) {
            return [];
        }
        const inputLength = keys.length;
        const segmentation: Segmentation = [];
        let pending: Scheme[] = headSyllables.map((syllable) => [syllable]);
        while (pending.length > 0) {
            const nextPending: Scheme[] = [];
            for (const scheme of pending) {
                segmentation.push(scheme);
                const handledLength = scheme.reduce((acc, syllable) => acc + syllable.alias.length, 0);
                if (handledLength >= inputLength) {
                    continue;
                }
                const tailKeys = keys.slice(handledLength);
                const tailSyllables = Segmenter.splitLeading(tailKeys, store);
                for (const syllable of tailSyllables) {
                    nextPending.push([...scheme, syllable]);
                }
            }
            pending = nextPending;
        }
        return segmentation
            .filter((scheme) => Segmenter.valid(scheme))
            .sort((lhs, rhs) => {
                const lhsKeyCount = lhs.map((syllable) => syllable.alias.length).reduce((acc, i) => acc + i, 0);
                const rhsKeyCount = rhs.map((syllable) => syllable.alias.length).reduce((acc, i) => acc + i, 0);
                return (lhsKeyCount === rhsKeyCount) ? (lhs.length - rhs.length) : (rhsKeyCount - lhsKeyCount);
            });
    }
    static segment(keys: VirtualInputKey[], store: relationalStore.RdbStore): Segmentation {
        switch (keys.length) {
            case 0: return [];
            case 1:
                switch (keys[0]) {
                    case VirtualInputKey.letterA: return Segmenter.letterA;
                    case VirtualInputKey.letterO: return Segmenter.letterO;
                    case VirtualInputKey.letterM: return Segmenter.letterM;
                    default: return [];
                }
            case 4:
                const combinedCode = keys.reduce((acc, key) => acc * 100 + key.code, 0);
                switch (combinedCode) {
                    case 32203220: return Segmenter.mama;
                    case 32203228: return Segmenter.mami;
                    default: return Segmenter.split(keys, store);
                }
            default:
                return Segmenter.split(keys, store);
        }
    }
    private static readonly letterA: Segmentation = [[new Syllable(20, 2020)]];
    private static readonly letterO: Segmentation = [[new Syllable(34, 34)]];
    private static readonly letterM: Segmentation = [[new Syllable(32, 32)]];
    private static readonly mama: Segmentation = [[
        new Syllable(3220, 322020),
        new Syllable(3220, 322020)
    ]];
    private static readonly mami: Segmentation = [[
        new Syllable(3220, 322020),
        new Syllable(3228, 3228)
    ]];
    private static valid(scheme: Scheme): boolean {
        switch (scheme.length) {
            case 0: return false;
            case 1: return true;
            default: break;
        }
        const tailLetterA = scheme.slice(0, -2).find((syllable) => syllable.origin[syllable.origin.length - 1] === VirtualInputKey.letterA)
        if (tailLetterA == undefined) { return true; }
        const originText = scheme.flatMap((syllable) => syllable.origin).map((key) => key.text).join("");
        const originNumber = originText.match("am(m|ng)")?.length ?? 0;
        if (originNumber === 0) { return true; }
        const aliasText = scheme.flatMap((syllable) => syllable.alias).map((key) => key.text).join("");
        const aliasNumber = aliasText.match("am(m|ng)")?.length ?? 0;
        if (aliasNumber === 0) { return false; }
        return originNumber === aliasNumber;
    }
}
