export const enum LexiconType {

    /** Cantonese word and Jyutping romanization */
    Cantonese = 1,

    /** Plain text. Examples: iPad, macOS */
    Text = 2,

    /** Note that characterCount == 1 not always true */
    Emoji = 3,

    /** Note that characterCount == 1 not always true */
    Symbol = 4,

    /** External keyboard composed text. Mainly for punctuation keys */
    Compose = 5
}
