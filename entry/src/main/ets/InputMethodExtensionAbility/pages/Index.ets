import controller from '../model/InputController';
import { InputMode } from '../model/InputMode';
import { KeyboardForm } from '../model/KeyboardForm';
import ABCKeyboard from './ABCKeyboard';
import CantoneseNumericKeyboard from './CantoneseNumericKeyboard';
import CantoneseSymbolicKeyboard from './CantoneseSymbolicKeyboard';
import NumericKeyboard from './NumericKeyboard';
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
                if (controller.keyboardForm === KeyboardForm.Numeric) {
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
                } else {
                    ABCKeyboard()
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
