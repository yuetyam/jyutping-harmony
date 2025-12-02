import controller from '../InputController';
import { KeyboardCase } from '../model/KeyboardCase';

@ComponentV2
export default struct ShiftKey {
    @Local private isTouching: boolean = false;
    @Local private timeBuffer: number = 0;
    @Local private intervalID: number = -1;
    build() {
        Stack() {
            Flex({
                direction: FlexDirection.Column,
                alignItems: ItemAlign.Center,
                justifyContent: FlexAlign.Center
            }) {
                Image(this.image(controller.keyboardCase))
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
                    controller.playModifierSound();
                    break;
                case TouchType.Move:
                    break;
                default:
                    this.isTouching = false;
                    break;
            }
        })
        .onClick(() => {
            clearInterval(this.intervalID);
            const isDoubleTapping: boolean = (this.timeBuffer > 0 && this.timeBuffer < 4);
            this.timeBuffer = 0;
            if (isDoubleTapping) {
                controller.doubleShift();
            } else {
                controller.shift();
                this.intervalID = setInterval(() => {
                    this.timeBuffer += 1;
                    if (this.timeBuffer > 4) {
                        clearInterval(this.intervalID);
                    }
                }, 100);
            }
        })
    }
    private image(keyboardCase: KeyboardCase): Resource {
        switch (keyboardCase) {
            case KeyboardCase.lowercased:
                return $r('app.media.key_shift');
            case KeyboardCase.uppercased:
                return $r('app.media.key_shifting');
            case KeyboardCase.capsLocked:
                return $r('app.media.key_capslock');
        }
    }
}
