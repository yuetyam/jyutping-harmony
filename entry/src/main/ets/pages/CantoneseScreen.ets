import { NavigationLabel } from "./NavigationLabel";

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
                            text: "粤语用字参考",
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
                            text: "简化字易混淆情况",
                            action: () => {
                                this.pageStack.pushPathByName("ConfusionPage", null, true)
                            }
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
