@Builder
export function PageBuilder() {
    InitialsPage();
}

@Component
export struct InitialsPage {
    private groupBackgroundColor = $r('app.color.group_background');
    private groupBorderRadius: Length = 12;

    build() {
        NavDestination() {
            List({ space: 20 }) {
                ListItemGroup({ space: 4 }) {
                    ListItem() {
                        Text("巴 baa1")
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        Text("趴 paa1")
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        Text("媽 maa1")
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        Text("花 faa1")
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)
                ListItemGroup({ space: 4 }) {
                    ListItem() {
                        Text("打 baa2")
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        Text("他 taa1")
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        Text("拿 naa4")
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        Text("啦 laa1")
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
        .title("粤拼声母表")
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.window_background'))
    }
}
