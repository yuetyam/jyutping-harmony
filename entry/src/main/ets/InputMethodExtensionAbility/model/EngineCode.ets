import { CharCode, DigitCode } from "./CharCode";
import { VirtualInputKey } from "./VirtualInputKey";

/** Exact database codes used by the bundled and learned lexicons. */
export class EngineCode {
    static radix100Overflowed(values: number[]): bigint {
        let result = BigInt(0);
        for (const value of values) {
            result = BigInt.asIntN(64, result * BigInt(100) + BigInt(value));
        }
        return result;
    }

    static decimalOverflowed(values: number[]): bigint {
        let result = BigInt(0);
        for (const value of values) {
            result = BigInt.asIntN(64, result * BigInt(10) + BigInt(value));
        }
        return result;
    }

    static keys(keys: VirtualInputKey[]): string {
        return EngineCode.radix100Overflowed(keys.map((key) => key.code)).toString();
    }

    static text(text: string): string {
        return EngineCode.radix100Overflowed(Array.from(text).map((char) => CharCode.virtualKeyInputCode(char) ?? 0)).toString();
    }

    static combos(combos: DigitCode[]): string {
        return EngineCode.decimalOverflowed(combos.map((combo) => combo.digit)).toString();
    }

    static nineKey(text: string): string {
        return EngineCode.decimalOverflowed(Array.from(text).map((char) => CharCode.nineKeyInterCode(char) ?? 0)).toString();
    }

    static complexity(lengths: number[]): string {
        return EngineCode.decimalOverflowed(lengths).toString();
    }
}
