import { common, Want } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { inputMethod } from '@kit.IMEKit';
import { CantoneseLexicon } from '../search/CantoneseLexicon';
import { CantoneseLexiconView } from '../search/CantoneseLexiconView';
import { ChoHokHelper } from '../search/ChoHokHelper';
import { ChoHokLexiconView } from '../search/ChoHokLexiconView';
import { ChoHokLexicon } from '../search/ChoHokUnit';
import { CantoneseDataHelper } from '../search/CantoneseDataHelper';
import { FanWanHelper } from '../search/FanWanHelper';
import { FanWanLexiconView } from '../search/FanWanLexiconView';
import { FanWanLexicon } from '../search/FanWanUnit';
import { GwongWanHelper } from '../search/GwongWanHelper';
import { GwongWanLexicon } from '../search/GwongWanUnit';
import { GwongWanLexiconView } from '../search/GwongWanLexiconView';
import { YingWaaHelper } from '../search/YingWaaHelper';
import { YingWaaLexiconView } from '../search/YingWaaLexiconView';
import { YingWaaLexicon } from '../search/YingWaaUnit';

@ComponentV2
export struct HomeScreen {
    private pageStack: NavPathStack = new NavPathStack();
    private groupBackgroundColor = $r('app.color.group_background');
    private groupBorderRadius: Length = 12;
    @Local private inputText: string = '';
    @Local private submittedText: string = '';
    @Monitor('submittedText') performSearch() {
        if (this.store) {
            if (this.submittedText) {
                this.lexicons = CantoneseDataHelper.search(this.submittedText, this.store);
                this.yingWaaLexicons = YingWaaHelper.search(this.submittedText, this.store);
                this.choHokLexicons = ChoHokHelper.search(this.submittedText, this.store);
                this.fanWanLexicons = FanWanHelper.search(this.submittedText, this.store);
                this.gwongWanLexicons = GwongWanHelper.search(this.submittedText, this.store);
            } else {
                this.lexicons = [];
                this.yingWaaLexicons = [];
                this.choHokLexicons = [];
                this.fanWanLexicons = [];
                this.gwongWanLexicons = [];
            }
        } else {
            this.prepareStore();
        }
    }
    @Local private lexicons: CantoneseLexicon[] = [];
    @Local private yingWaaLexicons: YingWaaLexicon[] = [];
    @Local private choHokLexicons: ChoHokLexicon[] = [];
    @Local private fanWanLexicons: FanWanLexicon[] = [];
    @Local private gwongWanLexicons: GwongWanLexicon[] = [];

