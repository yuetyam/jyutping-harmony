export const enum NumericLayout {
    Default = 1,
    Dedicated = 2,
}

export namespace NumericLayoutCompanion {

    export function isDefault(layout: NumericLayout): boolean {
        return layout === NumericLayout.Default;
    }

    export function isDedicated(layout: NumericLayout): boolean {
        return layout === NumericLayout.Dedicated;
    }

    export function layoutOf(value: number): NumericLayout {
        switch (value) {
            case NumericLayout.Dedicated:
                return NumericLayout.Dedicated;
            default:
                return NumericLayout.Default;
        }
    }
}
