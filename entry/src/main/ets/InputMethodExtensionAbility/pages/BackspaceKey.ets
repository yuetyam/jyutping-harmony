import controller from '../InputController'

@ComponentV2
export default struct BackspaceKey {
    @Local private isTouching: boolean = false
    @Local private actionCounter: number = 0

    build() {
        Stack() {
            Flex({
                direction: FlexDirection.Column,
                alignItems: ItemAlign.Center,
                justifyContent: FlexAlign.Center
            }) {
                Image(this.isTouching ? $r('app.media.key_backspacing') : $r('app.media.key_backspace'))
                    .fillColor($r('sys.color.ohos_id_color_primary'))
                    .width('22vp')
                    .height('22vp')
            }
            .backgroundColor(this.isTouching ? $r('app.color.key_shallow') : $r('app.color.key_emphatic'))
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
                    controller.playDeleteSound();
                    break;
                case TouchType.Move:
                    break;
                default:
                    this.isTouching = false;
                    this.actionCounter = 0;
                    break;
            }
        })
        .gesture(
            GestureGroup(GestureMode.Parallel,
                TapGesture().onAction((event: GestureEvent) => {
                    controller.backspace();
                    this.actionCounter += 1;
                }),
                LongPressGesture({
                    fingers: 1,
                    repeat: true,
                    duration: 100
                }).onAction((event: GestureEvent) => {
                    if (this.actionCounter < 2) {
                        this.actionCounter += 1;
                    } else {
                        controller.backspace();
                    }
                }),
                SwipeGesture({
                    fingers: 1,
                    direction: SwipeDirection.All,
                    speed: 100
                }).onAction((event: GestureEvent) => {
                    controller.backspace(10);
                })
            )
        )
    }
}