    private async deleteOldDatabases(context: Context) {
        const fileNames: string[] = ["appdb-20251125-tmp.sqlite3", "appdb-20251129-tmp.sqlite3"];
        const pathPrefix: string = context.databaseDir + "/rdb/app/";
        for (let index = 0; index < fileNames.length; index++) {
            const name: string = fileNames[index];
            const path: string = pathPrefix + name;
            try {
                if (fs.accessSync(path)) {
                    fs.unlinkSync(path);
                    console.debug("Successfully delete file " + name);
                }
            } catch (error) {
                let err: BusinessError = error as BusinessError;
                console.error(`Failed to delete file ${name}, message: ${err.message}, code: ${err.code}`);
            }
        }
    }
    private async copyAppDatabase(context: Context) {
        const srcFileName: string = "appdb.sqlite3";
        const srcPath: string = context.resourceDir + "/" + srcFileName;
        const desFileName: string = "appdb-20251217-tmp.sqlite3";
        const desPath: string = context.databaseDir + "/rdb/app/" + desFileName;
        try {
            if (fs.accessSync(desPath)) {
                console.debug("app database path: " + desPath);
            } else {
                console.debug("src database path: " + srcPath);
                console.debug("des database path: " + desPath);
                await fs.copyFile(srcPath, desPath);
            }
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error("copyAppDatabase() failed, message: " + err.message + ", code: " + err.code);
        }
        this.deleteOldDatabases(context);
    }
    private store: relationalStore.RdbStore | undefined = undefined;
    private async obtainStore() {
        const fileName: string = "appdb-20251217-tmp.sqlite3";
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
    private async prepareStore() {
        if (this.store) {
            const rowID: number = CantoneseDataHelper.test(this.store);
            if (rowID > 0) {
                return;
            }
            try {
                await this.store.close();
            } catch (error) {
                let err: BusinessError = error as BusinessError;
                console.error("error at closing data store, message: " + err.message + ", code: " + err.code);
            } finally {
                this.store = undefined;
            }
        }
        let context = this.getUIContext().getHostContext();
        if (context) {
            await this.copyAppDatabase(context);
            await this.obtainStore();
        }
    }

    @Local private shouldShowInputMethodButtons: boolean = true;
    private detectInputMethodState(): void {
        const packageName: string = "org.jyutping.jyutping";
        // const identifier: string = "InputMethodExtensionAbility";
        try {
            let currentInputMethod = inputMethod.getCurrentInputMethod();
            this.shouldShowInputMethodButtons = (currentInputMethod.name != packageName);
        } catch (error) {
        }
    }

    aboutToAppear(): void {
        this.prepareStore();
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

                ForEach(this.yingWaaLexicons, (item: YingWaaLexicon) => {
                    ListItemGroup() {
                        ListItem() {
                            Text("《英華分韻撮要》　衛三畏　1856年　廣州")
                                .fontSize(13)
                                .opacity(0.9)
                        }
                        .padding(2)
                        ListItem() {
                            YingWaaLexiconView({ lexicon: item })
                        }
                        .padding(8)
                        .backgroundColor(this.groupBackgroundColor)
                        .borderRadius(this.groupBorderRadius)
                    }
                }, (item: YingWaaLexicon) => item.word)

                ForEach(this.choHokLexicons, (item: ChoHokLexicon) => {
                    ListItemGroup() {
                        ListItem() {
                            Text("《初學粵音切要》　湛約翰　1855年　香港")
                                .fontSize(13)
                                .opacity(0.9)
                        }
                        .padding(2)
                        ListItem() {
                            ChoHokLexiconView({ lexicon: item })
                        }
                        .padding(8)
                        .backgroundColor(this.groupBackgroundColor)
                        .borderRadius(this.groupBorderRadius)
                    }
                }, (item: ChoHokLexicon) => item.word)

                ForEach(this.fanWanLexicons, (item: FanWanLexicon) => {
                    ListItemGroup() {
                        ListItem() {
                            Text("《分韻撮要》　佚名　廣州府　清初")
                                .fontSize(13)
                                .opacity(0.9)
                        }
                        .padding(2)
                        ListItem() {
                            FanWanLexiconView({ lexicon: item })
                        }
                        .padding(8)
                        .backgroundColor(this.groupBackgroundColor)
                        .borderRadius(this.groupBorderRadius)
                    }
                }, (item: FanWanLexicon) => item.word)

                ForEach(this.gwongWanLexicons, (item: GwongWanLexicon) => {
                    ListItemGroup() {
                        ListItem() {
                            Text("《大宋重修廣韻》　陳彭年等　北宋")
                                .fontSize(13)
                                .opacity(0.9)
                        }
                        .padding(2)
                        ListItem() {
                            GwongWanLexiconView({ lexicon: item })
                        }
                        .padding(8)
                        .backgroundColor(this.groupBackgroundColor)
                        .borderRadius(this.groupBorderRadius)
                    }
                }, (item: GwongWanLexicon) => item.word)

                if (this.shouldShowInputMethodButtons) {
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
                        .onClick((event: ClickEvent) => {
                            let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
                            let want: Want = {
                                bundleName: 'com.huawei.hmos.settings',
                                abilityName: 'com.huawei.hmos.settings.MainAbility',
                                uri: 'set_input',
                                parameters: {
                                    bundleName: context.abilityInfo.bundleName,
                                    pushParams: context.abilityInfo.bundleName
                                }
                            };
                            context.startAbility(want).catch(() => {
                                console.warn("Failed to jump to input method settings");
                            });
                        })
                    }
                }

                ListItem() {
                    Text("重要：键盘需「完整体验模式」方可用到完整词库")
                        .fontSize(14)
                        .lineHeight(20)
                }
                .padding(8)

                /*
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
                */
            }
            .padding({ left: 16, right: 16 })
            .width('100%')
            .height('100%')
        }
        .mode(NavigationMode.Stack)
        .title($r('app.string.home_screen_title'))
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.window_background'))
    }
}
