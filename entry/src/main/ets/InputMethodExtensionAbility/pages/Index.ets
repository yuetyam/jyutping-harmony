import EditingPanel from '../editing/EditingPanel';
import controller from '../InputController';
import { InputModeCompanion } from '../model/InputMode';
import { KeyboardForm } from '../model/KeyboardForm';
import { KeyboardLayoutCompanion } from '../model/KeyboardLayout';
import ABCKeyboard from './ABCKeyboard';
import CandidateBoard from './CandidateBoard';
import CantoneseKeyboard from './CantoneseKeyboard';
import CantoneseNumericKeyboard from './CantoneseNumericKeyboard';
import CantoneseSymbolicKeyboard from './CantoneseSymbolicKeyboard';
import EmojiBoard from '../emoji/EmojiBoard';
import LayoutPickerPanel from './LayoutPickerPanel';
import NineKeyKeyboard from '../ninekey/NineKeyKeyboard';
import NumericKeyboard from './NumericKeyboard';
import SettingsPanel from './SettingsPanel';
import SymbolicKeyboard from './SymbolicKeyboard';
import TailoredNumericKeyboard from '../numeric/TailoredNumericKeyboard';

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
                if (controller.keyboardForm === KeyboardForm.Primary) {
                    if (InputModeCompanion.isABC(controller.inputMode)) {
                        ABCKeyboard()
                    } else if (KeyboardLayoutCompanion.isNineKey(controller.keyboardLayout)) {
                        NineKeyKeyboard()
                    } else {
                        CantoneseKeyboard()
                    }
                } else if (controller.keyboardForm === KeyboardForm.DedicatedNumbers) {
                    TailoredNumericKeyboard()
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
                } else if (controller.keyboardForm === KeyboardForm.LayoutPicker) {
                    LayoutPickerPanel()
                } else if (controller.keyboardForm === KeyboardForm.CandidateBoard) {
                    CandidateBoard()
                } else if (controller.keyboardForm === KeyboardForm.EmojiBoard) {
                    EmojiBoard()
                } else {
                    CantoneseKeyboard()
                }
            }
            .width("100%")
            .height("100%")
        }
        .position({ x: 0, y: 0 })
        .zIndex(99999)
    }
}
