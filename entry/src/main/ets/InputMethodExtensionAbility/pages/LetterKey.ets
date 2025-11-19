import controller from '../InputController';
import { InputKeyEvent } from '../model/InputKeyEvent';
import { KeyboardCaseCompanion } from '../model/KeyboardCase';

@ComponentV2
export default struct LetterKey {
    @Param @Require @Once event: InputKeyEvent;
    @Local private isTouching: boolean = false;
    build() {
        Stack() {
            Flex({
                direction: FlexDirection.Column,
                alignItems: ItemAlign.Center,
                justifyContent: FlexAlign.Center
            }) {
                Text(this.event.text)
                    .textCase(KeyboardCaseCompanion.isLowercased(controller.keyboardCase) ? TextCase.Normal : TextCase.UpperCase)
                    .fontSize(22)
            }
            .backgroundColor(this.isTouching ? $r('app.color.key_emphatic') : $r('app.color.key_shallow'))
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
                    controller.playInputSound();
                    break;
                case TouchType.Move:
                    break;
                default:
                    this.isTouching = false;
                    break;
            }
        })
        .onClick((event?: ClickEvent) => {
            if (event) {
                controller.handle(this.event)
            }
        })
    }
}
