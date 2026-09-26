import controller from "../InputController";
import { KeyboardForm } from "../model/KeyboardForm";
import { PresetConstant } from "../model/PresetConstant";
import { tailoredShapeSize } from "../model/TailoredShapeSize";

@ComponentV2
export default struct NineKeyNavigateKey {
    @Param @Require @Once destination: KeyboardForm;
    @Local private isTouching: boolean = false;
    private keyText(): string {
        switch (this.destination) {
            case KeyboardForm.Primary: return "ABC";
            case KeyboardForm.DedicatedNumbers: return "123";
            case KeyboardForm.Numeric: return (controller.useDedicatedNumberPad ? "#@$" : "123");
            case KeyboardForm.Symbolic: return "#+=";
            default: return "…";
        }
    }
    build() {
        Stack() {
            Flex({
                direction: FlexDirection.Column,
                alignItems: ItemAlign.Center,
                justifyContent: FlexAlign.Center
            }) {
                Text(this.keyText())
            }
            .backgroundColor(this.isTouching ? $r('app.color.key_shallow') : $r('app.color.key_emphatic'))
            .backgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THIN)
            .borderRadius(PresetConstant.largeKeyCornerRadius)
            .width(tailoredShapeSize(this.isTouching))
            .height(tailoredShapeSize(this.isTouching))
        }
        .width("100%")
        .height("100%")
        .onTouch((event: TouchEvent) => {
            switch (event.type) {
                case TouchType.Down:
                    this.isTouching = true;
                    controller.playModifierSound();
                    controller.triggerHapticFeedback();
                    break;
                case TouchType.Move:
                    break;
                default:
                    this.isTouching = false;
                    break;
            }
        })
        .onClick(() => {
            controller.transformTo(this.destination);
        })
    }
}
