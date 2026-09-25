import controller from '../InputController';
import { InputModeCompanion } from '../model/InputMode';
import { PresetConstant } from '../model/PresetConstant';
import { editingKeySize } from './EditingKeySize';

@ComponentV2
export default struct EditingSpaceKey {
    @Local private isTouching: boolean = false;
    build() {
        Stack() {
            Flex({
                direction: FlexDirection.Column,
                alignItems: ItemAlign.Center,
                justifyContent: FlexAlign.Center
            }) {
                Text(InputModeCompanion.isCantonese(controller.inputMode) ? '空格' : 'space')
            }
            .backgroundColor(this.isTouching ? $r('app.color.key_shallow') : $r('app.color.key_emphatic'))
            .backgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THIN)
            .borderRadius(PresetConstant.ultraKeyCornerRadius)
            .width(editingKeySize(this.isTouching))
            .height(editingKeySize(this.isTouching))
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
        .onClick((event: ClickEvent) => {
            controller.insert(' ');
        })
    }
}
