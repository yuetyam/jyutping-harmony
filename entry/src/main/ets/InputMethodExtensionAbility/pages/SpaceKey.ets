import inputController from '../model/InputController'

@Component
export default struct SpaceKey {
    @State private isTouching: boolean = false
    build() {
        Stack() {
            Flex({
                direction: FlexDirection.Column,
                alignItems: ItemAlign.Center,
                justifyContent: FlexAlign.Center
            }) {
                Text("粵拼")
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
            let text: string = " ";
            inputController.insertText(text);
        })
    }
}
