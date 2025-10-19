import controller from '../InputController';
import { InputKeyEvent } from '../model/InputKeyEvent';
import { KeyboardForm } from '../model/KeyboardForm';
import BackspaceKey from './BackspaceKey';
import EnterKey from './EnterKey';
import LeftKey from './LeftKey';
import LetterKey from './LetterKey';
import RightKey from './RightKey';
import ShiftKey from './ShiftKey';
import SpaceKey from './SpaceKey';
import ToolBar from './TooBar';
import TransformKey from './TransformKey';

@ComponentV2
export default struct CantoneseKeyboard {
    keyHeight: Length = controller.keyHeight;
    build() {
        Flex({
            direction: FlexDirection.Column,
            alignItems: ItemAlign.Center,
            justifyContent: FlexAlign.SpaceEvenly
        }) {
            ToolBar()
                .width('100%')
                .height('56vp')
            Flex({ justifyContent: FlexAlign.SpaceBetween }) {
                LetterKey({ event: InputKeyEvent.letterQ })
                LetterKey({ event: InputKeyEvent.letterW })
                LetterKey({ event: InputKeyEvent.letterE })
                LetterKey({ event: InputKeyEvent.letterR })
                LetterKey({ event: InputKeyEvent.letterT })
                LetterKey({ event: InputKeyEvent.letterY })
                LetterKey({ event: InputKeyEvent.letterU })
                LetterKey({ event: InputKeyEvent.letterI })
                LetterKey({ event: InputKeyEvent.letterO })
                LetterKey({ event: InputKeyEvent.letterP })
            }
            .width('100%')
            .height(this.keyHeight)

            Flex({ justifyContent: FlexAlign.SpaceBetween }) {
                Blank().width('5%')
                LetterKey({ event: InputKeyEvent.letterA }).width('10%')
                LetterKey({ event: InputKeyEvent.letterS }).width('10%')
                LetterKey({ event: InputKeyEvent.letterD }).width('10%')
                LetterKey({ event: InputKeyEvent.letterF }).width('10%')
                LetterKey({ event: InputKeyEvent.letterG }).width('10%')
                LetterKey({ event: InputKeyEvent.letterH }).width('10%')
                LetterKey({ event: InputKeyEvent.letterJ }).width('10%')
                LetterKey({ event: InputKeyEvent.letterK }).width('10%')
                LetterKey({ event: InputKeyEvent.letterL }).width('10%')
                Blank().width('5%')
            }
            .width('100%')
            .height(this.keyHeight)

            Flex({ justifyContent: FlexAlign.SpaceBetween }) {
                ShiftKey().width('13%')
                Blank().width('2%')
                LetterKey({ event: InputKeyEvent.letterZ }).width('10%')
                LetterKey({ event: InputKeyEvent.letterX }).width('10%')
                LetterKey({ event: InputKeyEvent.letterC }).width('10%')
                LetterKey({ event: InputKeyEvent.letterV }).width('10%')
                LetterKey({ event: InputKeyEvent.letterB }).width('10%')
                LetterKey({ event: InputKeyEvent.letterN }).width('10%')
                LetterKey({ event: InputKeyEvent.letterM }).width('10%')
                Blank().width('2%')
                BackspaceKey().width('13%')
            }
            .width('100%')
            .height(this.keyHeight)

            Flex({ justifyContent: FlexAlign.SpaceBetween }) {
                TransformKey({ destination: KeyboardForm.Numeric }).width('20%')
                LeftKey().width('10%')
                SpaceKey().width('40%')
                RightKey().width('10%')
                EnterKey().width('20%')
            }
            .width('100%')
            .height(this.keyHeight)
        }
    }
}
