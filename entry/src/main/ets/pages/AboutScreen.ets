import { bundleManager } from '@kit.AbilityKit';
import { WebLinkView } from './WebLinkView';

@Component
export struct AboutScreen {
    private pageStack: NavPathStack = new NavPathStack();
    private groupBackgroundColor = $r('app.color.group_background');
    private groupBorderRadius: Length = 12;
    @State private version: string = 'error';
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
                        Text('版本')
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
                            text: '官网'
                        })
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        WebLinkView({
                            url: 'https://github.com/yuetyam/jyutping-harmony',
                            icon: $r('sys.symbol.more'),
                            text: '源码'
                        })
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        WebLinkView({
                            url: 'https://jyutping.app/privacy',
                            icon: $r('sys.symbol.lock'),
                            text: '隐私政策'
                        })
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        WebLinkView({
                            url: 'https://jyutping.app/faq',
                            icon: $r('sys.symbol.questionmark_circle'),
                            text: '常问问题'
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
                            text: '加入 QQ 交流群'
                        })
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        WebLinkView({
                            url: 'https://www.xiaohongshu.com/user/profile/62ee9df9000000001e01f5d6',
                            icon: $r('sys.symbol.book'),
                            text: '关注小红书'
                        })
                    }
                }
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)

                ListItemGroup() {
                    ListItem() {
                        WebLinkView({
                            url: 'https://wj.qq.com/s2/14037245/fe08',
                            icon: $r('sys.symbol.checkmark_circle'),
                            text: '腾讯问卷反馈'
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
                            text: '邮件反馈'
                        })
                    }
                }
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)
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
