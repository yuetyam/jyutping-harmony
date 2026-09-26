import controller from '../InputController'
import { KeyboardFormCompanion } from '../model/KeyboardForm';
import { PresetConstant } from '../model/PresetConstant';
import { tailoredShapeSize } from '../model/TailoredShapeSize';

@ComponentV2
export default struct NineKeySpaceKey {
    @Local private isTouching: boolean = false;
    build() {
        Stack() {
            Flex({
                direction: FlexDirection.Column,
                alignItems: ItemAlign.Center,
                justifyContent: FlexAlign.Center
            }) {
                Text(KeyboardFormCompanion.isDedicatedNumbers(controller.keyboardForm) ? "空格" : (controller.isMutilated ? "粤拼" : "粵拼"))
            }
            .backgroundColor(this.isTouching ? $r('app.color.key_emphatic') : $r('app.color.key_shallow'))
            .backgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THIN)
            .borderRadius(PresetConstant.largeKeyCornerRadius)
            .width(tailoredShapeSize(this.isTouching))
            .height(tailoredShapeSize(this.isTouching))
        }
        .width('100%')
        .height('100%')
        .onTouch((event: TouchEvent) => {
            switch (event.type) {
                case TouchType.Down:
                    this.isTouching = true;
                    controller.playInputSound();
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
            controller.space();
        })
    }
}
