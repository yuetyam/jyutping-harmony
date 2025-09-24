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
        .title($r('app.string.cantonese_confusion_title'))
    }
}
