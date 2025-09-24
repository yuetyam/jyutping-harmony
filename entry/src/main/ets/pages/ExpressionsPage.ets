@Builder
export function PageBuilder() {
    ExpressionsPage();
}

@Component
export struct ExpressionsPage {
    build() {
        NavDestination() {
            Column() {
                Text("Cantonese Expressions")
            }
            .width('100%')
            .height('100%')
        }
        .title($r('app.string.cantonese_expressions_title'))
    }
}
