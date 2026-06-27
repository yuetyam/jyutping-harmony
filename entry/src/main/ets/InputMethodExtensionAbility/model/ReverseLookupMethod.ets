import { VirtualInputKey } from "./VirtualInputKey";

export const enum ReverseLookupMethod {
    None,
    Pinyin,
    Cangjie,
    Stroke,
    Structure,
}

export namespace ReverseLookupMethodCompanion {
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
