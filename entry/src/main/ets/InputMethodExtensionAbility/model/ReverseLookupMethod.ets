import { VirtualInputKey } from "./VirtualInputKey";

export const enum ReverseLookupMethod {

    /** Not performing reverse lookup. Normal typing mode. */
    None,

    /** Mandarin Pinyin */
    Pinyin,

    /** Cangjie or Quick(Sucheng) */
    Cangjie,

    /** Stroke (five-stroke) input; 筆畫 */
    Stroke,

    /** Character decomposition; 拆字 */
    Structure,
}

export namespace ReverseLookupMethodCompanion {

    /** Check for the reverse lookup triggers */
    export function ofKey(key: VirtualInputKey | undefined): ReverseLookupMethod {
        switch (key) {
            case VirtualInputKey.letterR: return ReverseLookupMethod.Pinyin;
            case VirtualInputKey.letterV: return ReverseLookupMethod.Cangjie;
            case VirtualInputKey.letterX: return ReverseLookupMethod.Stroke;
            case VirtualInputKey.letterQ: return ReverseLookupMethod.Structure;
            default: return ReverseLookupMethod.None;
        }
    }

    export function isReverseLookup(method: ReverseLookupMethod): boolean {
        return method !== ReverseLookupMethod.None;
    }
}
