import { common, Want } from '@kit.AbilityKit'

@ComponentV2
export struct WebLinkView {
    @Param @Require @Once url: string;
    @Param @Require @Once icon: Resource;
    @Param @Require @Once text: Resource | string;
    build() {
        Button() {
            Row({ space: 12 }) {
                SymbolGlyph(this.icon)
                    .fontSize(20)
                    .fontColor([$r('app.color.accent')])
                Text(this.text)
                Blank()
                SymbolGlyph($r('sys.symbol.arrow_right_up_and_square'))
                    .fontColor([$r('sys.color.ohos_id_color_primary')])
                    .opacity(0.66)
            }
            .padding(8)
            .width('100%')
        }
        .backgroundColor(Color.Transparent)
        .onClick((event: ClickEvent) => {
            let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
            let want: Want = {
                action: 'ohos.want.action.viewData',
                entities: ['entity.system.browsable'],
                abilityName: 'MainAbility',
                uri: this.url
            }
            context.startAbility(want).catch(() => {
                // TODO: Implement error handling.
            });
        })
    }
}
