import controller from '../InputController';
import { PresetConstant } from '../model/PresetConstant';
import { EditingAction } from './EditingAction';
import { editingKeySize } from './EditingKeySize';

@ComponentV2
export default struct EditingMoveUpKey {
    @Local private isTouching: boolean = false;
    build() {
        Stack() {
            Flex({
                direction: FlexDirection.Column,
                alignItems: ItemAlign.Center,
                justifyContent: FlexAlign.Center
            }) {
                SymbolGlyph($r('sys.symbol.arrow_up'))
                    .fontSize(22)
                    .fontColor([$r('sys.color.ohos_id_color_primary')])
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
        .onClick((event?: ClickEvent) => {
            if (event) {
                controller.performEditing(EditingAction.MoveUp);
            }
        })
    }
}
