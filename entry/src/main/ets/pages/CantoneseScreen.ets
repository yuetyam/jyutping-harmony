@Component
export struct CantoneseScreen {
    private pageStack: NavPathStack = new NavPathStack();
    private groupBackgroundColor = $r('app.color.group_background');
    private groupBorderRadius: Length = 12;
    build() {
        Navigation(this.pageStack) {
            List({ space: 20 }) {
                ListItemGroup({ space: 8 }) {
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph($r('sys.symbol.doc_text_badge_checkmark'))
                            Text('粤语用字参考')
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
                            SymbolGlyph($r('sys.symbol.character_square'))
                            Text('简化字易混淆情况')
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
        .title($r('app.string.tab_bar_cantonese'))
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.window_background'))
    }
}
