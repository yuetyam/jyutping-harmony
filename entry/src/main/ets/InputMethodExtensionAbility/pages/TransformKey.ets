import inputController from '../model/InputController'

@Component
export default struct TransformKey {
    build() {
        Stack() {
            Flex({
                direction: FlexDirection.Column,
                alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center
            }) {
                Text("123")
            }
            .backgroundColor($r('app.color.key_emphatic'))
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
            inputController.enterKeyAction()
        })
    }
}
