import inputController from '../model/InputController'

@Component
export default struct EnterKey {
    build() {
        Column() {
            Flex({
                direction: FlexDirection.Column,
                alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center
            }) {
                Text("↵").fontSize(20)
            }
        }
        .backgroundColor(Color.White)
        .width("13%")
        .borderRadius(6)
        .onClick(() => {
            inputController.enterKeyAction();
        })
    }
}
