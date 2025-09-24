@Builder
export function PageBuilder() {
    FinalsPage();
}

@Component
export struct FinalsPage {
    build() {
        NavDestination() {
            Column() {
                Text("Jyutping Finals")
            }
            .width('100%')
            .height('100%')
        }
        .title($r('app.string.romanization_finals_title'))
    }
}
