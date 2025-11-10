@Builder
export function PageBuilder() {
    TonesPage();
}

@Component
export struct TonesPage {
    private groupBackgroundColor = $r('app.color.group_background');
    private groupBorderRadius: Length = 12;
    build() {
        NavDestination() {
            List({ space: 8 }) {
                ListItem() {
                    Row() {
                        Text("例字").width('30%')
                        Text("聲調").width('30%')
                        Text("調值")
                    }
                    .width('100%')
                }
                .padding({ left: 8, right: 8 })
                ListItemGroup({ space: 4 }) {
                    ListItem() {
                        ToneLabel({ word: "分", syllable: "fan1", name: "陰平", value: "55 / 53" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        ToneLabel({ word: "粉", syllable: "fan2", name: "陰上", value: "35" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        ToneLabel({ word: "糞", syllable: "fan3", name: "陰去", value: "33" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        ToneLabel({ word: "焚", syllable: "fan4", name: "陽平", value: "21 / 11" })
                    }
                    ListItem() {
                        ToneLabel({ word: "憤", syllable: "fan5", name: "陽上", value: "13 / 23" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        ToneLabel({ word: "份", syllable: "fan6", name: "陽去", value: "22" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        ToneLabel({ word: "弗", syllable: "fat1", name: "高陰入", value: "5" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        ToneLabel({ word: "法", syllable: "faat3", name: "低陰入", value: "3" })
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        ToneLabel({ word: "佛", syllable: "fat6", name: "陽入", value: "2" })
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
        .title($r('app.string.romanization_tones_title'))
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.window_background'))
    }
}

@ComponentV2
struct ToneLabel {
    @Param @Require @Once word: string;
    @Param @Require @Once syllable: string;
    @Param @Require @Once name: string;
    @Param @Require @Once value: string;
    build() {
        Row() {
            Text(this.word + " " + this.syllable).width('30%')
            Text(this.name).width('30%')
            Text(this.value)
        }
        .width('100%')
    }
}
