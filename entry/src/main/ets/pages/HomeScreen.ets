import { common, Want } from '@kit.AbilityKit'

@Component
export struct HomeScreen {
    private pageStack: NavPathStack = new NavPathStack();
    private groupBackgroundColor = $r('app.color.group_background');
    private groupBorderRadius: Length = 12;
    @State private inputText: string = '';
    build() {
        Navigation(this.pageStack) {
            List({ space: 20 }) {
                ListItem() {
                    Search({
                        value: this.inputText,
                        placeholder: $r('app.string.search_placeholder'),
                    })
                }

                ListItem() {
                    Button() {
                        Row({ space: 12 }) {
                            Blank()
                            SymbolGlyph($r('sys.symbol.keyboard')).fontColor([Color.White])
                            Text($r('app.string.home_button_enable_keyboard')).fontColor(Color.White)
                            SymbolGlyph($r('sys.symbol.keyboard')).opacity(0)
                            Blank()
                        }
                        .padding(8)
                    }
                    .backgroundColor($r('app.color.accent'))
                    .width('100%')
                    .onClick((event?: ClickEvent) => {
                        if (event) {
                            let context = getContext() as common.UIAbilityContext;
                            let want: Want = {
                                bundleName: 'com.huawei.hmos.settings',
                                abilityName: 'com.huawei.hmos.settings.MainAbility',
                                uri: 'application_info_entry',
                                parameters: {
                                    bundleName: context.abilityInfo.bundleName,
                                    pushParams: context.abilityInfo.bundleName
                                }
                            }
                            context.startAbility(want)
                        }
                    })
                }

                ListItemGroup({ space: 8 }) {
                    ListItem() {
                        Text($r("app.string.guide_abbreviated_input_heading"))
                            .fontWeight(FontWeight.Bold)
                    }

                    ListItem() {
                        Divider()
                    }

                    ListItem() {
                        Text($r('app.string.guide_abbreviated_input_body_row1'))
                    }

                    ListItem() {
                        Divider()
                    }

                    ListItem() {
                        Text($r('app.string.guide_abbreviated_input_body_row2'))
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)

                ListItemGroup({ space: 8 }) {
                    ListItem() {
                        Text($r('app.string.guide_pinyin_reverse_lookup_heading'))
                            .fontWeight(FontWeight.Bold)
                    }

                    ListItem() {
                        Divider()
                    }

                    ListItem() {
                        Text($r('app.string.guide_pinyin_reverse_lookup_body'))
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)

                ListItemGroup({ space: 8 }) {
                    ListItem() {
                        Text($r('app.string.guide_cangjie_reverse_lookup_heading'))
                            .fontWeight(FontWeight.Bold)
                    }

                    ListItem() {
                        Divider()
                    }

                    ListItem() {
                        Text($r('app.string.guide_cangjie_reverse_lookup_body_row1'))
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)

                ListItemGroup({ space: 8 }) {
                    ListItem() {
                        Text($r('app.string.guide_stroke_reverse_lookup_heading'))
                            .fontWeight(FontWeight.Bold)
                    }

                    ListItem() {
                        Divider()
                    }

                    ListItem() {
                        Text($r('app.string.guide_stroke_reverse_lookup_body'))
                    }

                    ListItem() {
                        Divider()
                    }

                    ListItem() {
                        Text($r('app.string.guide_stroke_reverse_lookup_examples'))
                            .fontFamily('Noto Sans Mono')
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)

                ListItemGroup({ space: 8 }) {
                    ListItem() {
                        Text($r('app.string.guide_structure_reverse_lookup_heading'))
                            .fontWeight(FontWeight.Bold)
                    }

                    ListItem() {
                        Divider()
                    }

                    ListItem() {
                        Text($r('app.string.guide_structure_reverse_lookup_body'))
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)

                ListItemGroup({ space: 8 }) {
                    ListItem() {
                        Text($r('app.string.guide_tones_input_heading'))
                            .fontWeight(FontWeight.Bold)
                    }

                    ListItem() {
                        Divider()
                    }

                    ListItem() {
                        Text($r('app.string.guide_tones_input_body'))
                            .fontFamily('Noto Sans Mono')
                    }

                    ListItem() {
                        Divider()
                    }

                    ListItem() {
                        Text($r('app.string.guide_tones_input_examples'))
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
        .mode(NavigationMode.Stack)
        .title($r('app.string.tab_bar_home'))
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.window_background'))
    }
}
