import controller from '../InputController';
import { VirtualInputKey } from '../model/VirtualInputKey';
import { KeyboardForm } from '../model/KeyboardForm';
import BackspaceKey from './BackspaceKey';
import CandidateBar from './CandidateBar';
import EnterKey from './EnterKey';
import LeftKey from './LeftKey';
import LetterKey from './LetterKey';
import RightKey from './RightKey';
import ShiftKey from './ShiftKey';
import SpaceKey from './SpaceKey';
import ToolBar from './TooBar';
import TransformKey from './TransformKey';
import GlobeKey from './GlobeKey';
import { PresetConstant } from '../model/PresetConstant';

@ComponentV2
export default struct CantoneseKeyboard {
    private keyHeight: Length = controller.keyHeight;
    private numericForm: KeyboardForm = controller.useDedicatedNumberPad ? KeyboardForm.DedicatedNumbers : KeyboardForm.Numeric;
    build() {
        Flex({
            direction: FlexDirection.Column,
            alignItems: ItemAlign.Center,
            justifyContent: FlexAlign.SpaceEvenly
        }) {
            Stack() {
                if (controller.isBuffering) {
                    CandidateBar()
                } else {
                    ToolBar()
                }
            }
            .width('100%')
            .height(PresetConstant.toolBarHeight)
            Flex({ justifyContent: FlexAlign.SpaceBetween }) {
                LetterKey({ virtual: VirtualInputKey.letterQ })
                LetterKey({ virtual: VirtualInputKey.letterW })
                LetterKey({ virtual: VirtualInputKey.letterE })
                LetterKey({ virtual: VirtualInputKey.letterR })
                LetterKey({ virtual: VirtualInputKey.letterT })
                LetterKey({ virtual: VirtualInputKey.letterY })
                LetterKey({ virtual: VirtualInputKey.letterU })
                LetterKey({ virtual: VirtualInputKey.letterI })
                LetterKey({ virtual: VirtualInputKey.letterO })
                LetterKey({ virtual: VirtualInputKey.letterP })
            }
            .width('100%')
            .height(this.keyHeight)

            Flex({ justifyContent: FlexAlign.SpaceBetween }) {
                Blank().width('5%')
                LetterKey({ virtual: VirtualInputKey.letterA }).width('10%')
                LetterKey({ virtual: VirtualInputKey.letterS }).width('10%')
                LetterKey({ virtual: VirtualInputKey.letterD }).width('10%')
                LetterKey({ virtual: VirtualInputKey.letterF }).width('10%')
                LetterKey({ virtual: VirtualInputKey.letterG }).width('10%')
                LetterKey({ virtual: VirtualInputKey.letterH }).width('10%')
                LetterKey({ virtual: VirtualInputKey.letterJ }).width('10%')
                LetterKey({ virtual: VirtualInputKey.letterK }).width('10%')
                LetterKey({ virtual: VirtualInputKey.letterL }).width('10%')
                Blank().width('5%')
            }
            .width('100%')
            .height(this.keyHeight)

            Flex({ justifyContent: FlexAlign.SpaceBetween }) {
                ShiftKey().width('13%')
                Blank().width('2%')
                LetterKey({ virtual: VirtualInputKey.letterZ }).width('10%')
                LetterKey({ virtual: VirtualInputKey.letterX }).width('10%')
                LetterKey({ virtual: VirtualInputKey.letterC }).width('10%')
                LetterKey({ virtual: VirtualInputKey.letterV }).width('10%')
                LetterKey({ virtual: VirtualInputKey.letterB }).width('10%')
                LetterKey({ virtual: VirtualInputKey.letterN }).width('10%')
                LetterKey({ virtual: VirtualInputKey.letterM }).width('10%')
                Blank().width('2%')
                BackspaceKey().width('13%')
            }
            .width('100%')
            .height(this.keyHeight)

            if (controller.needsGlobeKey) {
                Flex({ justifyContent: FlexAlign.SpaceBetween }) {
                    TransformKey({ destination: this.numericForm }).width('15%')
                    GlobeKey().width('10%')
                    LeftKey().width('10%')
                    SpaceKey().width('37%')
                    RightKey().width('10%')
                    EnterKey().width('18%')
                }
                .width('100%')
                .height(this.keyHeight)
            } else {
                Flex({ justifyContent: FlexAlign.SpaceBetween }) {
                    TransformKey({ destination: this.numericForm }).width('20%')
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
}
