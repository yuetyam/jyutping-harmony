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
            List({ space: 8 }) {
                ListItem() {
                    Row() {
                        Text("例字").width('35%')
                        Text("聲母").width('25%')
                        Text("國際音標")
                    }
                    .width('100%')
                }
                .padding({ left: 8, right: 8 })
                ListItemGroup({ space: 4 }) {
                    ListItem() {
                        InitialLabel({ word: "巴", syllable: "baa1", jyutping: "b", ipa: "[ p ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        InitialLabel({ word: "趴", syllable: "paa1", jyutping: "p", ipa: "[ pʰ ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        InitialLabel({ word: "媽", syllable: "maa1", jyutping: "m", ipa: "[ m ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        InitialLabel({ word: "花", syllable: "faa1", jyutping: "f", ipa: "[ f ]" })
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)
                ListItemGroup({ space: 4 }) {
                    ListItem() {
                        InitialLabel({ word: "打", syllable: "daa2", jyutping: "d", ipa: "[ t ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        InitialLabel({ word: "他", syllable: "taa1", jyutping: "t", ipa: "[ tʰ ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        InitialLabel({ word: "拿", syllable: "naa4", jyutping: "n", ipa: "[ n ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        InitialLabel({ word: "啦", syllable: "laa1", jyutping: "l", ipa: "[ l ]" })
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)
                ListItemGroup({ space: 4 }) {
                    ListItem() {
                        InitialLabel({ word: "家", syllable: "gaa1", jyutping: "g", ipa: "[ k ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        InitialLabel({ word: "卡", syllable: "kaa1", jyutping: "k", ipa: "[ kʰ ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        InitialLabel({ word: "蝦", syllable: "haa1", jyutping: "h", ipa: "[ h ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        InitialLabel({ word: "牙", syllable: "ngaa4", jyutping: "ng", ipa: "[ ŋ ]" })
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)
                ListItemGroup({ space: 4 }) {
                    ListItem() {
                        InitialLabel({ word: "瓜", syllable: "gwaa1", jyutping: "gw", ipa: "[ kʷ ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        InitialLabel({ word: "夸", syllable: "kwaa1", jyutping: "kw", ipa: "[ kʷʰ ]" })
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)
                ListItemGroup({ space: 4 }) {
                    ListItem() {
                        InitialLabel({ word: "渣", syllable: "zaa1", jyutping: "z", ipa: "t͡s ~ t͡ʃ" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        InitialLabel({ word: "叉", syllable: "caa1", jyutping: "c", ipa: "t͡sʰ ~ t͡ʃʰ" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        InitialLabel({ word: "沙", syllable: "saa1", jyutping: "s", ipa: "s ~ ʃ" })
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)
                ListItemGroup({ space: 4 }) {
                    ListItem() {
                        InitialLabel({ word: "蛙", syllable: "waa1", jyutping: "w", ipa: "[ w ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        InitialLabel({ word: "也", syllable: "jaa5", jyutping: "j", ipa: "[ j ]" })
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
        Row() {
            Text(this.word + " " + this.syllable).width('35%')
            Text(this.jyutping).width('25%')
            Text(this.ipa)
        }
        .width('100%')
    }
}
