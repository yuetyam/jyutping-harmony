import { NavigationLabel } from "./NavigationLabel";
import { WebLinkView } from "./WebLinkView";

@Component
export struct CantoneseScreen {
    private pageStack: NavPathStack = new NavPathStack();
    private groupBackgroundColor = $r('app.color.group_background');
    private groupBorderRadius: Length = 12;
    build() {
        Navigation(this.pageStack) {
            List({ space: 20 }) {
                ListItemGroup() {
                    ListItem() {
                        NavigationLabel({
                            icon: $r('sys.symbol.doc_text_badge_checkmark'),
                            text: $r('app.string.cantonese_expressions_label'),
                            action: () => {
                                this.pageStack.pushPathByName("ExpressionsPage", null, true)
                            }
                        })
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        NavigationLabel({
                            icon: $r('sys.symbol.character_square'),
                            text: $r('app.string.cantonese_confusion_label'),
                            action: () => {
                                this.pageStack.pushPathByName("ConfusionPage", null, true)
                            }
                        })
                    }
                }
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)

                ListItemGroup() {
                    ListItem() {
                        WebLinkView({
                            url: 'https://www.polyu.edu.hk/cbs/pronunciation',
                            icon: $r('sys.symbol.worldclock'),
                            text: '懶音診療室 - PolyU'
                        })
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        WebLinkView({
                            url: 'https://jyutping.org/blog/particles',
                            icon: $r('sys.symbol.worldclock'),
                            text: '粵語語氣詞'
                        })
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        WebLinkView({
                            url: 'https://www.classicalchineseliterature.org',
                            icon: $r('sys.symbol.worldclock'),
                            text: '中國古詩文精讀'
                        })
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        WebLinkView({
                            url: 'https://hambaanglaang.hk',
                            icon: $r('sys.symbol.worldclock'),
                            text: '冚唪唥粵文'
                        })
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        WebLinkView({
                            url: 'https://www.resonatehk.com',
                            icon: $r('sys.symbol.worldclock'),
                            text: '迴響'
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
        .title($r('app.string.tab_bar_cantonese'))
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.window_background'))
    }
}
