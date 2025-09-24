import { common, Want } from '@kit.AbilityKit'

@Component
export struct WebLinkView {
    url: string = 'https://jyutping.app';
    icon: Resource | undefined = undefined;
    text: string | Resource = 'placeholder';
    build() {
        Button() {
            Row({ space: 12 }) {
                SymbolGlyph(this.icon)
                    .fontSize(20)
                    .fontColor([$r('app.color.accent')])
                Text(this.text)
                Blank()
                SymbolGlyph($r('sys.symbol.arrow_up_right'))
                    .fontColor([$r('sys.color.ohos_id_color_primary')])
                    .opacity(0.66)
            }
            .padding(8)
            .width('100%')
        }
        .backgroundColor(Color.Transparent)
        .onClick((event: ClickEvent) => {
            if (event) {
                let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
                let want: Want = {
                    action: 'ohos.want.action.viewData',
                    entities: ['entity.system.browsable'],
                    abilityName: 'MainAbility',
                    uri: this.url
                }
                context.startAbility(want).catch(() => {
                    // TODO: Implement error handling.
                })
            }
        })
    }
}
