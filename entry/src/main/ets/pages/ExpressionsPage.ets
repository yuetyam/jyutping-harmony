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
                        Text("第一人稱代詞").fontWeight(FontWeight.Bold)
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
                        Text("第二人稱代詞").fontWeight(FontWeight.Bold)
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
                        Text("第三人稱代詞").fontWeight(FontWeight.Bold)
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
                            Text("無論性別、人、物，一律用佢。")
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
                ListItemGroup({ space: 4 }) {
                    ListItem() {
                        Text("區分【係】以及【喺】").fontWeight(FontWeight.Bold)
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Text("係 hai6 : 謂語，義同「是」。")
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Text("喺 hai2 : 表方位、時間，義同「在」。")
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Text("例：我係曹阿瞞。")
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Text("例：我喺赤壁遊山玩水。")
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)
                ListItemGroup({ space: 4 }) {
                    ListItem() {
                        Text("區分【諗】以及【冧】").fontWeight(FontWeight.Bold)
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Text("諗 nam2 : 想、思考、覺得")
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Text("冧 lam3 : 表示倒塌、倒下")
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Text("例：我諗緊今晚食咩。")
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Text("例：佢畀人㨃冧咗。")
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)
                ListItemGroup({ space: 4 }) {
                    ListItem() {
                        Text("區分【咁】以及【噉】").fontWeight(FontWeight.Bold)
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Text("咁 gam3 : 音同「禁」")
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Text("噉 gam2 : 音同「感」")
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Text("例：我生得咁靚仔。")
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Text("例：噉又未必。")
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)
                ListItemGroup({ space: 4 }) {
                    ListItem() {
                        Text("區分【會】以及【識】").fontWeight(FontWeight.Bold)
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Text("會：位於動詞前，將要做某事。")
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Text("識：識得；曉得；懂得；明白。")
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Text("例：我會煮飯。（我將要煮飯。）")
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Text("例：我識煮飯。（我懂得如何煮飯。）")
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)
                ListItemGroup({ space: 4 }) {
                    ListItem() {
                        Text("啩、啊嘛").fontWeight(FontWeight.Bold)
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph(this.checkmark)
                                .fontSize(20)
                                .fontColor(this.greenColor)
                            Text("下個禮拜會出啩。")
                        }
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph(this.checkmark)
                                .fontSize(20)
                                .fontColor(this.greenColor)
                            Text("唔係啊嘛，真係冇？")
                        }
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph(this.xmark)
                                .fontSize(20)
                                .fontColor(this.redColor)
                            Text("下個禮拜會出吧。")
                        }
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph(this.xmark)
                                .fontSize(20)
                                .fontColor(this.redColor)
                            Text("唔係吧，真係冇？")
                        }
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)
                ListItemGroup({ space: 4 }) {
                    ListItem() {
                        Text("喇、嘞").fontWeight(FontWeight.Bold)
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph(this.checkmark)
                                .fontSize(20)
                                .fontColor(this.greenColor)
                            Text("我識用粵拼打字喇！")
                        }
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph(this.checkmark)
                                .fontSize(20)
                                .fontColor(this.greenColor)
                            Text("係嘞，你試過粵拼輸入法未啊？")
                        }
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph(this.xmark)
                                .fontSize(20)
                                .fontColor(this.redColor)
                            Text("我識用粵拼打字了！")
                        }
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph(this.xmark)
                                .fontSize(20)
                                .fontColor(this.redColor)
                            Text("係了，你試過粵拼輸入法未啊？")
                        }
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)
                ListItemGroup({ space: 4 }) {
                    ListItem() {
                        Text("使").fontWeight(FontWeight.Bold)
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph(this.checkmark)
                                .fontSize(20)
                                .fontColor(this.greenColor)
                            Text("唔使驚")
                        }
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph(this.xmark)
                                .fontSize(20)
                                .fontColor(this.redColor)
                            Text("唔駛驚")
                        }
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph(this.xmark)
                                .fontSize(20)
                                .fontColor(this.redColor)
                            Text("唔洗驚")
                        }
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)
                ListItemGroup({ space: 4 }) {
                    ListItem() {
                        Text("而家").fontWeight(FontWeight.Bold)
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph(this.checkmark)
                                .fontSize(20)
                                .fontColor(this.greenColor)
                            Text("我而家食緊飯。")
                        }
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph(this.xmark)
                                .fontSize(20)
                                .fontColor(this.redColor)
                            Text("我宜家食緊飯。")
                        }
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)
                ListItemGroup({ space: 4 }) {
                    ListItem() {
                        Text("甲（形容詞）過乙").fontWeight(FontWeight.Bold)
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph(this.checkmark)
                                .fontSize(20)
                                .fontColor(this.greenColor)
                            Text("苦過黃連。")
                        }
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph(this.checkmark)
                                .fontSize(20)
                                .fontColor(this.greenColor)
                            Text("狼過華秀隻狗。")
                        }
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph(this.xmark)
                                .fontSize(20)
                                .fontColor(this.redColor)
                            Text("比黃連苦。")
                        }
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph(this.xmark)
                                .fontSize(20)
                                .fontColor(this.redColor)
                            Text("比華秀隻狗更狼。")
                        }
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)
                ListItemGroup({ space: 4 }) {
                    ListItem() {
                        Text("兩樣都得").fontWeight(FontWeight.Bold)
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph(this.infoMark)
                                .fontSize(20)
                            Text("甲：「你飲茶定係飲咖啡？」")
                        }
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph(this.checkmark)
                                .fontSize(20)
                                .fontColor(this.greenColor)
                            Text("乙：「兩樣都得。」")
                        }
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Row({ space: 12 }) {
                            SymbolGlyph(this.xmark)
                                .fontSize(20)
                                .fontColor(this.redColor)
                            Text("乙：「都得。」")
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
