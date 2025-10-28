@ComponentV2
export default struct InputModeSwitch {
    @Param @Require isSwitched: boolean;
    build() {
        Stack({ alignContent: Alignment.Center }) {
            Stack({ alignContent: Alignment.Center }) {
                Stack({ alignContent: Alignment.Start }) {
                    Stack({ alignContent: Alignment.Center }) {
                        Text("粵")
                            .fontSize(this.isSwitched ? 14: 17)
                    }
                    .backgroundColor(this.isSwitched ? Color.Transparent : $r('app.color.key_shallow'))
                    .borderRadius('13.vp')
                    .width('36vp')
                    .height('100%')
                }
                .width('100%')
                .height('100%')
                Stack({ alignContent: Alignment.End }) {
                    Stack({ alignContent: Alignment.Center }) {
                        Text("A")
                            .fontSize(this.isSwitched ? 17: 14)
                    }
                    .backgroundColor(this.isSwitched ? $r('app.color.key_shallow') : Color.Transparent)
                    .borderRadius('13.vp')
                    .width('36vp')
                    .height('100%')
                }
                .width('100%')
                .height('100%')
            }
            .backgroundColor($r('app.color.key_emphatic'))
            .borderRadius('13.vp')
            .width('64vp')
            .height('26vp')
        }
        .width('100%')
        .height('100%')
    }
}
