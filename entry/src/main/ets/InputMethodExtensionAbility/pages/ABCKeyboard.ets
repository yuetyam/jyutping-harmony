import BackspaceKey from './BackspaceKey';
import EnterKey from './EnterKey';
import LetterKey from './LetterKey';

@Component
export default struct ABCKeyboard {
    letters: string[] = ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"];
    build() {
        Flex({
            direction: FlexDirection.Column,
            alignItems: ItemAlign.Center,
            justifyContent: FlexAlign.SpaceEvenly
        }) {
            Flex({ justifyContent: FlexAlign.SpaceBetween }) {
                ForEach(
                    this.letters,
                    (item: string) => {
                        LetterKey({ keyText: item })
                    },
                    (item: string) => item
                );
            }
            .padding({ top: "2%" })
            .width("96%")
            .height("25%")
            Flex({ justifyContent: FlexAlign.SpaceBetween }) {
                BackspaceKey()
            }
            .width("96%")
            .height("25%")
            Flex({ justifyContent: FlexAlign.SpaceBetween }) {
                EnterKey()
            }
            .width("96%")
            .height("25%")
        }
    }
}
