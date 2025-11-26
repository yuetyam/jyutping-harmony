@ComponentV2
export default struct InputModeSwitch {
    @Param @Require isCantoneseMode: boolean;
    @Param @Require isMutilated: boolean;
    build() {
        Stack({ alignContent: Alignment.Center }) {
            Stack({ alignContent: Alignment.Center }) {
                Stack({ alignContent: Alignment.Start }) {
                    Stack({ alignContent: Alignment.Center }) {
                        Text(this.isMutilated ? "粤" : "粵")
                            .fontSize(this.isCantoneseMode ? 17: 13)
                            .padding({ right: this.isCantoneseMode ? 0 : 4 })
                    }
                    .backgroundColor(this.isCantoneseMode ? $r('app.color.key_shallow') : Color.Transparent)
                    .borderRadius('13.vp')
                    .width('36vp')
                    .height('100%')
                }
                .width('100%')
                .height('100%')
                Stack({ alignContent: Alignment.End }) {
                    Stack({ alignContent: Alignment.Center }) {
                        Text("A")
                            .fontSize(this.isCantoneseMode ? 13: 17)
                            .padding({ left: this.isCantoneseMode ? 4 : 0 })
                    }
                    .backgroundColor(this.isCantoneseMode ? Color.Transparent : $r('app.color.key_shallow'))
                    .borderRadius('13.vp')
                    .width('36vp')
                    .height('100%')
                }
                .width('100%')
                .height('100%')
            }
            .backgroundColor($r('app.color.key_emphatic'))
            .borderRadius('13.vp')
            .width('60vp')
            .height('26vp')
        }
        .width('100%')
        .height('100%')
    }
}
