import BackspaceKey from './BackspaceKey';
import EnterKey from './EnterKey';
import LeftKey from './LeftKey';
import LetterKey from './LetterKey';
import RightKey from './RightKey';
import ShiftKey from './ShiftKey';
import SpaceKey from './SpaceKey';
import TransformKey from './TransformKey';

@Component
export default struct ABCKeyboard {
    topRowLetters: string[] = ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"];
    mediumRowLetters: string[] = ["a", "s", "d", "f", "g", "h", "j", "k", "l"];
    bottomRowLetters: string[] = ["z", "x", "c", "v", "b", "n", "m"];
    build() {
        Flex({
            direction: FlexDirection.Column,
            alignItems: ItemAlign.Center,
            justifyContent: FlexAlign.SpaceEvenly
        }) {
            Flex({ justifyContent: FlexAlign.SpaceBetween }) {
                Blank()
            }
            .width('100%')
            .height("56vp")
            Flex({ justifyContent: FlexAlign.SpaceBetween }) {
                ForEach(
                    this.topRowLetters,
                    (item: string) => {
                        LetterKey({ keyText: item })
                    },
                    (item: string) => item
                );
            }
            .width('100%')
            .height("56vp")
            Flex({ justifyContent: FlexAlign.SpaceBetween }) {
                Blank().width('5%')
                ForEach(
                    this.mediumRowLetters,
                    (item: string) => {
                        LetterKey({ keyText: item }).width('10%')
                    },
                    (item: string) => item
                );
                Blank().width('5%')
            }
            .width('100%')
            .height("56vp")
            Flex({ justifyContent: FlexAlign.SpaceBetween }) {
                ShiftKey().width('13%')
                Blank().width('2%')
                ForEach(
                    this.bottomRowLetters,
                    (item: string) => {
                        LetterKey({ keyText: item }).width('10%')
                    },
                    (item: string) => item
                );
                Blank().width('2%')
                BackspaceKey().width('13%')
            }
            .width('100%')
            .height("56vp")
            Flex({ justifyContent: FlexAlign.SpaceBetween }) {
                TransformKey().width('20%')
                LeftKey().width('10%')
                SpaceKey().width('40%')
                RightKey().width('10%')
                EnterKey().width('20%')
            }
            .width('100%')
            .height("56vp")
        }
    }
}
