import EditingPanel from '../editing/EditingPanel';
import controller from '../InputController';
import { InputModeCompanion } from '../model/InputMode';
import { KeyboardForm } from '../model/KeyboardForm';
import ABCKeyboard from './ABCKeyboard';
import CandidateBoard from './CandidateBoard';
import CantoneseKeyboard from './CantoneseKeyboard';
import CantoneseNumericKeyboard from './CantoneseNumericKeyboard';
import CantoneseSymbolicKeyboard from './CantoneseSymbolicKeyboard';
import { EmojiKeyboard } from './EmojiKeyboard';
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
                    if (InputModeCompanion.isABC(controller.inputMode)) {
                        ABCKeyboard()
                    } else {
                        CantoneseKeyboard()
                    }
                } else if (controller.keyboardForm === KeyboardForm.Numeric) {
                    if (InputModeCompanion.isABC(controller.inputMode)) {
                        NumericKeyboard()
                    } else {
                        CantoneseNumericKeyboard()
                    }
                } else if (controller.keyboardForm === KeyboardForm.Symbolic) {
                    if (InputModeCompanion.isABC(controller.inputMode)) {
                        SymbolicKeyboard()
                    } else {
                        CantoneseSymbolicKeyboard()
                    }
                } else if (controller.keyboardForm === KeyboardForm.EditingPanel) {
                    EditingPanel()
                } else if (controller.keyboardForm === KeyboardForm.Settings) {
                    SettingsPanel()
                } else if (controller.keyboardForm === KeyboardForm.CandidateBoard) {
                    CandidateBoard()
                } else if (controller.keyboardForm === KeyboardForm.EmojiBoard) {
                    EmojiKeyboard()
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
