import controller from '../InputController';

@ComponentV2
export default struct EditingRightDeleteKey {
    @Local private isTouching: boolean = false;
    @Local private actionCounter: number = 0
    build() {
        Stack() {
            Flex({
                direction: FlexDirection.Column,
                alignItems: ItemAlign.Center,
                justifyContent: FlexAlign.Center
            }) {
                Image(this.isTouching ? $r('app.media.key_forward_deleting') : $r('app.media.key_forward_delete'))
                    .fillColor($r('sys.color.ohos_id_color_primary'))
                    .width('22vp')
                    .height('22vp')
                Text($r('app.string.keyboard_editing_panel_right_delete'))
                    .fontSize(11)
            }
            .backgroundColor(this.isTouching ? $r('app.color.key_shallow') : $r('app.color.key_emphatic'))
            .borderRadius(8)
            .shadow({
                radius: 1,
                color: Color.Gray,
                offsetY: 1
            })
            .width('calc(100% - 8vp)')
            .height('calc(100% - 8vp)')
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
                    break;
            }
        })
        .gesture(
            GestureGroup(GestureMode.Parallel,
                TapGesture().onAction((event: GestureEvent) => {
                    controller.rightDelete();
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
                        controller.rightDelete();
                    }
                })
            )
        )
    }
}
