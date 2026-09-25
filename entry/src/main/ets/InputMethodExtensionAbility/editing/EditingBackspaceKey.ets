import controller from '../InputController';
import { PresetConstant } from '../model/PresetConstant';
import { editingKeySize } from './EditingKeySize';

@ComponentV2
export default struct EditingBackspaceKey {
    @Local private isTouching: boolean = false;
    @Local private actionCounter: number = 0
    build() {
        Stack() {
            Flex({
                direction: FlexDirection.Column,
                alignItems: ItemAlign.Center,
                justifyContent: FlexAlign.Center
            }) {
                Image(this.isTouching ? $r('app.media.key_backspacing') : $r('app.media.key_backspace'))
                    .fillColor($r('sys.color.ohos_id_color_primary'))
                    .width('22vp')
                    .height('22vp')
                Text($r('app.string.keyboard_editing_panel_backspace'))
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
                    controller.playDeleteSound();
                    controller.triggerHapticFeedback();
                    break;
                case TouchType.Move:
                    break;
                default:
                    this.isTouching = false;
                    break;
            }
        })
        .gesture(
            GestureGroup(GestureMode.Parallel,
                TapGesture().onAction((event: GestureEvent) => {
                    controller.backspace();
                    this.actionCounter += 1;
                }),
                LongPressGesture({
                    fingers: 1,
                    repeat: true,
                    duration: 100
                }).onAction((event: GestureEvent) => {
                    if (this.actionCounter < 2) {
                        this.actionCounter += 1;
                    } else {
                        controller.playDeleteSound();
                        controller.triggerHapticFeedback();
                        controller.backspace();
                    }
                })
            )
        )
    }
}
