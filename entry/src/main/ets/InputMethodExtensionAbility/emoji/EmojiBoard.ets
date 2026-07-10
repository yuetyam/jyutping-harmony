import controller from "../InputController"
import BackspaceButton from "./BackspaceButton"

@ComponentV2
export default struct EmojiBoard {
    build() {
        Column() {
            Flex() {
                Text('Header')
            }
            .height('32vp')
            Blank().height('calc(100% - 76vp)')
            Flex({ justifyContent: FlexAlign.SpaceBetween }) {
                BackButton()
                BackspaceButton()
            }
            .height('44vp')
        }
        .justifyContent(FlexAlign.Start)
    }
}

@ComponentV2
struct BackButton {
    build() {
        Stack() {
            Text('ABC')
                .padding(2)
        }
        .onClick(() => {
            controller.playModifierSound();
            controller.triggerHapticFeedback();
            controller.transformTo(controller.previousKeyboardForm);
        })
    }
}
