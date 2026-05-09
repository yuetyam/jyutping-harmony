export class NineKeyCombo {
    readonly text: string;
    readonly digit: string;
    readonly letters: string[];

    private constructor(text: string, digit: string, letters: string[]) {
        this.text = text;
        this.digit = digit;
        this.letters = letters;
    }

    get leadingText(): string {
        return this.letters[0] ?? "";
    }

    get isSpecial(): boolean {
        return this === NineKeyCombo.Special;
    }

    static readonly Special = new NineKeyCombo("R", "1", ["r"]);
    static readonly ABC = new NineKeyCombo("ABC", "2", ["a", "b", "c"]);
    static readonly DEF = new NineKeyCombo("DEF", "3", ["d", "e", "f"]);
    static readonly GHI = new NineKeyCombo("GHI", "4", ["g", "h", "i"]);
    static readonly JKL = new NineKeyCombo("JKL", "5", ["j", "k", "l"]);
    static readonly MNO = new NineKeyCombo("MNO", "6", ["m", "n", "o"]);
    static readonly PQRS = new NineKeyCombo("PQRS", "7", ["p", "s"]);
    static readonly TUV = new NineKeyCombo("TUV", "8", ["t", "u"]);
    static readonly WXYZ = new NineKeyCombo("WXYZ", "9", ["w", "y", "z"]);
}
