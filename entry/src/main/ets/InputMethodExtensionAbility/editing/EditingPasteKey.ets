import controller from '../InputController';
import { EditingAction } from './EditingAction';

@ComponentV2
export default struct EditingPasteKey {
    @Local private isTouching: boolean = false;
    build() {
        Stack() {
            Flex({
                direction: FlexDirection.Column,
                alignItems: ItemAlign.Center,
                justifyContent: FlexAlign.Center
            }) {
                SymbolGlyph($r('sys.symbol.doc_text_badge_arrow_up'))
                    .fontSize(24)
                    .fontColor([$r('sys.color.ohos_id_color_primary')])
                Text($r('app.string.keyboard_editing_panel_paste'))
                    .fontSize(11)
            }
            .backgroundColor(this.isTouching ? $r('app.color.key_shallow') : $r('app.color.key_emphatic'))
            .borderRadius(8)
            .shadow({
                radius: 1,
                color: Color.Gray,
                offsetY: 1
            })
            .width('calc(100% - 8vp)')
            .height('calc(100% - 8vp)')
        }
        .width('100%')
        .height('100%')
        .onTouch((event: TouchEvent) => {
            switch (event.type) {
                case TouchType.Down:
                    this.isTouching = true;
                    controller.playModifierSound();
                    break;
                case TouchType.Move:
                    break;
                default:
                    this.isTouching = false;
                    break;
            }
        })
        .onClick((event: ClickEvent) => {
            controller.performEditing(EditingAction.Paste);
        })
    }
}
