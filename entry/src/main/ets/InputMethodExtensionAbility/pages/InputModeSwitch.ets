@Component
export default struct InputModeSwitch {
    @Prop isSwitched: boolean | undefined = undefined;
    build() {
        Stack() {
            Button() {
                Row() {
                    Row() {
                        Text("粵")
                    }
                    .justifyContent(FlexAlign.Center)
                    .backgroundColor(this.isSwitched ? Color.Transparent : $r('app.color.key_shallow'))
                    .borderRadius('13.vp')
                    .width('34vp')
                    .height('100%')
                    Row() {
                        Text("A")
                    }
                    .justifyContent(FlexAlign.Center)
                    .backgroundColor(this.isSwitched ? $r('app.color.key_shallow') : Color.Transparent)
                    .borderRadius('13.vp')
                    .width('34vp')
                    .height('100%')
                }
                .backgroundColor($r('app.color.key_emphatic'))
                .borderRadius('13.vp')
                .width('68vp')
                .height('26vp')
            }
            .backgroundColor(Color.Transparent)
            .width('70vp')
            .height('28vp')
        }
        .width('100%')
        .height('100%')
    }
}
