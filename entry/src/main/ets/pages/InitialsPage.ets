@Builder
export function PageBuilder() {
    InitialsPage();
}

@Component
export struct InitialsPage {
    private groupBackgroundColor = $r('app.color.group_background');
    private groupBorderRadius: Length = 12;

    build() {
        NavDestination() {
            List({ space: 20 }) {
                ListItemGroup({ space: 4 }) {
                    ListItem() {
                        InitialLabel({ word: "巴", syllable: "baa1", jyutping: "b", ipa: "[ p ]" })
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        InitialLabel({ word: "趴", syllable: "paa1", jyutping: "p", ipa: "[ pʰ ]" })
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        InitialLabel({ word: "媽", syllable: "maa1", jyutping: "m", ipa: "[ m ]" })
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        InitialLabel({ word: "花", syllable: "faa1", jyutping: "f", ipa: "[ f ]" })
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)
                ListItemGroup({ space: 4 }) {
                    ListItem() {
                        Text("打 baa2")
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        Text("他 taa1")
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        Text("拿 naa4")
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        Text("啦 laa1")
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)
            }
            .padding({ left: 16, right: 16 })
            .width('100%')
            .height('100%')
        }
        .title($r('app.string.romanization_initials_title'))
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.window_background'))
    }
}

@ComponentV2
struct InitialLabel {
    @Param @Require @Once word: string;
    @Param @Require @Once syllable: string;
    @Param @Require @Once jyutping: string;
    @Param @Require @Once ipa: string;
    build() {
        Row({ space: 32 }) {
            Text(this.word + " " + this.syllable)
            Text(this.jyutping)
            Text(this.ipa)
        }
        .width('100%')
    }
}
