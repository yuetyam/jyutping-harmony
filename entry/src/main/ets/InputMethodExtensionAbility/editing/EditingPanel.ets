import controller from '../InputController';
import EditingBackKey from './EditingBackKey';
import EditingBackspaceKey from './EditingBackspaceKey';
import EditingClearKey from './EditingClearKey';
import EditingClipboardClearKey from './EditingClipboardClearKey';
import EditingConversionKey from './EditingConversionKey';
import EditingCopyKey from './EditingCopyKey';
import EditingCutKey from './EditingCutKey';
import EditingEnterKey from './EditingEnterKey';
import EditingJumpEndKey from './EditingJumpEndKey';
import EditingJumpStartKey from './EditingJumpStartKey';
import EditingMoveDownKey from './EditingMoveDownKey';
import EditingMoveLeftKey from './EditingMoveLeftKey';
import EditingMoveRightKey from './EditingMoveRight';
import EditingMoveUpKey from './EditingMoveUp';
import EditingPasteKey from './EditingPasteKey';
import EditingRightDeleteKey from './EditingRightDeleteKey';
import EditingSpaceKey from './EditingSpaceKey';

@ComponentV2
export default struct EditingPanel {
    private keyHeight: Length = (controller.keyboardHeight as number) / 4.0
    build() {
        Flex({
            direction: FlexDirection.Row,
            alignItems: ItemAlign.Center,
            justifyContent: FlexAlign.SpaceEvenly
        }) {
            Flex({
                direction: FlexDirection.Column,
                alignItems: ItemAlign.Center,
                justifyContent: FlexAlign.SpaceEvenly
            }) {
                EditingCopyKey()
                    .width('100%')
                    .height(this.keyHeight)
                EditingCutKey()
                    .width('100%')
                    .height(this.keyHeight)
                EditingClearKey()
                    .width('100%')
                    .height(this.keyHeight)
                EditingConversionKey()
                    .width('100%')
                    .height(this.keyHeight)
            }
            .width('25%')
            Flex({
                direction: FlexDirection.Column,
                alignItems: ItemAlign.Center,
                justifyContent: FlexAlign.SpaceEvenly
            }) {
                Flex({
                    direction: FlexDirection.Row,
                    alignItems: ItemAlign.Center,
                    justifyContent: FlexAlign.SpaceEvenly
                }) {
                    EditingClipboardClearKey()
                        .width('100%')
                        .height('100%')
                    EditingPasteKey()
                        .width('100%')
                        .height('100%')
                }
                .height(this.keyHeight)
                Flex({
                    direction: FlexDirection.Row,
                    alignItems: ItemAlign.Center,
                    justifyContent: FlexAlign.SpaceEvenly
                }) {
                    EditingMoveLeftKey()
                        .width('100%')
                        .height('100%')
                    EditingMoveUpKey()
                        .width('100%')
                        .height('100%')
                    EditingMoveRightKey()
                        .width('100%')
                        .height('100%')
                }
                .height(this.keyHeight)
                Flex({
                    direction: FlexDirection.Row,
                    alignItems: ItemAlign.Center,
                    justifyContent: FlexAlign.SpaceEvenly
                }) {
                    EditingJumpStartKey()
                        .width('100%')
                        .height('100%')
                    EditingMoveDownKey()
                        .width('100%')
                        .height('100%')
                    EditingJumpEndKey()
                        .width('100%')
                        .height('100%')
                }
                .height(this.keyHeight)
                EditingSpaceKey()
                    .width('100%')
                    .height(this.keyHeight)
            }
            .width('50%')
            Flex({
                direction: FlexDirection.Column,
                alignItems: ItemAlign.Center,
                justifyContent: FlexAlign.SpaceEvenly
            }) {
                EditingBackKey()
                    .width('100%')
                    .height(this.keyHeight)
                EditingBackspaceKey()
                    .width('100%')
                    .height(this.keyHeight)
                EditingRightDeleteKey()
                    .width('100%')
                    .height(this.keyHeight)
                EditingEnterKey()
                    .width('100%')
                    .height(this.keyHeight)
            }
            .width('25%')
        }
        .width('100%')
        .height(controller.keyboardHeight)
    }
}
