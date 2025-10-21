export const enum InputMode {
    Cantonese = 1,
    ABC = 2,
}

export namespace InputModeCompanion {
    export function isCantonese(mode: InputMode): boolean {
        return mode === InputMode.Cantonese;
    }
    export function isABC(mode: InputMode): boolean {
        return mode === InputMode.ABC;
    }
}
