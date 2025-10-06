import controller from "../model/InputController"
import { CircleShape } from "@kit.ArkUI";

@ComponentV2
export default struct SettingsPanel {
    private shapeLength = '44vp';
    private shape = new CircleShape({ width: this.shapeLength, height: this.shapeLength });
    private groupBackgroundColor = $r('app.color.group_background');
    private groupBorderRadius: Length = 12;
    private groupHorizontalPadding: Length = 12;

    build() {
        Column() {
            Row() {
                Stack() {
                    Button() {
                        SymbolGlyph($r('sys.symbol.chevron_up'))
                            .fontSize(32)
                            .fontColor([$r('sys.color.ohos_id_color_primary')])
                    }
                    .backgroundColor($r('app.color.key_shallow'))
                    .clipShape(this.shape)
                    .width(this.shapeLength)
                    .height(this.shapeLength)
                }
                .width('50vp')
                .height('100%')
                .onClick((event?: ClickEvent) => {
                    if (event) {
                        controller.playModifierSound();
                        controller.transformTo(controller.previousKeyboardForm);
                    }
                })
                Blank()
                Text('This page is scrollable')
                    .fontSize(12)
                    .opacity(0.8)
                Blank()
                Stack() {
                    Button() {
                        Stack() {
                            SymbolGlyph($r('sys.symbol.arrow_up'))
                                .fontSize(22)
                                .fontColor([$r('sys.color.ohos_id_color_primary')])
                                .padding({ bottom: 5 })
                            SymbolGlyph($r('sys.symbol.arrow_down'))
                                .fontSize(22)
                                .fontColor([$r('sys.color.ohos_id_color_primary')])
                                .padding({ top: 5 })
                        }
                    }
                    .backgroundColor($r('app.color.key_shallow'))
                    .clipShape(this.shape)
                    .width(this.shapeLength)
                    .height(this.shapeLength)
                }
                .width('50vp')
                .height('100%')
                .onClick((event?: ClickEvent) => {
                    if (event) {
                        controller.playModifierSound();
                        // TODO: Extend Keyboard Height
                    }
                })
            }
            .width('100%')
            .height('50vp')
            List({ space: 20 }) {
                ListItemGroup() {
                    ListItem() {
                        Button() {
                            Row() {
                                Text("Traditional")
                                Blank()
                                SymbolGlyph($r('sys.symbol.checkmark'))
                                    .fontSize(28)
                                    .fontColor([$r('app.color.accent')])
                            }
                            .padding({ left: 8, top: 4, right: 8, bottom: 4 })
                            .width('100%')
                        }
                        .backgroundColor(Color.Transparent)
                        .width('100%')
                        .onClick((event?: ClickEvent) => {
                            if (event) {
                                // TODO: Handler
                            }
                        })
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        Button() {
                            Row() {
                                Text("Traditional, Hong Kong")
                                Blank()
                                SymbolGlyph($r('sys.symbol.checkmark'))
                                    .fontSize(28)
                                    .fontColor([$r('app.color.accent')])
                                    .opacity(0)
                            }
                            .padding({ left: 8, top: 4, right: 8, bottom: 4 })
                            .width('100%')
                        }
                        .backgroundColor(Color.Transparent)
                        .width('100%')
                        .onClick((event?: ClickEvent) => {
                            if (event) {
                                // TODO: Handler
                            }
                        })
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        Button() {
                            Row() {
                                Text("Traditional, Taiwan")
                                Blank()
                                SymbolGlyph($r('sys.symbol.checkmark'))
                                    .fontSize(28)
                                    .fontColor([$r('app.color.accent')])
                                    .opacity(0)
                            }
                            .padding({ left: 8, top: 4, right: 8, bottom: 4 })
                            .width('100%')
                        }
                        .backgroundColor(Color.Transparent)
                        .width('100%')
                        .onClick((event?: ClickEvent) => {
                            if (event) {
                                // TODO: Handler
                            }
                        })
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        Button() {
                            Row() {
                                Text("Simplified")
                                Blank()
                                SymbolGlyph($r('sys.symbol.checkmark'))
                                    .fontSize(28)
                                    .fontColor([$r('app.color.accent')])
                                    .opacity(0)
                            }
                            .padding({ left: 8, top: 4, right: 8, bottom: 4 })
                            .width('100%')
                        }
                        .backgroundColor(Color.Transparent)
                        .width('100%')
                        .onClick((event?: ClickEvent) => {
                            if (event) {
                                // TODO: Handler
                            }
                        })
                    }
                }
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)

                ListItemGroup() {
                    ListItem() {
                        Row() {
                            Text("Sound Feedback")
                            Blank()
                            Toggle({ type: ToggleType.Switch, isOn: true })
                                .selectedColor($r('app.color.accent'))
                                .switchPointColor(Color.White)
                                .onChange((isOn: boolean) => {
                                    // TODO: Handle sound switch
                                })
                        }
                        .padding({ left: 8, top: 4, right: 8, bottom: 4 })
                        .width('100%')
                    }
                    ListItem() {
                        Divider()
                    }
                    ListItem() {
                        Row() {
                            Text("Haptic Feedback")
                            Blank()
                            Toggle({ type: ToggleType.Switch, isOn: true })
                                .selectedColor($r('app.color.accent'))
                                .switchPointColor(Color.White)
                                .onChange((isOn: boolean) => {
                                    // TODO: Handle haptic switch
                                })
                        }
                        .padding({ left: 8, top: 4, right: 8, bottom: 4 })
                        .width('100%')
                    }
                }
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)
            }
            .padding({ left: this.groupHorizontalPadding, right: this.groupHorizontalPadding })
            .width('100%')
            .height('calc(100% - 50vp)')
        }
        .width('100%')
        .height(controller.keyboardHeight)
    }
}
