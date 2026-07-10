import { CircleShape } from "@kit.ArkUI";
import controller from "../InputController";
import { Emoji } from "./Emoji";
import { EmojiCategory, EmojiCategoryCompanion } from "./EmojiCategory";
import BackspaceButton from "./BackspaceButton";

@ComponentV2
export default struct EmojiBoard {
    @Local private currentCategory: EmojiCategory = EmojiCategory.Frequent;
    private scroller: Scroller = new Scroller();
    private indicatorShape: CircleShape = new CircleShape({ width: "28vp", height: "28vp" });
    build() {
        Column() {
            Row() {
                Text(this.titleFor(this.currentCategory))
                    .fontSize(12)
                    .fontColor($r("sys.color.ohos_id_color_primary"))
                    .padding({ left: 8 })
                Blank()
            }
            .width("100%")
            .height("24vp")
            List({ scroller: this.scroller }) {
                ForEach(this.emojiColumns(), (column: Emoji[]) => {
                    ListItem() {
                        Column() {
                            ForEach(column, (emoji: Emoji) => {
                                Stack() {
                                    Text(emoji.text)
                                        .fontSize(28)
                                        .textAlign(TextAlign.Center)
                                        .width("100%")
                                }
                                .width("100%")
                                .height("20%")
                                .onClick(() => {
                                    controller.playInputSound();
                                    controller.triggerHapticFeedback();
                                    controller.insert(emoji.text);
                                    controller.updateEmojiFrequent(emoji);
                                })
                            }, (emoji: Emoji) => emoji.identifier.toString())
                        }
                        .width("52vp")
                        .height("100%")
                    }
                    .width("52vp")
                    .height("100%")
                }, (column: Emoji[]) => column[0].identifier.toString())
            }
            .listDirection(Axis.Horizontal)
            .scrollBar(BarState.Off)
            .width("100%")
            .height("calc(100% - 68vp)")
            Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
                BackButton().width("100%")
                ForEach(EmojiCategoryCompanion.all(), (category: EmojiCategory) => {
                    Stack() {
                        Button() {
                            Text(EmojiCategoryCompanion.indicator(category)).fontSize(16)
                        }
                        .backgroundColor(this.currentCategory === category ? $r("app.color.key_shallow") : Color.Transparent)
                        .clipShape(this.indicatorShape)
                        .width("28vp")
                        .height("28vp")
                        .onClick(() => {
                            controller.playModifierSound();
                            controller.triggerHapticFeedback();
                            this.currentCategory = category;
                            this.scroller.scrollToIndex(this.startIndexFor(category), false);
                        })
                    }
                    .width("100%")
                    .height("28vp")
                }, (category: EmojiCategory) => category.toString())
                BackspaceButton().width("100%")
            }
            .width("100%")
            .height("44vp")
        }
        .justifyContent(FlexAlign.Start)
        .width("100%")
        .height("100%")
    }

    private startIndexFor(category: EmojiCategory): number {
        return Math.floor(controller.emojiBoardEmojis.findIndex((emoji) => emoji.category === category) / 5);
    }

    private emojiColumns(): Emoji[][] {
        const columns: Emoji[][] = [];
        for (let index = 0; index < controller.emojiBoardEmojis.length; index += 5) {
            columns.push(controller.emojiBoardEmojis.slice(index, index + 5));
        }
        return columns;
    }

    private titleFor(category: EmojiCategory): Resource {
        switch (category) {
            case EmojiCategory.Frequent: return $r("app.string.emoji_board_header_frequently_used");
            case EmojiCategory.SmileysAndPeople: return $r("app.string.emoji_board_header_smileys_and_people");
            case EmojiCategory.AnimalsAndNature: return $r("app.string.emoji_board_header_animals_and_nature");
            case EmojiCategory.FoodAndDrink: return $r("app.string.emoji_board_header_food_and_drink");
            case EmojiCategory.Activity: return $r("app.string.emoji_board_header_activity");
            case EmojiCategory.TravelAndPlaces: return $r("app.string.emoji_board_header_travel_and_places");
            case EmojiCategory.Objects: return $r("app.string.emoji_board_header_objects");
            case EmojiCategory.Symbols: return $r("app.string.emoji_board_header_symbols");
            case EmojiCategory.Flags: return $r("app.string.emoji_board_header_flags");
        }
    }
}

@ComponentV2
struct BackButton {
    build() {
        Stack() {
            Text("ABC")
                .padding(2)
        }
        .onClick(() => {
            controller.playModifierSound();
            controller.triggerHapticFeedback();
            controller.transformTo(controller.previousKeyboardForm);
        })
    }
}
