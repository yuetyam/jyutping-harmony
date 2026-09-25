import controller from '../InputController';
import { InputModeCompanion } from '../model/InputMode';
import { PresetConstant } from '../model/PresetConstant';
import { editingKeySize } from './EditingKeySize';

@ComponentV2
export default struct EditingEnterKey {
    @Local private isTouching: boolean = false;
    build() {
        Stack() {
            Flex({
                direction: FlexDirection.Column,
                alignItems: ItemAlign.Center,
                justifyContent: FlexAlign.Center
            }) {
                Image($r('app.media.key_return'))
                    .fillColor($r('sys.color.ohos_id_color_primary'))
                    .width('20vp')
                    .height('20vp')
                Text(InputModeCompanion.isCantonese(controller.inputMode) ? '回車' : 'return')
                    .fontSize(11)
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
        .onClick((event: ClickEvent) => {
            controller.enterKeyAction();
        })
    }
}
