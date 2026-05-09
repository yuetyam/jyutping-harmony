import controller from '../InputController';
import { NineKeyCombo } from './NineKeyCombo';
import { KeyboardForm } from '../model/KeyboardForm';
import CandidateBar from '../pages/CandidateBar';
import NineKeyInputKey from './NineKeyInputKey';
import ToolBar from '../pages/TooBar';
import NineKeySpecialKey from './NineKeySpecialKey';
import NineKeyNavigateKey from './NineKeyNavigateKey';
import NineKeyBackspaceKey from './NineKeyBackspaceKey';
import NineKeyEnterKey from './NineKeyEnterKey';
import NineKeySpaceKey from './NineKeySpaceKey';
import NineKeyPlaceholderView from './NineKeyPlaceholderView';

@ComponentV2
export default struct NineKeyKeyboard {
    build() {
        Flex({
            direction: FlexDirection.Column,
            alignItems: ItemAlign.Center,
            justifyContent: FlexAlign.SpaceBetween
        }) {
            Stack() {
                if (controller.isBuffering) {
                    CandidateBar()
                } else {
                    ToolBar()
                }
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
                        NineKeyPlaceholderView().width("23.5%")
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
                                NineKeySpecialKey().width("33.33%")
                                NineKeyInputKey({ combo: NineKeyCombo.ABC }).width("33.33%")
                                NineKeyInputKey({ combo: NineKeyCombo.DEF }).width("33.33%")
                            }
                            .height("33%")
                            Flex({
                                direction: FlexDirection.Row,
                                alignItems: ItemAlign.Center,
                                justifyContent: FlexAlign.SpaceBetween
                            }) {
                                NineKeyInputKey({ combo: NineKeyCombo.GHI }).width("33.33%")
                                NineKeyInputKey({ combo: NineKeyCombo.JKL }).width("33.33%")
                                NineKeyInputKey({ combo: NineKeyCombo.MNO }).width("33.33%")
                            }
                            .height("33%")
                            Flex({
                                direction: FlexDirection.Row,
                                alignItems: ItemAlign.Center,
                                justifyContent: FlexAlign.SpaceBetween
                            }) {
                                NineKeyInputKey({ combo: NineKeyCombo.PQRS }).width("33.33%")
                                NineKeyInputKey({ combo: NineKeyCombo.TUV }).width("33.33%")
                                NineKeyInputKey({ combo: NineKeyCombo.WXYZ }).width("33.33%")
                            }
                            .height("33%")
                        }
                        .width("76.5%")
                    }
                    .height("75%")
                    Flex({
                        direction: FlexDirection.Row,
                        alignItems: ItemAlign.Center,
                        justifyContent: FlexAlign.SpaceBetween
                    }) {
                        NineKeyNavigateKey({ destination: KeyboardForm.Numeric }).width("23.5%")
                        NineKeySpaceKey().width("76.5%")
                    }
                    .height("25%")
                }
                .width("81.2%")
                Flex({
                    direction: FlexDirection.Column,
                    alignItems: ItemAlign.Center,
                    justifyContent: FlexAlign.SpaceBetween
                }) {
                    NineKeyBackspaceKey().height("25%")
                    NineKeyPlaceholderView().height("25%")
                    NineKeyEnterKey().height("50%")
                }
                .width("18.8%")
            }
            .width("100%")
            .height("calc(100% - 56vp)")
        }
        .width("100%")
        .width("100%")
    }
}
