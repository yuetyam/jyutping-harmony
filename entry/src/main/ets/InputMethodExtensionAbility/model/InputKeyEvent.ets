/**
 * Input key; Input method processing event
 */
export class InputKeyEvent {
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
        if (!(other instanceof InputKeyEvent)) return false;
        return this.code === other.code;
    }

    /**
     * Compares this key event with another for order.
     * @param other The other InputKeyEvent to compare against.
     * @returns A negative number if this code is less than the other's, a positive number if greater, and zero if they are equal.
     */
    compareTo(other: InputKeyEvent): number {
        return this.code - other.code;
    }

    /** Checks if the key is a digit from 0-9. */
    get isNumber(): boolean {
        return InputKeyEvent.digitSet.has(this);
    }

    /** Checks if the key is a Cantonese tone digit from 1-6. */
    get isToneNumber(): boolean {
        return InputKeyEvent.toneSet.has(this);
    }

    /** Checks if the key is a letter from a-z. */
    get isLetter(): boolean {
        return InputKeyEvent.alphabetSet.has(this);
    }

    /** Checks if the key is a letter used for syllables (a-z, excluding tone letters v, x, q). */
    get isSyllableLetter(): boolean {
        return this.isLetter && !this.isToneLetter;
    }

    /** Checks if the key is a tone letter (v, x, or q). */
    get isToneLetter(): boolean {
        return this === InputKeyEvent.letterV || this === InputKeyEvent.letterX || this === InputKeyEvent.letterQ;
    }

    /** Checks if the key represents a tone (letters v, x, q or digits 1-6). */
    get isToneEvent(): boolean {
        return this.isToneLetter || this.isToneNumber;
    }

    /** Checks if the key is a trigger for reverse lookup (r, v, x, or q). */
    get isReverseLookupTrigger(): boolean {
        return this === InputKeyEvent.letterR || this === InputKeyEvent.letterV || this === InputKeyEvent.letterX || this === InputKeyEvent.letterQ;
    }

    /** Checks if the key is an apostrophe (separator/delimiter). */
    get isApostrophe(): boolean {
        return this === InputKeyEvent.apostrophe;
    }

    /** Checks if the key is a grave accent (backtick). */
    get isGrave(): boolean {
        return this === InputKeyEvent.grave;
    }

    /** Returns the integer value of the number key, or `null` if it's not a number key. */
    get digit(): number | null {
        return this.isNumber ? (this.code - 10) : null;
    }

    static readonly number0 = new InputKeyEvent("0", 10);
    static readonly number1 = new InputKeyEvent("1", 11);
    static readonly number2 = new InputKeyEvent("2", 12);
    static readonly number3 = new InputKeyEvent("3", 13);
    static readonly number4 = new InputKeyEvent("4", 14);
    static readonly number5 = new InputKeyEvent("5", 15);
    static readonly number6 = new InputKeyEvent("6", 16);
    static readonly number7 = new InputKeyEvent("7", 17);
    static readonly number8 = new InputKeyEvent("8", 18);
    static readonly number9 = new InputKeyEvent("9", 19);

    static readonly letterA = new InputKeyEvent("a", 20);
    static readonly letterB = new InputKeyEvent("b", 21);
    static readonly letterC = new InputKeyEvent("c", 22);
    static readonly letterD = new InputKeyEvent("d", 23);
    static readonly letterE = new InputKeyEvent("e", 24);
    static readonly letterF = new InputKeyEvent("f", 25);
    static readonly letterG = new InputKeyEvent("g", 26);
    static readonly letterH = new InputKeyEvent("h", 27);
    static readonly letterI = new InputKeyEvent("i", 28);
    static readonly letterJ = new InputKeyEvent("j", 29);
    static readonly letterK = new InputKeyEvent("k", 30);
    static readonly letterL = new InputKeyEvent("l", 31);
    static readonly letterM = new InputKeyEvent("m", 32);
    static readonly letterN = new InputKeyEvent("n", 33);
    static readonly letterO = new InputKeyEvent("o", 34);
    static readonly letterP = new InputKeyEvent("p", 35);
    static readonly letterQ = new InputKeyEvent("q", 36);
    static readonly letterR = new InputKeyEvent("r", 37);
    static readonly letterS = new InputKeyEvent("s", 38);
    static readonly letterT = new InputKeyEvent("t", 39);
    static readonly letterU = new InputKeyEvent("u", 40);
    static readonly letterV = new InputKeyEvent("v", 41);
    static readonly letterW = new InputKeyEvent("w", 42);
    static readonly letterX = new InputKeyEvent("x", 43);
    static readonly letterY = new InputKeyEvent("y", 44);
    static readonly letterZ = new InputKeyEvent("z", 45);

    /** Separator; Delimiter; Quote */
    static readonly apostrophe = new InputKeyEvent("'", 47);

    /** Grave accent; Backtick; Backquote */
    static readonly grave = new InputKeyEvent("`", 48);

    /** Set of digit keys [0-9] */
    static readonly digitSet: Set<InputKeyEvent> = new Set([
        InputKeyEvent.number0,
        InputKeyEvent.number1,
        InputKeyEvent.number2,
        InputKeyEvent.number3,
        InputKeyEvent.number4,
        InputKeyEvent.number5,
        InputKeyEvent.number6,
        InputKeyEvent.number7,
        InputKeyEvent.number8,
        InputKeyEvent.number9
    ]);

    /** Set of Cantonese tone digit keys [1-6] */
    static readonly toneSet: Set<InputKeyEvent> = new Set([
        InputKeyEvent.number1,
        InputKeyEvent.number2,
        InputKeyEvent.number3,
        InputKeyEvent.number4,
        InputKeyEvent.number5,
        InputKeyEvent.number6
    ]);

    /** Set of alphabet letter keys [a-z] */
    static readonly alphabetSet: Set<InputKeyEvent> = new Set([
        InputKeyEvent.letterA,
        InputKeyEvent.letterB,
        InputKeyEvent.letterC,
        InputKeyEvent.letterD,
        InputKeyEvent.letterE,
        InputKeyEvent.letterF,
        InputKeyEvent.letterG,
        InputKeyEvent.letterH,
        InputKeyEvent.letterI,
        InputKeyEvent.letterJ,
        InputKeyEvent.letterK,
        InputKeyEvent.letterL,
        InputKeyEvent.letterM,
        InputKeyEvent.letterN,
        InputKeyEvent.letterO,
        InputKeyEvent.letterP,
        InputKeyEvent.letterQ,
        InputKeyEvent.letterR,
        InputKeyEvent.letterS,
        InputKeyEvent.letterT,
        InputKeyEvent.letterU,
        InputKeyEvent.letterV,
        InputKeyEvent.letterW,
        InputKeyEvent.letterX,
        InputKeyEvent.letterY,
        InputKeyEvent.letterZ
    ]);
}
