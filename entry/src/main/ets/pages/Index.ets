import { HomeScreen } from './HomeScreen';
import { RomanizationScreen } from './RomanizationScreen';
import { CantoneseScreen } from './CantoneseScreen';
import { AboutScreen } from './AboutScreen';
import { PrivacyScreen } from './PrivacyScreen';
import { preferences } from '@kit.ArkData';
import { SymbolGlyphModifier, uiMaterial } from "@kit.ArkUI";
import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';
import { hdsMaterial, HdsTabs } from '@kit.UIDesignKit';

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

    @State private selection: number = 0;

    @Builder
    private tabBuilder(index: number, title: Resource, icon: Resource) {
        Column({ space: 4 }) {
            SymbolGlyph(icon)
                .fontSize(24)
                .fontColor(this.selection === index ? [$r('app.color.accent')] : [$r('sys.color.ohos_id_color_primary')])
            Text(title)
                .fontSize(12)
                .fontColor(this.selection === index ? $r('app.color.accent') : $r('sys.color.ohos_id_color_primary'))
        }
        .justifyContent(FlexAlign.Center)
    }

    @State private privacy: string = "0";
    private settingsFileName: string = "shared";
    private privacySettingsKey: string = "privacy";
    private definedPrivacyValue: string = "2025";
    private fallbackPrivacyValue: string = "0";

    aboutToAppear(): void {
        try {
            const options: preferences.Options = { name: this.settingsFileName };
            const sharedPreferences = preferences.getPreferencesSync(this.getUIContext().getHostContext(), options);
            this.privacy = sharedPreferences.getSync(this.privacySettingsKey, this.fallbackPrivacyValue) as string;
        } catch (error) {
            const err: BusinessError = error as BusinessError;
            console.error("Failed to fetch agreements value, message: " + err.message + ", code: " + err.code);
        }
    }

    build() {
        if (this.privacy != this.definedPrivacyValue) {
            PrivacyScreen({ privacy: this.privacy })
        } else if (deviceInfo.apiAvailable('26.0.0')) {
            Tabs() {
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
            .barPosition(BarPosition.End)
            .vertical(false)
            .barFloatingStyle({
                adaptToHandedness: true,
                systemMaterial: new uiMaterial.ImmersiveMaterial({
                    style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
                    interactive: true,
                    lightEffect: {}
                })
            })
            .background($r('app.color.window_background'))
        } else {
            HdsTabs() {
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
            .barPosition(BarPosition.End)
            .vertical(false)
            .barFloatingStyle({
                barBottomMargin: 28,
                adaptToHandedness: true,
                systemMaterialEffect: {
                    materialType: hdsMaterial.MaterialType.ADAPTIVE,
                    materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
                }
            })
            .background($r('app.color.window_background'))
        }
    }
}
