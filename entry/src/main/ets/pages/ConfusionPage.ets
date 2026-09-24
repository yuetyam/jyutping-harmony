import { HdsNavDestination, hdsMaterial, ScrollEffectType } from "@kit.UIDesignKit";
import util from '@ohos.util';

@Builder
export function PageBuilder() {
    ConfusionPage();
}

@ComponentV2
export struct ConfusionPage {
    private groupBackgroundColor = $r('app.color.group_background');
    private groupBorderRadius: Length = 16;
    @Local entries: ConfusionEntry[] = [];
    aboutToAppear(): void {
        let context = this.getUIContext().getHostContext();
        const fileName: string = 'confusion.json';
        try {
            context?.resourceManager.getRawFileContent(fileName, (error, value) => {
                if (error) {
                    console.error(error.message);
                    return;
                }
                let textDecoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
                const sourceText = textDecoder.decodeToString(value, { stream: false });
                this.entries = JSON.parse(sourceText);
            });
        } catch (error) {
            console.error(error.message);
        }
    }
    build() {
        HdsNavDestination() {
            List({ space: 8 }) {
                ForEach(this.entries, (item: ConfusionEntry) => {
                    ListItem() {
                        ConfusionEntryView({ entry: item })
                    }
                    .padding(8)
                    .backgroundColor(this.groupBackgroundColor)
                    .borderRadius(this.groupBorderRadius)
                }, (item: ConfusionEntry) => item.simplified)

            }
            .padding({ left: 16, right: 16 })
            .contentStartOffset($r('app.float.app_content_compact_offset'))
            .contentEndOffset($r('app.float.app_content_large_offset'))
            .width('100%')
            .height('100%')
        }
        .titleBar({
            content: {
                title: {
                    mainTitle: $r('app.string.cantonese_confusion_title')
                }
            },
            style: {
                scrollEffectOpts: {
                    enableScrollEffect: true,
                    scrollEffectType: ScrollEffectType.GRADIENT_BLUR
                },
                systemMaterialEffect: {
                    materialType: hdsMaterial.MaterialType.ADAPTIVE,
                    materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
                }
            }
        })
        .backgroundColor($r('app.color.window_background'))
    }
}

@ComponentV2
struct ConfusionEntryView {
    @Param @Require @Once entry: ConfusionEntry;
    build() {
        Row({ space: 12 }) {
            Text(this.entry.simplified)
            Column({ space: 4 }) {
                ForEach(this.entry.traditional, (item: TraditionalUnit) => {
                    Row({ space: 8 }) {
                        Text(item.character)
                        Stack() {
                            Text("chung4").opacity(0)
                            Text(item.romanization)
                        }
                        .alignContent(Alignment.Start)
                        Text(item.note)
                        Blank()
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.Start)
                }, (item: TraditionalUnit) => (item.character + item.romanization))
            }
            .width('100%')
            .justifyContent(FlexAlign.Start)
            Blank()
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
    }
}

interface ConfusionEntry {
    readonly simplified: string;
    readonly traditional: TraditionalUnit[];
}

interface TraditionalUnit {
    readonly character: string;
    readonly romanization: string;
    readonly note: string;
}
