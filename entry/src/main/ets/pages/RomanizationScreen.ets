@Component
export struct RomanizationScreen {
    private pageStack: NavPathStack = new NavPathStack();

    build() {
        Navigation(this.pageStack) {
            List({ space: 16 }) {
                ListItemGroup() {
                    ListItem() {
                        Row({ space: 16 }) {
                            SymbolGlyph($r('sys.symbol.list_bullet')).fontColor([$r('sys.color.ohos_id_color_primary')])
                            Text('粵拼聲母表')
                            Blank()
                        }
                    }
                    .padding({ top: 8, bottom: 8 })

                    ListItem() {
                        Divider()
                    }

                    ListItem() {
                        Row({ space: 16 }) {
                            SymbolGlyph($r('sys.symbol.list_bullet')).fontColor([$r('sys.color.ohos_id_color_primary')])
                            Text('粵拼韻母表')
                            Blank()
                        }
                    }
                    .padding({ top: 8, bottom: 8 })

                    ListItem() {
                        Divider()
                    }

                    ListItem() {
                        Row({ space: 16 }) {
                            SymbolGlyph($r('sys.symbol.bell')).fontColor([$r('sys.color.ohos_id_color_primary')])
                            Text('粵拼聲調表')
                            Blank()
                        }
                    }
                    .padding({ top: 8, bottom: 8 })
                }
                .padding({ left: 8, right: 8 })
                .backgroundColor($r('app.color.group_background'))
                .borderRadius(10)
                .margin({ left: 16, right: 16 })
            }
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
