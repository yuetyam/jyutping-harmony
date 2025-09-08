import { bundleManager } from '@kit.AbilityKit';

@Component
export struct AboutScreen {
    private pageStack: NavPathStack = new NavPathStack();
    private groupBackgroundColor = $r('app.color.group_background');
    private groupBorderRadius: Length = 12;
    @State private version: string = '';
    aboutToAppear(): void {
        bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION).then((bundleInfo) => {
            this.version = bundleInfo.versionName + ` (${bundleInfo.versionCode})`
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

                ListItemGroup({ space: 8 }) {
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph($r('sys.symbol.worldclock'))
                                .fontSize(20)
                                .fontColor([$r('app.color.accent')])
                            Text('官网')
                            Blank()
                            SymbolGlyph($r('sys.symbol.arrow_up_right')).opacity(0.66)
                        }
                        .width('100%')
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph($r('sys.symbol.more'))
                                .fontSize(20)
                                .fontColor([$r('app.color.accent')])
                            Text('源码')
                            Blank()
                            SymbolGlyph($r('sys.symbol.arrow_up_right')).opacity(0.66)
                        }
                        .width('100%')
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph($r('sys.symbol.lock'))
                                .fontSize(20)
                                .fontColor([$r('app.color.accent')])
                            Text('隐私政策')
                            Blank()
                            SymbolGlyph($r('sys.symbol.arrow_up_right')).opacity(0.66)
                        }
                        .width('100%')
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph($r('sys.symbol.questionmark_circle'))
                                .fontSize(20)
                                .fontColor([$r('app.color.accent')])
                            Text('常问问题')
                            Blank()
                            SymbolGlyph($r('sys.symbol.arrow_up_right')).opacity(0.66)
                        }
                        .width('100%')
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)

                ListItemGroup({ space: 8 }) {
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph($r('sys.symbol.person_2'))
                                .fontSize(20)
                                .fontColor([$r('app.color.accent')])
                            Text('加入 QQ 交流群')
                            Blank()
                            SymbolGlyph($r('sys.symbol.arrow_up_right')).opacity(0.66)
                        }
                        .width('100%')
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph($r('sys.symbol.book'))
                                .fontSize(20)
                                .fontColor([$r('app.color.accent')])
                            Text('关注小红书')
                            Blank()
                            SymbolGlyph($r('sys.symbol.arrow_up_right')).opacity(0.66)
                        }
                        .width('100%')
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)

                ListItemGroup({ space: 8 }) {
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph($r('sys.symbol.checkmark_circle'))
                                .fontSize(20)
                                .fontColor([$r('app.color.accent')])
                            Text('腾讯问卷反馈')
                            Blank()
                            SymbolGlyph($r('sys.symbol.arrow_up_right')).opacity(0.66)
                        }
                        .width('100%')
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph($r('sys.symbol.envelope'))
                                .fontSize(20)
                                .fontColor([$r('app.color.accent')])
                            Text('邮件反馈')
                            Blank()
                            SymbolGlyph($r('sys.symbol.arrow_up_right')).opacity(0.66)
                        }
                        .width('100%')
                    }
                }
                .padding(8)
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
