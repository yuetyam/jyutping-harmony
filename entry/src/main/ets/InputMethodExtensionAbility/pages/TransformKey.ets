import controller from '../InputController';
import { KeyboardForm } from '../model/KeyboardForm'

@Component
export default struct TransformKey {
    destination: KeyboardForm | undefined = undefined;
    @State private isTouching: boolean = false;
    private keyText(): string {
        if (this.destination === KeyboardForm.Numeric) {
            return "123";
        } else if (this.destination === KeyboardForm.Symbolic) {
            return "#+="
        } else {
            return "ABC"
        }
    }
    build() {
        Stack() {
            Flex({
                direction: FlexDirection.Column,
                alignItems: ItemAlign.Center,
                justifyContent: FlexAlign.Center
            }) {
                Text(this.keyText())
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
                    controller.triggerHapticFeedback();
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
                let nextForm = this.destination ?? KeyboardForm.Alphabetic;
                controller.transformTo(nextForm);
            }
        })
    }
}
