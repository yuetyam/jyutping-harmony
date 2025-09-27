import { HomeScreen } from './HomeScreen';
import { RomanizationScreen } from './RomanizationScreen';
import { CantoneseScreen } from './CantoneseScreen';
import { AboutScreen } from './AboutScreen';

@Entry
@Component
struct Index {

    @StorageProp('topRectHeight') topRectHeight: number = 0;
    @StorageProp('bottomRectHeight') bottomRectHeight: number = 0;

    @State private selection: number = 0;

    @Builder
    private tabBuilder(index: number, title: Resource, icon: Resource) {
        Column({ space: 4 }) {
            SymbolGlyph(icon)
                .fontSize(24)
                .fontColor(this.selection === index ? [$r('app.color.accent')] :
                    [$r('sys.color.ohos_id_color_primary')])
            Text(title)
                .fontSize(12)
                .fontColor(this.selection === index ? $r('app.color.accent') : $r('sys.color.ohos_id_color_primary'))
        }
        .justifyContent(FlexAlign.Center)
    }

    build() {
        Tabs({ barPosition: BarPosition.End, index: this.selection }) {
            TabContent() {
                HomeScreen()
            }
            .tabBar(this.tabBuilder(0, $r("app.string.tab_bar_home"), $r('sys.symbol.house')))

            TabContent() {
                RomanizationScreen()
            }
            .tabBar(this.tabBuilder(1, $r("app.string.tab_bar_romanization"), $r('sys.symbol.doc_text_badge_magnifyingglass')))

            TabContent() {
                CantoneseScreen()
            }
            .tabBar(this.tabBuilder(2, $r("app.string.tab_bar_cantonese"), $r('sys.symbol.worldclock')))

            TabContent() {
                AboutScreen()
            }
            .tabBar(this.tabBuilder(3, $r("app.string.tab_bar_about"), $r('sys.symbol.info_circle')))
        }
        .barMode(BarMode.Fixed)
        .barHeight(56)
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.window_background'))
        .onChange((index: number) => {
            this.selection = index;
        })
        .padding({
            top: this.getUIContext().px2vp(this.topRectHeight),
            bottom: this.getUIContext().px2vp(this.bottomRectHeight)
        })
    }
}
