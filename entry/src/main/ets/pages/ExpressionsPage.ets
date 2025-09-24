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
        .title("粤语用字参考")
    }
}
