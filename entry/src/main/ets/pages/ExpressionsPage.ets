@Builder
export function PageBuilder() {
    ExpressionsPage();
}

@Component
export struct ExpressionsPage {
    private groupBackgroundColor = $r('app.color.group_background');
    private groupBorderRadius: Length = 12;
    private checkmark = $r('sys.symbol.checkmark_circle');
    private xmark = $r('sys.symbol.xmark_circle');
    private infoMark = $r('sys.symbol.info_circle');
    private greenColor = [$r('app.color.green')];
    private redColor = [$r('app.color.red')];
    private orangeColor = [$r('app.color.orange')];
    build() {
        NavDestination() {
            List({ space: 20 }) {
                ListItemGroup({ space: 4 }) {
                    ListItem() {
                        Text("第一人稱代詞").fontWeight(FontWeight.Medium)
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph(this.checkmark)
                                .fontSize(20)
                                .fontColor(this.greenColor)
                            Text("單數：我")
                        }
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph(this.checkmark)
                                .fontSize(20)
                                .fontColor(this.greenColor)
                            Text("複數：我哋")
                        }
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph(this.xmark)
                                .fontSize(20)
                                .fontColor(this.redColor)
                            Text("咱、咱們")
                        }
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)
                ListItemGroup({ space: 4 }) {
                    ListItem() {
                        Text("第二人稱代詞").fontWeight(FontWeight.Medium)
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph(this.checkmark)
                                .fontSize(20)
                                .fontColor(this.greenColor)
                            Text("單數：你")
                        }
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph(this.checkmark)
                                .fontSize(20)
                                .fontColor(this.greenColor)
                            Text("複數：你哋")
                        }
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph(this.infoMark)
                                .fontSize(20)
                                .fontColor(this.orangeColor)
                            Text("如果要用敬詞，粵語一般用「閣下」。「您」係北京方言用字，好少見於其他漢語。").width('90%')
                        }
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph(this.infoMark)
                                .fontSize(20)
                                .fontColor(this.orangeColor)
                            Text("冇必要畫蛇添足用「妳」。")
                        }
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)
                ListItemGroup({ space: 4 }) {
                    ListItem() {
                        Text("第三人稱代詞").fontWeight(FontWeight.Medium)
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph(this.checkmark)
                                .fontSize(20)
                                .fontColor(this.greenColor)
                            Text("單數：佢")
                        }
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph(this.checkmark)
                                .fontSize(20)
                                .fontColor(this.greenColor)
                            Text("複數：佢哋")
                        }
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph(this.infoMark)
                                .fontSize(20)
                            Text("無論性別、人、物，一律用佢。").width('85%')
                        }
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph(this.infoMark)
                                .fontSize(20)
                            Text("佢 亦作 渠、{⿰亻渠}")
                        }
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
        .title($r('app.string.cantonese_expressions_title'))
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.window_background'))
    }
}
