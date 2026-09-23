import controller from '../InputController';
import { Combo } from './Combo';
import { KeyboardForm } from '../model/KeyboardForm';
import CandidateBar from '../pages/CandidateBar';
import NineKeyInputKey from './NineKeyInputKey';
import ToolBar from '../pages/TooBar';
import NineKeySpecialKey from './NineKeySpecialKey';
import NineKeyNavigateKey from './NineKeyNavigateKey';
import NineKeyBackspaceKey from './NineKeyBackspaceKey';
import NineKeyEnterKey from './NineKeyEnterKey';
import NineKeySpaceKey from './NineKeySpaceKey';
import SidebarPanel from './SidebarPanel';
import { PresetConstant } from '../model/PresetConstant';
import NineKeyGlobeKey from './NineKeyGlobeKey';

@ComponentV2
export default struct NineKeyKeyboard {
    private numericForm: KeyboardForm = controller.useDedicatedNumberPad ? KeyboardForm.DedicatedNumbers : KeyboardForm.Numeric;
    private symbolicForm: KeyboardForm = controller.useDedicatedNumberPad ? KeyboardForm.Numeric : KeyboardForm.Symbolic;
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
            .height(PresetConstant.toolBarHeight)

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
                        SidebarPanel().width("22.2%")
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
                                NineKeyInputKey({ element: Combo.ABC }).width("33.33%")
                                NineKeyInputKey({ element: Combo.DEF }).width("33.33%")
                            }
                            .height("33%")
                            Flex({
                                direction: FlexDirection.Row,
                                alignItems: ItemAlign.Center,
                                justifyContent: FlexAlign.SpaceBetween
                            }) {
                                NineKeyInputKey({ element: Combo.GHI }).width("33.33%")
                                NineKeyInputKey({ element: Combo.JKL }).width("33.33%")
                                NineKeyInputKey({ element: Combo.MNO }).width("33.33%")
                            }
                            .height("33%")
                            Flex({
                                direction: FlexDirection.Row,
                                alignItems: ItemAlign.Center,
                                justifyContent: FlexAlign.SpaceBetween
                            }) {
                                NineKeyInputKey({ element: Combo.PQRS }).width("33.33%")
                                NineKeyInputKey({ element: Combo.TUV }).width("33.33%")
                                NineKeyInputKey({ element: Combo.WXYZ }).width("33.33%")
                            }
                            .height("33%")
                        }
                        .width("77.8%")
                    }
                    .height("75%")
                    if (controller.needsGlobeKey) {
                        Flex({
                            direction: FlexDirection.Row,
                            alignItems: ItemAlign.Center,
                            justifyContent: FlexAlign.SpaceBetween
                        }) {
                            NineKeyNavigateKey({ destination: this.numericForm }).width("22.2%")
                            NineKeyGlobeKey().width("12.8%")
                            NineKeySpaceKey().width("65%")
                        }
                        .height("25%")
                    } else {
                        Flex({
                            direction: FlexDirection.Row,
                            alignItems: ItemAlign.Center,
                            justifyContent: FlexAlign.SpaceBetween
                        }) {
                            NineKeyNavigateKey({ destination: this.numericForm }).width("22.2%")
                            NineKeySpaceKey().width("77.8%")
                        }
                        .height("25%")
                    }
                }
                .width("81.8%")
                Flex({
                    direction: FlexDirection.Column,
                    alignItems: ItemAlign.Center,
                    justifyContent: FlexAlign.SpaceBetween
                }) {
                    NineKeyBackspaceKey().height("25%")
                    NineKeyNavigateKey({ destination: this.symbolicForm }).height("25%")
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
