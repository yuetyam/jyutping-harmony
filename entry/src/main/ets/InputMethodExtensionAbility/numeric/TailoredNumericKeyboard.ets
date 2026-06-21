import TailoredNumberKey from './TailoredNumberKey'
import { KeyboardForm } from '../model/KeyboardForm';
import ToolBar from '../pages/TooBar';
import NineKeyNavigateKey from '../ninekey/NineKeyNavigateKey';
import NineKeyBackspaceKey from '../ninekey/NineKeyBackspaceKey';
import NineKeyEnterKey from '../ninekey/NineKeyEnterKey';
import NineKeySpaceKey from '../ninekey/NineKeySpaceKey';
import NineKeyPlaceholderView from '../ninekey/NineKeyPlaceholderView';
import { VirtualInputKey } from '../model/VirtualInputKey';
import TailoredNumericDotKey from './TailoredNumericDotKey';

@ComponentV2
export default struct TailoredNumericKeyboard {
    build() {
        Flex({
            direction: FlexDirection.Column,
            alignItems: ItemAlign.Center,
            justifyContent: FlexAlign.SpaceBetween
        }) {
            Stack() {
                ToolBar()
            }
            .width("100%")
            .height("56vp")

            Flex({
                direction: FlexDirection.Row,
                alignItems: ItemAlign.Center,
                justifyContent: FlexAlign.SpaceBetween
            }) {
                Flex({
                    direction: FlexDirection.Column,
                    alignItems: ItemAlign.Center,
                    justifyContent: FlexAlign.SpaceBetween
                }) {
                    Flex({
                        direction: FlexDirection.Row,
                        alignItems: ItemAlign.Center,
                        justifyContent: FlexAlign.SpaceBetween
                    }) {
                        NineKeyPlaceholderView().width("22.2%")
                        Flex({
                            direction: FlexDirection.Column,
                            alignItems: ItemAlign.Center,
                            justifyContent: FlexAlign.SpaceBetween
                        }) {
                            Flex({
                                direction: FlexDirection.Row,
                                alignItems: ItemAlign.Center,
                                justifyContent: FlexAlign.SpaceBetween
                            }) {
                                TailoredNumberKey({ element: VirtualInputKey.number1 }).width("33.33%")
                                TailoredNumberKey({ element: VirtualInputKey.number2 }).width("33.33%")
                                TailoredNumberKey({ element: VirtualInputKey.number3 }).width("33.33%")
                            }
                            .height("33%")
                            Flex({
                                direction: FlexDirection.Row,
                                alignItems: ItemAlign.Center,
                                justifyContent: FlexAlign.SpaceBetween
                            }) {
                                TailoredNumberKey({ element: VirtualInputKey.number4 }).width("33.33%")
                                TailoredNumberKey({ element: VirtualInputKey.number5 }).width("33.33%")
                                TailoredNumberKey({ element: VirtualInputKey.number6 }).width("33.33%")
                            }
                            .height("33%")
                            Flex({
                                direction: FlexDirection.Row,
                                alignItems: ItemAlign.Center,
                                justifyContent: FlexAlign.SpaceBetween
                            }) {
                                TailoredNumberKey({ element: VirtualInputKey.number7 }).width("33.33%")
                                TailoredNumberKey({ element: VirtualInputKey.number8 }).width("33.33%")
                                TailoredNumberKey({ element: VirtualInputKey.number9 }).width("33.33%")
                            }
                            .height("33%")
                        }
                        .width("77.8%")
                    }
                    .height("75%")
                    Flex({
                        direction: FlexDirection.Row,
                        alignItems: ItemAlign.Center,
                        justifyContent: FlexAlign.SpaceBetween
                    }) {
                        NineKeyNavigateKey({ destination: KeyboardForm.Primary }).width("22.2%")
                        TailoredNumericDotKey().width("25.9%")
                        TailoredNumberKey({ element: VirtualInputKey.number0 }).width("25.9%")
                        NineKeySpaceKey().width("26%")
                    }
                    .height("25%")
                }
                .width("81.8%")
                Flex({
                    direction: FlexDirection.Column,
                    alignItems: ItemAlign.Center,
                    justifyContent: FlexAlign.SpaceBetween
                }) {
                    NineKeyBackspaceKey().height("25%")
                    NineKeyNavigateKey({ destination: KeyboardForm.Numeric }).height("25%")
                    NineKeyEnterKey().height("50%")
                }
                .width("18.2%")
            }
            .width("100%")
            .height("calc(100% - 56vp)")
        }
        .width("100%")
        .width("100%")
    }
}
