import inputController from '../model/InputController'

@Component
export default struct BackspaceKey {
    build() {
        Stack() {
            Flex({
                direction: FlexDirection.Column,
                alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center
            }) {
                SymbolGlyph($r('sys.symbol.delete_left'))
                    .fontSize(24)
                    .fontColor([$r('sys.color.ohos_id_color_text_primary')])
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
            inputController.deleteForward(1);
        })
    }
}
