import controller from '../InputController'
import { PresetConstant } from '../model/PresetConstant'
import { tailoredShapeSize } from '../model/TailoredShapeSize'

@ComponentV2
export default struct NineKeyEnterKey {
    @Local private isTouching: boolean = false
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
            }
            .backgroundColor(this.isTouching ? $r('app.color.key_shallow') : $r('app.color.key_emphatic'))
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
            controller.enterKeyAction();
        })
    }
}
