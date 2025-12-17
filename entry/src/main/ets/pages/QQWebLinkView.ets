import { common, Want } from '@kit.AbilityKit';

@ComponentV2
export struct QQWebLinkView {
    build() {
        Button() {
            Row({ space: 12 }) {
                SymbolGlyph($r('sys.symbol.person_2'))
                    .fontSize(20)
                    .fontColor([$r('app.color.accent')])
                Text($r('app.string.about_qq'))
                Text('( 293148593 )')
                    .fontSize(13)
                    .opacity(0.85)
                Blank()
                SymbolGlyph($r('sys.symbol.arrow_right_up_and_square'))
                    .fontColor([$r('sys.color.ohos_id_color_primary')])
                    .opacity(0.66)
            }
            .padding(8)
            .width('100%')
        }
        .backgroundColor(Color.Transparent)
        .onClick(() => {
            let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
            let want: Want = {
                action: 'ohos.want.action.viewData',
                entities: ['entity.system.browsable'],
                abilityName: 'MainAbility',
                uri: 'https://jq.qq.com/?k=4PR17m3t'
            }
            context.startAbility(want).catch(() => {
                // TODO: Implement error handling.
            });
        })
    }
}
