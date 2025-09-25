import ABCKeyboard from './ABCKeyboard'

@Entry
@Component
struct Index {
    build() {
        Stack() {
            Flex({
                direction: FlexDirection.Column,
                alignItems: ItemAlign.Center,
                justifyContent: FlexAlign.SpaceBetween
            }) {
                ABCKeyboard()
            }
            .width("100%")
            .height("100%")
            .backgroundColor($r('app.color.keyboard_background'))
        }
        .position({ x: 0, y: 0 })
        .zIndex(99999)
    }
}
