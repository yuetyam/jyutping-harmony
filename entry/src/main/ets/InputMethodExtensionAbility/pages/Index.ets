import inputController from '../model/InputController';
import { KeyboardForm } from '../model/KeyboardForm';
import ABCKeyboard from './ABCKeyboard';
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
                if (inputController.keyboardForm === KeyboardForm.Numeric) {
                    NumericKeyboard()
                } else if (inputController.keyboardForm === KeyboardForm.Symbolic) {
                    SymbolicKeyboard()
                } else if (inputController.keyboardForm === KeyboardForm.Alphabetic) {
                    ABCKeyboard()
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
