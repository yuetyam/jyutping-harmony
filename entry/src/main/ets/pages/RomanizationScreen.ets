import { NavigationLabel } from "./NavigationLabel";
import { WebLinkView } from "./WebLinkView";

@Component
export struct RomanizationScreen {
    private pageStack: NavPathStack = new NavPathStack();
    private groupBackgroundColor = $r('app.color.group_background');
    private groupBorderRadius: Length = 12;
    build() {
        Navigation(this.pageStack) {
            List({ space: 20 }) {
                ListItemGroup() {
                    ListItem() {
                        NavigationLabel({
                            icon: $r('sys.symbol.list_bullet'),
                            text: "粵拼聲母表",
                            action: () => {
                                this.pageStack.pushPathByName("InitialsPage", null, true)
                            }
                        })
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        NavigationLabel({
                            icon: $r('sys.symbol.list_bullet'),
                            text: "粤拼韵母表",
                            action: () => {
                                this.pageStack.pushPathByName("FinalsPage", null, true)
                            }
                        })
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        NavigationLabel({
                            icon: $r('sys.symbol.bell'),
                            text: "粤拼声调表",
                            action: () => {
                                this.pageStack.pushPathByName("TonesPage", null, true)
                            }
                        })
                    }
                }
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)

                ListItemGroup() {
                    ListItem() {
                        WebLinkView({
                            url: 'https://jyut.net',
                            icon: $r('sys.symbol.doc_text_badge_magnifyingglass'),
                            text: '粵音資料集叢'
                        })
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        WebLinkView({
                            url: 'https://words.hk',
                            icon: $r('sys.symbol.doc_text_badge_magnifyingglass'),
                            text: '粵典'
                        })
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        WebLinkView({
                            url: 'https://humanum.arts.cuhk.edu.hk/Lexis/lexi-can',
                            icon: $r('sys.symbol.doc_text_badge_magnifyingglass'),
                            text: '粵語審音配詞字庫'
                        })
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        WebLinkView({
                            url: 'https://shyyp.net/hant',
                            icon: $r('sys.symbol.doc_text_badge_magnifyingglass'),
                            text: '羊羊粵語'
                        })
                    }
                }
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)

                ListItemGroup() {
                    ListItem() {
                        WebLinkView({
                            url: 'https://jyutping.org',
                            icon: $r('sys.symbol.worldclock'),
                            text: '粵拼 Jyutping'
                        })
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        WebLinkView({
                            url: 'https://www.ilc.cuhk.edu.hk/workshop/Chinese/Cantonese/Romanization',
                            icon: $r('sys.symbol.worldclock'),
                            text: '粵語拼音速遞 - CUHK'
                        })
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        WebLinkView({
                            url: 'https://www.ilc.cuhk.edu.hk/workshop/Chinese/Cantonese/OnlineTutorial',
                            icon: $r('sys.symbol.worldclock'),
                            text: '粵語網路課堂 - CUHK'
                        })
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        WebLinkView({
                            url: 'https://www.polyu.edu.hk/clc/cantonese/home',
                            icon: $r('sys.symbol.worldclock'),
                            text: '翻轉粵語教室 - PolyU'
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
        .title($r('app.string.tab_bar_romanization'))
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.window_background'))
    }
}
