export const enum KeyboardCase {
    lowercased = 1,
    uppercased = 2,
    capsLocked = 3,
}

export namespace KeyboardCaseCompanion {
    export function isLowercased(mode: KeyboardCase): boolean {
        return mode === KeyboardCase.lowercased;
    }
    export function isUppercased(mode: KeyboardCase): boolean {
        return mode === KeyboardCase.uppercased;
    }
    export function isCapsLocked(mode: KeyboardCase): boolean {
        return mode === KeyboardCase.capsLocked;
    }

    /** Is not lowercased */
    export function isCapitalized(mode: KeyboardCase): boolean {
        return mode != KeyboardCase.lowercased;
    }
}
