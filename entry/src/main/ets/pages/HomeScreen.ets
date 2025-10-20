import { common, Want } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { bundleManager } from '@kit.AbilityKit';
import { CantoneseLexicon } from '../search/CantoneseLexicon';
import { CantoneseLexiconView } from '../search/CantoneseLexiconView';
import { DatabaseHelper } from '../search/DatabaseHelper';

@ComponentV2
export struct HomeScreen {
    private pageStack: NavPathStack = new NavPathStack();
    private groupBackgroundColor = $r('app.color.group_background');
    private groupBorderRadius: Length = 12;
    @Local private inputText: string = '';
    @Local private submittedText: string = '';
    @Monitor('submittedText') performSearch() {
        this.prepareStore();
        if (this.store) {
            if (this.submittedText) {
                let lexicon = DatabaseHelper.search(this.submittedText, this.store);
                this.lexicons = [lexicon];
            } else {
                this.lexicons = [];
            }
        }
    }
    @Local private lexicons: CantoneseLexicon[] = [];
    private store: relationalStore.RdbStore | undefined = undefined;
    private async obtainStore() {
        let bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
        let fileName: string = `appdb-${bundleInfo.versionName}-${bundleInfo.versionCode}-tmp.sqlite3`;
        let storeConfig: relationalStore.StoreConfig = {
            name: fileName,
            securityLevel: relationalStore.SecurityLevel.S1,
            encrypt: false,
            customDir: 'app',
            isReadOnly: true
        };
        relationalStore.getRdbStore(this.getUIContext().getHostContext(), storeConfig,
            async (err: BusinessError, rdbStore: relationalStore.RdbStore) => {
                if (err) {
                    console.error(`Error in getRdbStore(). message: ${err.message}, code: ${err.code}`);
                    return;
                }
                this.store = rdbStore;
            });
    }
    private prepareStore(): void {
        if (this.store === undefined) {
            this.obtainStore();
        } else if (this.store.version < 1) {
            this.obtainStore();
        }
    }

    build() {
        Navigation(this.pageStack) {
            List({ space: 20 }) {
                ListItem() {
                    Search({
                        value: this.inputText,
                        placeholder: $r('app.string.search_placeholder'),
                    }).onEditChange((changed: boolean) => {
                        if (changed) {
                            this.prepareStore();
                        }
                    }).onSubmit((text: string) => {
                        this.submittedText = text;
                    })
                }
                ForEach(this.lexicons, (item: CantoneseLexicon) => {
                    ListItem() {
                        CantoneseLexiconView({ lexicon: item })
                    }
                    .padding(8)
                    .backgroundColor(this.groupBackgroundColor)
                    .borderRadius(this.groupBorderRadius)
                }, (item: CantoneseLexicon) => item.text)

                ListItem() {
                    Button() {
                        Row({ space: 12 }) {
                            Blank()
                            SymbolGlyph($r('sys.symbol.keyboard')).fontColor([Color.White])
                            Text($r('app.string.home_button_enable_keyboard')).fontColor(Color.White)
                            SymbolGlyph($r('sys.symbol.arrow_right_up_and_square')).fontColor([Color.White])
                            Blank()
                        }
                        .padding(8)
                    }
                    .backgroundColor($r('app.color.accent'))
                    .width('100%')
                    .onClick((event?: ClickEvent) => {
                        if (event) {
                            let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
                            let want: Want = {
                                bundleName: 'com.huawei.hmos.settings',
                                abilityName: 'com.huawei.hmos.settings.MainAbility',
                                uri: 'set_input',
                                parameters: {
                                    bundleName: context.abilityInfo.bundleName,
                                    pushParams: context.abilityInfo.bundleName
                                }
                            }
                            context.startAbility(want).catch(() => {
                                // TODO: Implement error handling.
                            })
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
