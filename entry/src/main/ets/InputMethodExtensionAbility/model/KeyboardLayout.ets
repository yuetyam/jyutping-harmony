export const enum KeyboardLayout {
    Qwerty = 1,
    // TripleStroke = 2,
    NineKey = 3,
}

export namespace KeyboardLayoutCompanion {
    export function isQwerty(layout: KeyboardLayout): boolean {
        return layout === KeyboardLayout.Qwerty;
    }

    export function isNineKey(layout: KeyboardLayout): boolean {
        return layout === KeyboardLayout.NineKey;
    }

    export function layoutOf(value: number): KeyboardLayout {
        switch (value) {
            case KeyboardLayout.NineKey:
                return KeyboardLayout.NineKey;
            default:
                return KeyboardLayout.Qwerty;
        }
    }
}
