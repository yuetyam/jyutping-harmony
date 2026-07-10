export enum EmojiCategory {
    Frequent = 0,
    SmileysAndPeople = 1,
    AnimalsAndNature = 2,
    FoodAndDrink = 3,
    Activity = 4,
    TravelAndPlaces = 5,
    Objects = 6,
    Symbols = 7,
    Flags = 8,
}

export namespace EmojiCategoryCompanion {
    const categories: EmojiCategory[] = [
        EmojiCategory.Frequent,
        EmojiCategory.SmileysAndPeople,
        EmojiCategory.AnimalsAndNature,
        EmojiCategory.FoodAndDrink,
        EmojiCategory.Activity,
        EmojiCategory.TravelAndPlaces,
        EmojiCategory.Objects,
        EmojiCategory.Symbols,
        EmojiCategory.Flags,
    ];

    export function all(): EmojiCategory[] {
        return categories;
    }

    export function of(value: number): EmojiCategory | undefined {
        return categories.find((category) => category === value);
    }

    export function indicator(category: EmojiCategory): string {
        switch (category) {
            case EmojiCategory.Frequent: return "🕒";
            case EmojiCategory.SmileysAndPeople: return "😀";
            case EmojiCategory.AnimalsAndNature: return "🐶";
            case EmojiCategory.FoodAndDrink: return "🍏";
            case EmojiCategory.Activity: return "⚽";
            case EmojiCategory.TravelAndPlaces: return "🚘";
            case EmojiCategory.Objects: return "💡";
            case EmojiCategory.Symbols: return "❤️";
            case EmojiCategory.Flags: return "️‍🇺🇳";
        }
    }
}
