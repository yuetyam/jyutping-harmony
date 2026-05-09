@ComponentV2
export default struct NineKeyPlaceholderView {
    build() {
        Stack() {
            Flex({
                direction: FlexDirection.Column,
                alignItems: ItemAlign.Center,
                justifyContent: FlexAlign.Center
            }) {
            }
            .backgroundColor($r('app.color.key_shallow'))
            .opacity(0.8)
            .borderRadius(7)
            .shadow({
                radius: 1,
                color: Color.Gray,
                offsetY: 1
            })
            .width("calc(100% - 6vp)")
            .height("calc(100% - 6vp)")
        }
        .width('100%')
        .height('100%')
    }
}
