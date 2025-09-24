@Component
export struct NavigationLabel {
    icon: Resource | undefined = undefined;
    text: string | Resource = 'placeholder';
    action: () => void = () => {};
    build() {
        Button() {
            Row({ space: 12 }) {
                SymbolGlyph(this.icon)
                    .fontSize(20)
                    .fontColor([$r('app.color.accent')])
                Text(this.text)
                Blank()
                SymbolGlyph($r('sys.symbol.chevron_forward'))
                    .fontColor([$r('sys.color.ohos_id_color_primary')])
                    .opacity(0.66)
            }
            .padding(8)
            .width('100%')
        }
        .backgroundColor(Color.Transparent)
        .onClick((event: ClickEvent) => {
            if (event) {
                this.action()
            }
        })
    }
}
