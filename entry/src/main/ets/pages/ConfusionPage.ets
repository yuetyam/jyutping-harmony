@Builder
export function PageBuilder() {
    ConfusionPage();
}

@Component
export struct ConfusionPage {
    build() {
        NavDestination() {
            Column() {
                Text("Confusion")
            }
            .width('100%')
            .height('100%')
        }
        .title("简化字易混淆情况")
    }
}
