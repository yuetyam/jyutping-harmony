import { HomeScreen } from './HomeScreen';
import { RomanizationScreen } from './RomanizationScreen';
import { CantoneseScreen } from './CantoneseScreen';
import { AboutScreen } from './AboutScreen';
import { PrivacyScreen } from './PrivacyScreen';
import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { SymbolGlyphModifier, uiMaterial } from "@kit.ArkUI";

@Entry
@Component
struct Index {
    private tabBarStyle(icon: Resource, label: Resource): BottomTabBarStyle {
        return new BottomTabBarStyle({
            normal: new SymbolGlyphModifier(icon).renderingStrategy(SymbolRenderingStrategy.SINGLE).fontColor([$r('sys.color.ohos_id_color_primary')]),
            selected: new SymbolGlyphModifier(icon).renderingStrategy(SymbolRenderingStrategy.SINGLE).fontColor([$r('app.color.accent')])
        }, label).labelStyle({
            unselectedColor: $r('sys.color.ohos_id_color_primary'),
            selectedColor: $r('app.color.accent')
        });
    }

    @State private privacy: string = "0";

    private settingsFileName: string ="shared";
    private privacySettingsKey: string ="privacy";
    private definedPrivacyValue: string = "2025";
    private fallbackPrivacyValue: string = "0";

    aboutToAppear(): void {
        try {
            const options: preferences.Options = { name: this.settingsFileName };
            let sharedPreferences = preferences.getPreferencesSync(this.getUIContext().getHostContext(), options);
            this.privacy = sharedPreferences.getSync(this.privacySettingsKey, this.fallbackPrivacyValue) as string;
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error("Failed to fetch agreements value, message: " + err.message + ", code: " + err.code);
        }
    }

    build() {
        if (this.privacy != this.definedPrivacyValue) {
            PrivacyScreen({ privacy: this.privacy })
        } else {
            Tabs({ barPosition: BarPosition.End }) {
                TabContent() {
                    HomeScreen()
                }
                .tabBar(this.tabBarStyle($r('sys.symbol.house'), $r('app.string.tab_bar_home')))
                TabContent() {
                    RomanizationScreen()
                }
                .tabBar(this.tabBarStyle($r('sys.symbol.doc_text_badge_magnifyingglass'), $r('app.string.tab_bar_romanization')))
                TabContent() {
                    CantoneseScreen()
                }
                .tabBar(this.tabBarStyle($r('sys.symbol.worldclock'), $r('app.string.tab_bar_cantonese')))
                TabContent() {
                    AboutScreen()
                }
                .tabBar(this.tabBarStyle($r('sys.symbol.info_circle'), $r('app.string.tab_bar_about')))
            }
            .barOverlap(true)
            .barFloatingStyle({
                adaptToHandedness: true,
                systemMaterial: new uiMaterial.ImmersiveMaterial({
                    style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
                    applyShadow: true,
                    interactive: true,
                    lightEffect: { color: Color.White }
                })
            })
            .width('100%')
            .height('100%')
            .backgroundColor($r('app.color.window_background'))
        }
    }
}
