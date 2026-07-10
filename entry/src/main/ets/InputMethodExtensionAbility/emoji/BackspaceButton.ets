import controller from "../InputController";

@ComponentV2
export default struct BackspaceButton {
    @Local private isTouching: boolean = false;
    @Local private actionCounter: number = 0
    build() {
        Stack() {
            Image(this.isTouching ? $r('app.media.key_backspacing') : $r('app.media.key_backspace'))
                .fillColor($r('sys.color.ohos_id_color_primary'))
                .width('22vp')
                .height('22vp')
                .padding(2)
        }
        .onTouch((event: TouchEvent) => {
            switch (event.type) {
                case TouchType.Down:
                    this.isTouching = true;
                    controller.playDeleteSound();
                    controller.triggerHapticFeedback();
                    break;
                case TouchType.Move:
                    break;
                default:
                    this.isTouching = false;
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
                        controller.playDeleteSound();
                        controller.triggerHapticFeedback();
                        controller.backspace();
                    }
                })
            )
        )
    }
}
