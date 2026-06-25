import controller from '../InputController';
import { PresetConstant } from '../model/PresetConstant';

@ComponentV2
export default struct SymbolSidebarScrollView {
    @Param @Require @Once symbols: string[];
    private scroller: Scroller = new Scroller();
    build() {
        List({ scroller: this.scroller }) {
            ForEach(this.symbols, (symbol: string) => {
                ListItem() {
                    Button() {
                        Text(this.centerFormed(symbol))
                            .textAlign(TextAlign.Center)
                            .fontSize(18)
                            .fontFamily('HarmonyOS Sans TC')
                    }
                    .borderRadius(PresetConstant.largeKeyCornerRadius)
                    .backgroundColor(Color.Transparent)
                    .width('100%')
                    .height('25%')
                    .onClick(() => {
                        controller.playInputSound();
                        controller.triggerHapticFeedback();
                        controller.insert(symbol);
                        this.scroller.scrollToIndex(0);
                    })
                }
                ListItem() { Divider() }
            }, (item: string) => item)
        }
        .listDirection(Axis.Vertical)
        .scrollBar(BarState.Off)
        .width('100%')
        .height('100%')
    }

    /** Apply Variation Selector to the punctuation mark */
    private centerFormed(text: string): string {
        const code = text.codePointAt(0) ?? 0x3F;
        return String.fromCodePoint(code, 0xFE01);
    }
}
