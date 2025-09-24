@Component
export struct RomanizationScreen {
    private pageStack: NavPathStack = new NavPathStack();
    private groupBackgroundColor = $r('app.color.group_background');
    private groupBorderRadius: Length = 12;
    build() {
        Navigation(this.pageStack) {
            List({ space: 16 }) {
                ListItemGroup({ space: 8 }) {
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph($r('sys.symbol.list_bullet')).fontColor([$r('sys.color.ohos_id_color_primary')])
                            Text('粵拼聲母表')
                            Blank()
                            SymbolGlyph($r('sys.symbol.chevron_forward')).opacity(0.66)
                        }
                        .width('100%')
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph($r('sys.symbol.list_bullet')).fontColor([$r('sys.color.ohos_id_color_primary')])
                            Text('粵拼韻母表')
                            Blank()
                            SymbolGlyph($r('sys.symbol.chevron_forward')).opacity(0.66)
                        }
                        .width('100%')
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph($r('sys.symbol.bell')).fontColor([$r('sys.color.ohos_id_color_primary')])
                            Text('粵拼聲調表')
                            Blank()
                            SymbolGlyph($r('sys.symbol.chevron_forward')).opacity(0.66)
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
        .title($r('app.string.tab_bar_romanization'))
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.window_background'))
    }
}
