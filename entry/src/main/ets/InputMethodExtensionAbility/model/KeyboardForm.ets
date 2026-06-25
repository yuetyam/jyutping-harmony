export const enum KeyboardForm {

    /** Expanded Candidate page */
    CandidateBoard,

    /** 10-key keypad-style digit keyboard with a symbol sidebar and some other action keys */
    DedicatedNumbers,

    /** 9-key (T9) Stroke keyboard for reverse lookup */
    DedicatedStroke,

    /** Candidate detail page */
    DetailInspecting,

    /** Button page for copy, cut, clear, etc. */
    EditingPanel,

    /** Emoji keyboard */
    EmojiBoard,

    /** KeyboardLayout picking page */
    LayoutPicker,

    /** Numbers and symbols */
    Numeric,

    /** Main keyboard; alphabetic; letters or 9-key (T9) */
    Primary,

    /** Keyboard settings page */
    Settings,

    /** Extra symbols */
    Symbolic,
}

export namespace KeyboardFormCompanion {
    export function isPrimary(form: KeyboardForm): boolean {
        return form === KeyboardForm.Primary;
    }
    export function isDedicatedNumbers(form: KeyboardForm): boolean {
        return form === KeyboardForm.DedicatedNumbers;
    }
    export function isDedicatedStroke(form: KeyboardForm): boolean {
        return form === KeyboardForm.DedicatedStroke;
    }
    export  function isBufferable(form: KeyboardForm): boolean {
        switch (form) {
            case KeyboardForm.Primary: return true
            case KeyboardForm.CandidateBoard: return true
            case KeyboardForm.DedicatedStroke: return true
            case KeyboardForm.DetailInspecting: return true
            default: return false
        }
    }
}
