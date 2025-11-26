@ComponentV2
export default struct CharacterSetSwitch {
    @Param @Require isMutilated: boolean;
    build() {
        Stack({ alignContent: Alignment.Center }) {
            Stack({ alignContent: Alignment.Center }) {
                Stack({ alignContent: Alignment.Start }) {
                    Stack({ alignContent: Alignment.Center }) {
                        Text("繁")
                            .fontSize(this.isMutilated ? 12: 16)
                            .padding({ right: this.isMutilated ? 4 : 0 })
                    }
                    .backgroundColor(this.isMutilated ? Color.Transparent : $r('app.color.key_shallow'))
                    .borderRadius('13.vp')
                    .width('28vp')
                    .height('100%')
                }
                .width('100%')
                .height('100%')
                Stack({ alignContent: Alignment.End }) {
                    Stack({ alignContent: Alignment.Center }) {
                        Text("简")
                            .fontSize(this.isMutilated ? 16: 12)
                            .padding({ left: this.isMutilated ? 0 : 4 })
                    }
                    .backgroundColor(this.isMutilated ? $r('app.color.key_shallow') : Color.Transparent)
                    .borderRadius('13.vp')
                    .width('28vp')
                    .height('100%')
                }
                .width('100%')
                .height('100%')
            }
            .backgroundColor($r('app.color.key_emphatic'))
            .borderRadius('13.vp')
            .width('48vp')
            .height('26vp')
        }
        .width('100%')
        .height('100%')
    }
}
