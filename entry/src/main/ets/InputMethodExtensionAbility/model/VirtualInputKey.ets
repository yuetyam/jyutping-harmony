export class VirtualInputKey {
    /** The text representation of the key. */
    readonly text: string;
    /** A unique identifier code for the key. */
    readonly code: number;

    /**
     * Private constructor to enforce the use of static instances.
     * @param text The text of the key.
     * @param code The unique code of the key.
     */
    private constructor(text: string, code: number) {
        this.text = text;
        this.code = code;
    }

    /**
     * Checks if this key event is equal to another.
     * @param other The other object to compare against.
     * @returns `true` if the objects are the same instance or have the same code, `false` otherwise.
     */
    equals(other: Object | null | undefined): boolean {
        if (this === other) return true;
        if (!(other instanceof VirtualInputKey)) return false;
        return this.code === other.code;
    }

    /**
     * Compares this key event with another for order.
     * @param other The other InputKeyEvent to compare against.
     * @returns A negative number if this code is less than the other's, a positive number if greater, and zero if they are equal.
     */
    compareTo(other: VirtualInputKey): number {
        return this.code - other.code;
    }

    /** Checks if the key is a digit from 0-9. */
    get isNumber(): boolean {
        return VirtualInputKey.digitSet.includes(this);
    }

    /** Checks if the key is a Cantonese tone digit from 1-6. */
    get isToneNumber(): boolean {
        return VirtualInputKey.toneSet.includes(this);
    }

    /** Checks if the key is a letter from a-z. */
    get isLetter(): boolean {
        return VirtualInputKey.alphabetSet.includes(this);
    }

    /** Checks if the key is a letter used for syllables (a-z, excluding tone letters v, x, q). */
    get isSyllableLetter(): boolean {
        return this.isLetter && !this.isToneLetter;
    }

    /** Checks if the key is a tone letter (v, x, or q). */
    get isToneLetter(): boolean {
        return this === VirtualInputKey.letterV || this === VirtualInputKey.letterX || this === VirtualInputKey.letterQ;
    }

    /** Checks if the key represents a tone (letters v, x, q or digits 1-6). */
    get isToneEvent(): boolean {
        return this.isToneLetter || this.isToneNumber;
    }

    /** Checks if the key is a trigger for reverse lookup (r, v, x, or q). */
    get isReverseLookupTrigger(): boolean {
        return this === VirtualInputKey.letterR || this === VirtualInputKey.letterV || this === VirtualInputKey.letterX || this === VirtualInputKey.letterQ;
    }

    /** Checks if the key is an apostrophe (separator/delimiter). */
    get isApostrophe(): boolean {
        return this === VirtualInputKey.apostrophe;
    }

    /** Checks if the key is a grave accent (backtick). */
    get isGrave(): boolean {
        return this === VirtualInputKey.grave;
    }

    /** Returns the integer value of the number key, or `null` if it's not a number key. */
    get digit(): number | null {
        return this.isNumber ? (this.code - 10) : null;
    }

    static matchVirtualKey(value: number): VirtualInputKey | undefined {
        return VirtualInputKey.alphabetSet.find((item) => item.code === value) ?? VirtualInputKey.digitSet.find((item) => item.code === value);
    }

    static readonly number0 = new VirtualInputKey("0", 10);
    static readonly number1 = new VirtualInputKey("1", 11);
    static readonly number2 = new VirtualInputKey("2", 12);
    static readonly number3 = new VirtualInputKey("3", 13);
    static readonly number4 = new VirtualInputKey("4", 14);
    static readonly number5 = new VirtualInputKey("5", 15);
    static readonly number6 = new VirtualInputKey("6", 16);
    static readonly number7 = new VirtualInputKey("7", 17);
    static readonly number8 = new VirtualInputKey("8", 18);
    static readonly number9 = new VirtualInputKey("9", 19);

    static readonly letterA = new VirtualInputKey("a", 20);
    static readonly letterB = new VirtualInputKey("b", 21);
    static readonly letterC = new VirtualInputKey("c", 22);
    static readonly letterD = new VirtualInputKey("d", 23);
    static readonly letterE = new VirtualInputKey("e", 24);
    static readonly letterF = new VirtualInputKey("f", 25);
    static readonly letterG = new VirtualInputKey("g", 26);
    static readonly letterH = new VirtualInputKey("h", 27);
    static readonly letterI = new VirtualInputKey("i", 28);
    static readonly letterJ = new VirtualInputKey("j", 29);
    static readonly letterK = new VirtualInputKey("k", 30);
    static readonly letterL = new VirtualInputKey("l", 31);
    static readonly letterM = new VirtualInputKey("m", 32);
    static readonly letterN = new VirtualInputKey("n", 33);
    static readonly letterO = new VirtualInputKey("o", 34);
    static readonly letterP = new VirtualInputKey("p", 35);
    static readonly letterQ = new VirtualInputKey("q", 36);
    static readonly letterR = new VirtualInputKey("r", 37);
    static readonly letterS = new VirtualInputKey("s", 38);
    static readonly letterT = new VirtualInputKey("t", 39);
    static readonly letterU = new VirtualInputKey("u", 40);
    static readonly letterV = new VirtualInputKey("v", 41);
    static readonly letterW = new VirtualInputKey("w", 42);
    static readonly letterX = new VirtualInputKey("x", 43);
    static readonly letterY = new VirtualInputKey("y", 44);
    static readonly letterZ = new VirtualInputKey("z", 45);

    /** Separator; Delimiter; Quote */
    static readonly apostrophe = new VirtualInputKey("'", 47);

    /** Grave accent; Backtick; Backquote */
    static readonly grave = new VirtualInputKey("`", 48);

    /** Set of digit keys [0-9] */
    static readonly digitSet: VirtualInputKey[] = [
        VirtualInputKey.number0,
        VirtualInputKey.number1,
        VirtualInputKey.number2,
        VirtualInputKey.number3,
        VirtualInputKey.number4,
        VirtualInputKey.number5,
        VirtualInputKey.number6,
        VirtualInputKey.number7,
        VirtualInputKey.number8,
        VirtualInputKey.number9
    ];

    /** Set of Cantonese tone digit keys [1-6] */
    static readonly toneSet: VirtualInputKey[] = [
        VirtualInputKey.number1,
        VirtualInputKey.number2,
        VirtualInputKey.number3,
        VirtualInputKey.number4,
        VirtualInputKey.number5,
        VirtualInputKey.number6
    ];

    /** Set of alphabet letter keys [a-z] */
    static readonly alphabetSet: VirtualInputKey[] = [
        VirtualInputKey.letterA,
        VirtualInputKey.letterB,
        VirtualInputKey.letterC,
        VirtualInputKey.letterD,
        VirtualInputKey.letterE,
        VirtualInputKey.letterF,
        VirtualInputKey.letterG,
        VirtualInputKey.letterH,
        VirtualInputKey.letterI,
        VirtualInputKey.letterJ,
        VirtualInputKey.letterK,
        VirtualInputKey.letterL,
        VirtualInputKey.letterM,
        VirtualInputKey.letterN,
        VirtualInputKey.letterO,
        VirtualInputKey.letterP,
        VirtualInputKey.letterQ,
        VirtualInputKey.letterR,
        VirtualInputKey.letterS,
        VirtualInputKey.letterT,
        VirtualInputKey.letterU,
        VirtualInputKey.letterV,
        VirtualInputKey.letterW,
        VirtualInputKey.letterX,
        VirtualInputKey.letterY,
        VirtualInputKey.letterZ
    ];
}
