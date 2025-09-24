@Builder
export function PageBuilder() {
    TonesPage();
}

@Component
export struct TonesPage {
    build() {
        NavDestination() {
            Column() {
                Text("Jyutping Tones")
            }
            .width('100%')
            .height('100%')
        }
        .title($r('app.string.romanization_tones_title'))
    }
}
