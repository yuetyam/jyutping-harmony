import { HomeScreen } from './HomeScreen';
import { RomanizationScreen } from './RomanizationScreen';
import { CantoneseScreen } from './CantoneseScreen';
import { AboutScreen } from './AboutScreen';
import { PrivacyScreen } from './PrivacyScreen';
import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';

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

    @State private privacy: string = "0";

    aboutToAppear(): void {
        try {
            const options: preferences.Options = { name: "shared" };
            let sharedPreferences = preferences.getPreferencesSync(this.getUIContext().getHostContext(), options);
            this.privacy = sharedPreferences.getSync("privacy", "0") as string;
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error("Failed to fetch agreements value, message: " + err.message + ", code: " + err.code);
        }
    }

    build() {
        if (this.privacy != "2025") {
            PrivacyScreen({ privacy: this.privacy })
        } else {
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
}
