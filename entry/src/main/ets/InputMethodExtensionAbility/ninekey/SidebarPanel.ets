import controller from "../InputController";
import { KeyboardFormCompanion } from "../model/KeyboardForm";
import { PresetConstant } from "../model/PresetConstant";
import SidebarScrollView from "./SidebarScrollView";
import SymbolSidebarScrollView from "./SymbolSidebarScrollView";

@ComponentV2
export default struct SidebarPanel {
    private punctuation: string[] = ["，", "。", "？", "！", "、", "：", "；", "／", "…", "~", "～"];
    private symbols: string[] = ["+", "-", "*", "/", "=", "%", ":", "@", "#", ",", "$", "~", "≈", "×", "÷"];
    build() {
        Stack() {
            Flex({
                direction: FlexDirection.Column,
                alignItems: ItemAlign.Center,
                justifyContent: FlexAlign.Center
            }) {
                if (controller.isBuffering) {
                    SidebarScrollView()
                } else {
                    SymbolSidebarScrollView({ symbols: KeyboardFormCompanion.isDedicatedNumbers(controller.keyboardForm) ? this.symbols : this.punctuation })
                }
            }
            .backgroundColor($r('app.color.key_shallow'))
            .clip(true)
            .borderRadius(PresetConstant.largeKeyCornerRadius)
            .shadow({
                radius: 1,
                color: Color.Gray,
                offsetY: 1
            })
            .width("calc(100% - 6vp)")
            .height("calc(100% - 6vp)")
        }
        .width('100%')
        .height('100%')
    }
}
