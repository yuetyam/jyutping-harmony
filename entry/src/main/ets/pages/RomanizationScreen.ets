import { NavigationLabel } from "./NavigationLabel";

@Component
export struct RomanizationScreen {
    private pageStack: NavPathStack = new NavPathStack();
    private groupBackgroundColor = $r('app.color.group_background');
    private groupBorderRadius: Length = 12;
    build() {
        Navigation(this.pageStack) {
            List({ space: 16 }) {
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
