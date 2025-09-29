import controller from '../model/InputController';
import { KeyboardForm } from '../model/KeyboardForm';
import BackspaceKey from './BackspaceKey';
import EnterKey from './EnterKey';
import LeftKey from './LeftKey';
import RightKey from './RightKey';
import SpaceKey from './SpaceKey';
import SymbolKey from './SymbolKey';
import ToolBar from './TooBar';
import TransformKey from './TransformKey';

@ComponentV2
export default struct CantoneseSymbolicKeyboard {
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
                SymbolKey({ keyText: "［" })
                SymbolKey({ keyText: "］" })
                SymbolKey({ keyText: "｛" })
                SymbolKey({ keyText: "｝" })
                SymbolKey({ keyText: "#" })
                SymbolKey({ keyText: "%" })
                SymbolKey({ keyText: "^" })
                SymbolKey({ keyText: "*" })
                SymbolKey({ keyText: "+" })
                SymbolKey({ keyText: "=" })
            }
            .width('100%')
            .height(this.keyHeight)

            Flex({ justifyContent: FlexAlign.SpaceBetween }) {
                SymbolKey({ keyText: "_" })
                SymbolKey({ keyText: "—" })
                SymbolKey({ keyText: "\\" })
                SymbolKey({ keyText: "｜" })
                SymbolKey({ keyText: "～" })
                SymbolKey({ keyText: "《" })
                SymbolKey({ keyText: "》" })
                SymbolKey({ keyText: "¥" })
                SymbolKey({ keyText: "&" })
                SymbolKey({ keyText: "·" })
            }
            .width('100%')
            .height(this.keyHeight)

            Flex({ justifyContent: FlexAlign.SpaceBetween }) {
                TransformKey({ destination: KeyboardForm.Numeric }).width('13%')
                Blank().width('2%')
                SymbolKey({ keyText: "…" }).width('10%')
                SymbolKey({ keyText: "©" }).width('10%')
                SymbolKey({ keyText: "®" }).width('10%')
                SymbolKey({ keyText: "℗" }).width('10%')
                SymbolKey({ keyText: "™" }).width('10%')
                SymbolKey({ keyText: "℠" }).width('10%')
                SymbolKey({ keyText: "'" }).width('10%')
                Blank().width('2%')
                BackspaceKey().width('13%')
            }
            .width('100%')
            .height(this.keyHeight)

            Flex({ justifyContent: FlexAlign.SpaceBetween }) {
                TransformKey({ destination: KeyboardForm.Alphabetic }).width('20%')
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
