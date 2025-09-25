import ABCKeyboard from './ABCKeyboard'

@Entry
@Component
struct Index {
    build() {
        Stack() {
            Flex({
                direction: FlexDirection.Column,
                alignItems: ItemAlign.Center,
                justifyContent: FlexAlign.End
            }) {
                Flex({
                    direction: FlexDirection.Column,
                    alignItems: ItemAlign.Center,
                    justifyContent: FlexAlign.SpaceBetween
                }) {
                    ABCKeyboard()
                }
                .align(Alignment.End)
                .width("100%")
                .height("75%")
            }
            .height("100%")
            .align(Alignment.End)
            .backgroundColor(Color.Gray)
            // .backgroundColor($r('app.color.keyboard_background'))
        }
        .position({ x: 0, y: 0 }).zIndex(99999)
    }
}
