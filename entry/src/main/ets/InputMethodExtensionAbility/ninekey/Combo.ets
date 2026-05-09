/** 9-Key (T9) element */
export class Combo {

    /** Key number */
    readonly digit: number;

    /** Key display text */
    readonly text: string;

    /** Jyutping syllable compatible letters */
    readonly letters: string[];

    private constructor(digit: number, text: string, letters: string[]) {
        this.digit = digit;
        this.text = text;
        this.letters = letters;
    }

    get leadingLetter(): string {
        return this.letters[0] ?? "a";
    }

    get isSpecial(): boolean {
        return this === Combo.Special;
    }

    static readonly Special = new Combo(1, "R", ["r"]);
    static readonly ABC = new Combo(2, "ABC", ["a", "b", "c"]);
    static readonly DEF = new Combo(3, "DEF", ["d", "e", "f"]);
    static readonly GHI = new Combo(4, "GHI", ["g", "h", "i"]);
    static readonly JKL = new Combo(5, "JKL", ["j", "k", "l"]);
    static readonly MNO = new Combo(6, "MNO", ["m", "n", "o"]);
    static readonly PQRS = new Combo(7, "PQRS", ["p", "s"]);
    static readonly TUV = new Combo(8, "TUV", ["t", "u"]);
    static readonly WXYZ = new Combo(9, "WXYZ", ["w", "y", "z"]);
}
