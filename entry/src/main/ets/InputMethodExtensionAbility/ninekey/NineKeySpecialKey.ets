import controller from "../InputController";
import { PresetConstant } from "../model/PresetConstant";
import { Combo } from "./Combo";

@ComponentV2
export default struct NineKeySpecialKey {
    @Local private isTouching: boolean = false;
    build() {
        Stack() {
            Stack() {
                Stack({ alignContent: Alignment.Bottom }) {
                    Stack()
                        .width("100%")
                        .height("100%")
                    Text("反查")
                        .fontSize(10)
                        .opacity(controller.isBuffering ? 0 : 0.35)
                }
                .padding(2)
                Text("R")
                    .fontSize(16)
                    .opacity(controller.isBuffering ? 0 : 1)
            }
            .backgroundColor(this.isTouching ? $r('app.color.key_emphatic') : $r('app.color.key_shallow'))
            .borderRadius(PresetConstant.largeKeyCornerRadius)
            .shadow({
                radius: 1,
                color: Color.Gray,
                offsetY: 1
            })
            .width("calc(100% - 6vp)")
            .height("calc(100% - 6vp)")
        }
        .width("100%")
        .height("100%")
        .onTouch((event: TouchEvent) => {
            switch (event.type) {
                case TouchType.Down:
                    this.isTouching = true;
                    controller.playInputSound();
                    controller.triggerHapticFeedback();
                    break;
                case TouchType.Move:
                    break;
                default:
                    this.isTouching = false;
                    break;
            }
        })
        .onClick(() => {
            if (!controller.isBuffering) {
                controller.handleNineKey(Combo.Special);
            }
        })
    }
}
