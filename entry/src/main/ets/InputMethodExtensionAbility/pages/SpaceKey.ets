import inputController from '../model/InputController'
import { InputMode } from '../model/InputMode'

@Component
export default struct SpaceKey {
    @State private isTouching: boolean = false
    @StorageProp('currentInputMode') private inputMode: InputMode = InputMode.Cantonese
    build() {
        Stack() {
            Flex({
                direction: FlexDirection.Column,
                alignItems: ItemAlign.Center,
                justifyContent: FlexAlign.Center
            }) {
                Text(this.inputMode === InputMode.Cantonese ? "粵拼" : "space")
            }
            .backgroundColor(this.isTouching ? $r('app.color.key_emphatic') : $r('app.color.key_shallow'))
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
        .onTouch((event: TouchEvent) => {
            switch (event.type) {
                case TouchType.Down:
                    this.isTouching = true;
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
                let text: string = " ";
                inputController.insertText(text);
            }
        })
    }
}
