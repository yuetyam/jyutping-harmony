import inputController from '../model/InputController'

@Component
export default struct LetterKey {
    keyText: string = 'a';
    build() {
        Column() {
            Flex({
                direction: FlexDirection.Column,
                alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center
            }) {
                Text(this.keyText)
                    .fontSize(20)
            }
        }
        .backgroundColor(Color.White)
        .borderRadius(6)
        .width("8%")
        .height("65%")
        .onClick((event?: ClickEvent) => {
            inputController.insertText(this.keyText);
        })
    }
}
