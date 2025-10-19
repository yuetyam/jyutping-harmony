import EditingPanel from '../editing/EditingPanel';
import controller from '../InputController';
import { InputMode } from '../model/InputMode';
import { KeyboardForm } from '../model/KeyboardForm';
import ABCKeyboard from './ABCKeyboard';
import CantoneseKeyboard from './CantoneseKeyboard';
import CantoneseNumericKeyboard from './CantoneseNumericKeyboard';
import CantoneseSymbolicKeyboard from './CantoneseSymbolicKeyboard';
import NumericKeyboard from './NumericKeyboard';
import SettingsPanel from './SettingsPanel';
import SymbolicKeyboard from './SymbolicKeyboard';

@Entry
@ComponentV2
struct Index {
    build() {
        Stack() {
            Flex({
                direction: FlexDirection.Column,
                alignItems: ItemAlign.Center,
                justifyContent: FlexAlign.SpaceBetween
            }) {
                if (controller.keyboardForm === KeyboardForm.Alphabetic) {
                    if (controller.inputMode === InputMode.ABC) {
                        ABCKeyboard()
                    } else {
                        CantoneseKeyboard()
                    }
                } else if (controller.keyboardForm === KeyboardForm.Numeric) {
                    if (controller.inputMode === InputMode.ABC) {
                        NumericKeyboard()
                    } else {
                        CantoneseNumericKeyboard()
                    }
                } else if (controller.keyboardForm === KeyboardForm.Symbolic) {
                    if (controller.inputMode === InputMode.ABC) {
                        SymbolicKeyboard()
                    } else {
                        CantoneseSymbolicKeyboard()
                    }
                } else if (controller.keyboardForm === KeyboardForm.EditingPanel) {
                    EditingPanel()
                } else if (controller.keyboardForm === KeyboardForm.Settings) {
                    SettingsPanel()
                } else {
                    CantoneseKeyboard()
                }
            }
            .width("100%")
            .height("100%")
            .backgroundColor($r('app.color.keyboard_background'))
        }
        .position({ x: 0, y: 0 })
        .zIndex(99999)
    }
}
