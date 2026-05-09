import { CircleShape } from "@kit.ArkUI";
import { KeyboardLayout, KeyboardLayoutCompanion } from "../model/KeyboardLayout";
import controller from "../InputController"

@ComponentV2
export default struct KeyboardLayoutPickerView {
    private shapeSize = '44vp';
    private shape = new CircleShape({ width: this.shapeSize, height: this.shapeSize });
    build() {
        Column({ space: 8 }) {
            Row() {
                Stack() {
                    Button() {
                        SymbolGlyph($r('sys.symbol.chevron_up'))
                            .fontSize(32)
                            .fontColor([$r('sys.color.ohos_id_color_primary')])
                    }
                    .backgroundColor($r('app.color.key_shallow'))
                    .clipShape(this.shape)
                    .width(this.shapeSize)
                    .height(this.shapeSize)
                }
                .width('50vp')
                .height('100%')
                .onClick(() => {
                    controller.playModifierSound();
                    controller.triggerHapticFeedback();
                    controller.transformTo(controller.previousKeyboardForm);
                })
                Blank()
            }
            .width('100%')
            .height('50vp')
            Flex({
                direction: FlexDirection.Row,
                alignItems: ItemAlign.Center,
                justifyContent: FlexAlign.SpaceEvenly
            }) {
                LayoutOptionView({ layout: KeyboardLayout.Qwerty })
                LayoutOptionView({ layout: KeyboardLayout.Qwerty }).opacity(0)
                LayoutOptionView({ layout: KeyboardLayout.NineKey })
                LayoutOptionView({ layout: KeyboardLayout.NineKey }).opacity(0)
            }
        }
    }
}

@ComponentV2
struct LayoutOptionView {
    @Param @Require @Once layout: KeyboardLayout;
    private isNineKey: boolean = KeyboardLayoutCompanion.isNineKey(this.layout);
    private buttonSize = '50vp';
    private shapeSize = '44vp';
    private iconSize = '30vp';
    private shape = new CircleShape({ width: this.shapeSize, height: this.shapeSize });
    build() {
        Column({ space: 2 }) {
            Button() {
                Image($r('app.media.button_show_keyboard'))
                    .fillColor(controller.keyboardLayout === this.layout ? $r('app.color.accent') : $r('sys.color.ohos_id_color_primary'))
                    .width(this.iconSize)
                    .height(this.iconSize)
            }
            .backgroundColor($r('app.color.key_shallow'))
            .clipShape(this.shape)
            .width(this.shapeSize)
            .height(this.shapeSize)
            Text(this.isNineKey ? $r('app.string.keyboard_settings_layout_t9') : $r('app.string.keyboard_settings_layout_qwerty'))
                .fontSize(13)
        }
        .width(this.buttonSize)
        .height(this.buttonSize)
        .onClick(() => {
            controller.playModifierSound();
            controller.triggerHapticFeedback();
            controller.updateKeyboardLayout(this.layout);
        })
    }
}
