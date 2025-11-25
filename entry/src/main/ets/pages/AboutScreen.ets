import { bundleManager } from '@kit.AbilityKit';
import { WebLinkView } from './WebLinkView';

@Component
export struct AboutScreen {
    private pageStack: NavPathStack = new NavPathStack();
    private groupBackgroundColor = $r('app.color.group_background');
    private groupBorderRadius: Length = 12;
    @State private version: string = '_error';
    aboutToAppear(): void {
        bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION).then((bundleInfo) => {
            this.version = bundleInfo.versionName + ' (' + bundleInfo.versionCode + ')'
        })
    }
    build() {
        Navigation(this.pageStack) {
            List({ space: 20 }) {
                ListItem() {
                    Row({ space: 12 }) {
                        SymbolGlyph($r('sys.symbol.info_circle'))
                            .fontSize(20)
                            .fontColor([$r('app.color.accent')])
                        Text($r('app.string.about_version'))
                        Blank()
                        Text(this.version)
                            .copyOption(CopyOptions.LocalDevice)
                    }
                    .width('100%')
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)

                ListItemGroup() {
                    ListItem() {
                        WebLinkView({
                            url: 'https://jyutping.app',
                            icon: $r('sys.symbol.worldclock'),
                            text: $r('app.string.about_website')
                        })
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        WebLinkView({
                            url: 'https://github.com/yuetyam/jyutping-harmony',
                            icon: $r('sys.symbol.more'),
                            text: $r('app.string.about_source_code')
                        })
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        WebLinkView({
                            url: 'https://jyutping.app/harmony/privacy',
                            icon: $r('sys.symbol.lock'),
                            text: $r('app.string.about_privacy_policy')
                        })
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        WebLinkView({
                            url: 'https://jyutping.app/faq',
                            icon: $r('sys.symbol.questionmark_circle'),
                            text: $r('app.string.about_faq')
                        })
                    }
                }
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)

                ListItemGroup() {
                    ListItem() {
                        WebLinkView({
                            url: 'https://jq.qq.com/?k=4PR17m3t',
                            icon: $r('sys.symbol.person_2'),
                            text: $r('app.string.about_qq')
                        })
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        WebLinkView({
                            url: 'https://www.xiaohongshu.com/user/profile/62ee9df9000000001e01f5d6',
                            icon: $r('sys.symbol.book'),
                            text: $r('app.string.about_red_note')
                        })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        WebLinkView({
                            url: 'https://wj.qq.com/s2/14037245/fe08',
                            icon: $r('sys.symbol.checkmark_circle'),
                            text: $r('app.string.about_tencent_survey')
                        })
                    }
                }
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)

                /*
                ListItemGroup() {
                    ListItem() {
                        WebLinkView({
                            url: 'https://wj.qq.com/s2/14037245/fe08',
                            icon: $r('sys.symbol.checkmark_circle'),
                            text: $r('app.string.about_tencent_survey')
                        })
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        // FIXME: Email URL scheme
                        WebLinkView({
                            url: 'support@jyutping.app',
                            icon: $r('sys.symbol.envelope'),
                            text: $r('app.string.about_email')
                        })
                    }
                }
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)
                */
            }
            .padding({ left: 16, right: 16 })
            .width('100%')
            .height('100%')
        }
        .mode(NavigationMode.Stack)
        .title($r('app.string.tab_bar_about'))
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.window_background'))
    }
}
