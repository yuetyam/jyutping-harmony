import controller from '../model/InputController'
import { InputMode } from '../model/InputMode';

@ComponentV2
export default struct LeftKey {
    private keyText: string = "，";
    private altKeyText: string = ",";
    build() {
        Stack() {
            Flex({
                direction: FlexDirection.Column,
                alignItems: ItemAlign.Center,
                justifyContent: FlexAlign.Center
            }) {
                Text(controller.inputMode === InputMode.Cantonese ? this.keyText : this.altKeyText)
                    .fontSize(20)
            }
            .backgroundColor($r('app.color.key_shallow'))
            .borderRadius(7)
            .shadow({
                radius: 1,
                color: Color.Gray,
                offsetY: 1
            })
            .width('calc(100% - 6vp)')
            .height('calc(100% - 12vp)')
        }
        .width('100%')
        .height('100%')
        .onClick((event?: ClickEvent) => {
            if (event) {
                let text = controller.inputMode === InputMode.Cantonese ? this.keyText : this.altKeyText;
                controller.insert(text);
            }
        })
    }
}
