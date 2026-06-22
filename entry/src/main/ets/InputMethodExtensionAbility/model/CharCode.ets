import { VirtualInputKey } from "./VirtualInputKey";

export interface DigitCode {
    readonly digit: number;
}

export class CharCode {
    // ArkTS number cannot safely carry the longest 64-bit codes used by the Swift build-time tools.
    private static readonly maxRadix100Length: number = 8;
    private static readonly maxDecimalLength: number = 15;

    static charCode(text: string): number | undefined {
        const codes: number[] = [];
        for (const char of text) {
            const code = CharCode.interCode(char);
            if (code === undefined) {
                return undefined;
            }
            codes.push(code);
        }
        if (codes.length < 1) {
            return 0;
        }
        const value = CharCode.radix100Combined(codes);
        return value > 0 ? value : undefined;
    }

    static nineKeyCharCode(text: string): number | undefined {
        const codes: number[] = [];
        for (const char of text) {
            const code = CharCode.nineKeyInterCode(char);
            if (code === undefined) {
                return undefined;
            }
            codes.push(code);
        }
        if (codes.length < 1) {
            return 0;
        }
        const value = CharCode.decimalCombined(codes);
        return value > 0 ? value : undefined;
    }

    static keysText(keys: VirtualInputKey[]): string {
        return keys.map((key) => key.text).join("");
    }

    static keysCode(keys: VirtualInputKey[]): number {
        return CharCode.radix100Combined(keys.map((key) => key.code));
    }

    static anchorsCode(keys: VirtualInputKey[]): number {
        return CharCode.keysCode(keys.map((key) => CharCode.normalizeAnchorKey(key)));
    }

    static comboCode(combos: DigitCode[]): number {
        return CharCode.decimalCombined(combos.map((combo) => combo.digit));
    }

    static radix100Combined(numbers: number[]): number {
        if (numbers.length > CharCode.maxRadix100Length) {
            return 0;
        }
        return numbers.reduce((acc, num) => acc * 100 + num, 0);
    }

    static decimalCombined(numbers: number[]): number {
        if (numbers.length > CharCode.maxDecimalLength) {
            return 0;
        }
        return numbers.reduce((acc, num) => acc * 10 + num, 0);
    }

    static interCode(char: string): number | undefined {
        switch (char) {
            case "a": return 20;
            case "b": return 21;
            case "c": return 22;
            case "d": return 23;
            case "e": return 24;
            case "f": return 25;
            case "g": return 26;
            case "h": return 27;
            case "i": return 28;
            case "j": return 29;
            case "k": return 30;
            case "l": return 31;
            case "m": return 32;
            case "n": return 33;
            case "o": return 34;
            case "p": return 35;
            case "q": return 36;
            case "r": return 37;
            case "s": return 38;
            case "t": return 39;
            case "u": return 40;
            case "v": return 41;
            case "w": return 42;
            case "x": return 43;
            case "y": return 44;
            case "z": return 45;
            default: return undefined;
        }
    }

    static virtualKeyInputCode(char: string): number | undefined {
        return CharCode.interCode(char) ?? CharCode.numberCode(char);
    }

    static nineKeyInterCode(char: string): number | undefined {
        switch (char) {
            case "a":
            case "b":
            case "c":
                return 2;
            case "d":
            case "e":
            case "f":
                return 3;
            case "g":
            case "h":
            case "i":
                return 4;
            case "j":
            case "k":
            case "l":
                return 5;
            case "m":
            case "n":
            case "o":
                return 6;
            case "p":
            case "q":
            case "r":
            case "s":
                return 7;
            case "t":
            case "u":
            case "v":
                return 8;
            case "w":
            case "x":
            case "y":
            case "z":
                return 9;
            default:
                return undefined;
        }
    }

    static normalizeAnchorKey(key: VirtualInputKey): VirtualInputKey {
        return key === VirtualInputKey.letterY ? VirtualInputKey.letterJ : key;
    }

    static matchedInputKeys(value: number): VirtualInputKey[] {
        let num = value;
        const codes: number[] = [];
        while (num > 0) {
            codes.push(num % 100);
            num = Math.floor(num / 100);
        }
        return codes.reverse().map((code) => VirtualInputKey.matchVirtualKey(code)).filter(Boolean) as VirtualInputKey[];
    }

    private static numberCode(char: string): number | undefined {
        switch (char) {
            case "0": return 10;
            case "1": return 11;
            case "2": return 12;
            case "3": return 13;
            case "4": return 14;
            case "5": return 15;
            case "6": return 16;
            case "7": return 17;
            case "8": return 18;
            case "9": return 19;
            default: return undefined;
        }
    }
}
