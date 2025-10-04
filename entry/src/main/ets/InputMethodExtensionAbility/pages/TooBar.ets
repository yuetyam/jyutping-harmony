import controller from "../model/InputController";
import { CircleShape } from "@kit.ArkUI";
import InputModeSwitch from "./InputModeSwitch";
import { InputMode } from "../model/InputMode";
import { KeyboardForm } from "../model/KeyboardForm";

@ComponentV2
export default struct ToolBar {
    private buttonLength: Length = '50vp';
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
            .onClick((event?: ClickEvent) => {
                if (event) {
                    controller.playModifierSound();
                    controller.insert("settings");
                }
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
            .onClick((event?: ClickEvent) => {
                if (event) {
                    controller.playModifierSound();
                    controller.insert("emoji");
                }
            })

            InputModeSwitch({ isSwitched: controller.inputMode === InputMode.ABC })
                .width('70vp')
                .height('100%')
                .onClick((event?: ClickEvent) => {
                    if (event) {
                        controller.playModifierSound();
                        let newMode = (controller.inputMode === InputMode.ABC) ? InputMode.Cantonese : InputMode.ABC;
                        controller.updateInputMode(newMode);
                    }
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
            .onClick((event?: ClickEvent) => {
                if (event) {
                    controller.playModifierSound();
                    controller.transformTo(KeyboardForm.EditingPanel);
                }
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
            .onClick((event?: ClickEvent) => {
                if (event) {
                    controller.playModifierSound();
                    controller.dismissKeyboard();
                }
            })
        }
        .width('100%')
        .height('100%')
    }
}
