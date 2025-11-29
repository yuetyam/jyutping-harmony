import controller from "../InputController";
import { CircleShape } from "@kit.ArkUI";
import InputModeSwitch from "./InputModeSwitch";
import { InputModeCompanion } from "../model/InputMode";
import { KeyboardForm } from "../model/KeyboardForm";
import CharacterSetSwitch from "./CharacterSetSwitch";

@ComponentV2
export default struct ToolBar {
    private buttonLength: Length = '48vp';
    private iconLength: Length = '24vp';
    private shapeLength = '44vp';
    private shape = new CircleShape({ width: this.shapeLength, height: this.shapeLength });
    build() {
        Flex({
            direction: FlexDirection.Row,
            alignItems: ItemAlign.Center,
            justifyContent: FlexAlign.SpaceBetween
        }) {
            Stack() {
                Button() {
                    Image($r('app.media.button_settings'))
                        .fillColor($r('sys.color.ohos_id_color_primary'))
                        .width(this.iconLength)
                        .height(this.iconLength)
                }
                .backgroundColor(Color.Transparent)
                .clipShape(this.shape)
                .width(this.shapeLength)
                .height(this.shapeLength)
            }
            .width(this.buttonLength)
            .height('100%')
            .onClick((event: ClickEvent) => {
                controller.playModifierSound();
                controller.transformTo(KeyboardForm.Settings);
            })

            Stack() {
                Button() {
                    Image($r('app.media.button_emoji'))
                        .fillColor($r('sys.color.ohos_id_color_primary'))
                        .width(this.iconLength)
                        .height(this.iconLength)
                }
                .backgroundColor(Color.Transparent)
                .clipShape(this.shape)
                .width(this.shapeLength)
                .height(this.shapeLength)
            }
            .width(this.buttonLength)
            .height('100%')
            .onClick((event: ClickEvent) => {
                controller.playModifierSound();
            })
            .opacity(0)

            Stack() {
                Button() {
                    Image($r('app.media.button_emoji'))
                        .fillColor($r('sys.color.ohos_id_color_primary'))
                        .width(this.iconLength)
                        .height(this.iconLength)
                }
                .backgroundColor(Color.Transparent)
                .clipShape(this.shape)
                .width(this.shapeLength)
                .height(this.shapeLength)
            }
            .width(this.buttonLength)
            .height('100%')
            .onClick((event: ClickEvent) => {
                controller.playModifierSound();
            })
            .opacity(0)

            InputModeSwitch({ isCantoneseMode: InputModeCompanion.isCantonese(controller.inputMode), isMutilated: controller.isMutilated })
                .width('64vp')
                .height('100%')
                .onClick((event: ClickEvent) => {
                    controller.playModifierSound();
                    controller.toggleInputMode();
                })

            Stack() {
                Button() {
                    Image($r('app.media.button_editing'))
                        .fillColor($r('sys.color.ohos_id_color_primary'))
                        .width('28vp')
                        .height('28vp')
                }
                .backgroundColor(Color.Transparent)
                .clipShape(this.shape)
                .width(this.shapeLength)
                .height(this.shapeLength)
            }
            .width(this.buttonLength)
            .height('100%')
            .onClick((event: ClickEvent) => {
                controller.playModifierSound();
                controller.transformTo(KeyboardForm.EditingPanel);
            })

            CharacterSetSwitch({ isMutilated: controller.isMutilated })
                .width(this.buttonLength)
                .height('100%')
                .onClick((event: ClickEvent) => {
                    controller.playModifierSound();
                    controller.toggleCharacterScriptVariant();
                })

            Stack() {
                Button() {
                    Image($r('app.media.button_dismiss_keyboard'))
                        .fillColor($r('sys.color.ohos_id_color_primary'))
                        .width(this.iconLength)
                        .height(this.iconLength)
                }
                .backgroundColor(Color.Transparent)
                .clipShape(this.shape)
                .width(this.shapeLength)
                .height(this.shapeLength)
            }
            .width(this.buttonLength)
            .height('100%')
            .onClick((event: ClickEvent) => {
                controller.playModifierSound();
                controller.dismissKeyboard();
            })
        }
        .width('100%')
        .height('100%')
    }
}
