@Builder
export function PageBuilder() {
    FinalsPage();
}

@Component
export struct FinalsPage {
    private groupBackgroundColor = $r('app.color.group_background');
    private groupBorderRadius: Length = 12;
    build() {
        NavDestination() {
            List({ space: 8 }) {
                ListItem() {
                    Row() {
                        Text("例字").width('35%')
                        Text("韻母").width('25%')
                        Text("國際音標")
                    }
                    .width('100%')
                }
                .padding({ left: 8, right: 8 })
                ListItemGroup({ space: 4 }) {
                    ListItem() {
                        FinalLabel({ word: "駕", syllable: "gaa3", jyutping: "aa", ipa: "[ aː ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "界", syllable: "gaai3", jyutping: "aai", ipa: "[ aːi ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "教", syllable: "gaau3", jyutping: "aau", ipa: "[ aːu ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "鑑", syllable: "gaam3", jyutping: "aam", ipa: "[ aːm ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "諫", syllable: "gaan3", jyutping: "aan", ipa: "[ aːn ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "耕", syllable: "gaang1", jyutping: "aang", ipa: "[ aːŋ ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "甲", syllable: "gaap3", jyutping: "aap", ipa: "[ aːp̚ ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "戛", syllable: "gaat3", jyutping: "aat", ipa: "[ aːt̚ ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "格", syllable: "gaak3", jyutping: "aak", ipa: "[ aːk̚ ]" })
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)
                ListItemGroup({ space: 4 }) {
                    ListItem() {
                        FinalLabel({ word: "㗎", syllable: "ga3", jyutping: "a", ipa: "[ ɐ ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "計", syllable: "gai3", jyutping: "ai", ipa: "[ ɐi ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "救", syllable: "gau3", jyutping: "au", ipa: "[ ɐu ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "禁", syllable: "gam3", jyutping: "am", ipa: "[ ɐm ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "斤", syllable: "gan1", jyutping: "an", ipa: "[ ɐn ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "庚", syllable: "gang1", jyutping: "ang", ipa: "[ ɐŋ ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "急", syllable: "gap1", jyutping: "ap", ipa: "[ ɐp̚ ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "吉", syllable: "gat1", jyutping: "at", ipa: "[ ɐt̚ ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "北", syllable: "bak1", jyutping: "ak", ipa: "[ ɐk̚ ]" })
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)
                ListItemGroup({ space: 4 }) {
                    ListItem() {
                        FinalLabel({ word: "嘅", syllable: "ge3", jyutping: "e", ipa: "[ ɛː ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "記", syllable: "gei3", jyutping: "ei", ipa: "[ ei ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "掉", syllable: "deu6", jyutping: "eu", ipa: "[ ɛːu ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "𦧷", syllable: "lem2", jyutping: "em", ipa: "[ ɛːm ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "鏡", syllable: "geng3", jyutping: "eng", ipa: "[ ɛːŋ ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "夾", syllable: "gep6", jyutping: "ep", ipa: "[ ɛːp̚ ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "坺", syllable: "pet6", jyutping: "et", ipa: "[ ɛːt̚ ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "踢", syllable: "tek3", jyutping: "ek", ipa: "[ ɛːk̚ ]" })
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)
                ListItemGroup({ space: 4 }) {
                    ListItem() {
                        FinalLabel({ word: "意", syllable: "ji3", jyutping: "i", ipa: "[ iː ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "叫", syllable: "giu3", jyutping: "iu", ipa: "[ iːu ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "劍", syllable: "gim3", jyutping: "im", ipa: "[ iːm ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "見", syllable: "gin3", jyutping: "in", ipa: "[ iːn ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "敬", syllable: "ging3", jyutping: "ing", ipa: "[ eŋ ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "劫", syllable: "gip3", jyutping: "ip", ipa: "[ iːp̚ ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "結", syllable: "git3", jyutping: "it", ipa: "[ iːt̚ ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "極", syllable: "gik6", jyutping: "ik", ipa: "[ ek̚ ]" })
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)
                ListItemGroup({ space: 4 }) {
                    ListItem() {
                        FinalLabel({ word: "個", syllable: "go3", jyutping: "o", ipa: "[ ɔː ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "蓋", syllable: "goi3", jyutping: "oi", ipa: "[ ɔːi ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "告", syllable: "gou3", jyutping: "ou", ipa: "[ ou ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "幹", syllable: "gon3", jyutping: "on", ipa: "[ ɔːn ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "鋼", syllable: "gong3", jyutping: "ong", ipa: "[ ɔːŋ ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "割", syllable: "got3", jyutping: "ot", ipa: "[ ɔːt̚ ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "各", syllable: "gok3", jyutping: "ok", ipa: "[ ɔːk̚ ]" })
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)
                ListItemGroup({ space: 4 }) {
                    ListItem() {
                        FinalLabel({ word: "夫", syllable: "fu1", jyutping: "u", ipa: "[ uː ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "灰", syllable: "fui1", jyutping: "ui", ipa: "[ uːi ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "寬", syllable: "fun1", jyutping: "un", ipa: "[ uːn ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "封", syllable: "fung1", jyutping: "ung", ipa: "[ oŋ ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "闊", syllable: "fut3", jyutping: "ut", ipa: "[ uːt̚ ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "福", syllable: "fuk1", jyutping: "uk", ipa: "[ ok̚ ]" })
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)
                ListItemGroup({ space: 4 }) {
                    ListItem() {
                        FinalLabel({ word: "鋸", syllable: "goe3", jyutping: "oe", ipa: "[ œː ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "姜", syllable: "goeng1", jyutping: "oeng", ipa: "[ œːŋ ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "*", syllable: "goet4", jyutping: "oet", ipa: "[ œːt̚ ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "腳", syllable: "goek3", jyutping: "oek", ipa: "[ œːk̚ ]" })
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)
                ListItemGroup({ space: 4 }) {
                    ListItem() {
                        FinalLabel({ word: "歲", syllable: "seoi3", jyutping: "eoi", ipa: "[ ɵy ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "信", syllable: "seon3", jyutping: "eon", ipa: "[ ɵn ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "術", syllable: "seot6", jyutping: "eot", ipa: "[ ɵt̚ ]" })
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)
                ListItemGroup({ space: 4 }) {
                    ListItem() {
                        FinalLabel({ word: "恕", syllable: "syu3", jyutping: "yu", ipa: "[ yː ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "算", syllable: "syun3", jyutping: "yun", ipa: "[ yːn ]" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        FinalLabel({ word: "雪", syllable: "syut3", jyutping: "yut", ipa: "[ yːt̚ ]" })
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)
                ListItemGroup({ space: 4 }) {
                    FinalLabel({ word: "唔", syllable: "m4", jyutping: "m", ipa: "[ m̩ ]" })
                    FinalLabel({ word: "吳", syllable: "ng4", jyutping: "ng", ipa: "[ ŋ̩ ]" })
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)
            }
            .padding({ left: 16, right: 16 })
            .width('100%')
            .height('100%')
        }
        .title($r('app.string.romanization_finals_title'))
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.window_background'))
    }
}

@ComponentV2
struct FinalLabel {
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
