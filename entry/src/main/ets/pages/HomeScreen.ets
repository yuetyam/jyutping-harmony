import { common, Want } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { HdsNavigation, hdsMaterial, ScrollEffectType } from "@kit.UIDesignKit";
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

const APP_DATABASE_FILE_NAME: string = "app-260923-db.sqlite3";

@ComponentV2
export struct HomeScreen {
    private groupBackgroundColor = $r('app.color.group_background');
    private groupBorderRadius: Length = 16;
    @Local private inputText: string = '';
    @Local private submittedText: string = '';
    @Monitor('submittedText') performSearch(): void {
        this.searchSubmittedText();
    }
    @Local private lexicons: CantoneseLexicon[] = [];
    @Local private yingWaaLexicons: YingWaaLexicon[] = [];
    @Local private choHokLexicons: ChoHokLexicon[] = [];
    @Local private fanWanLexicons: FanWanLexicon[] = [];
    @Local private gwongWanLexicons: GwongWanLexicon[] = [];

    private async deleteOldDatabases(context: Context) {
        const fileNames: string[] = ["app-260913-db.sqlite3", "app-20260712-tmp.sqlite3", "app-20260620-tmp.sqlite3"];
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
    private async copyAppDatabase(context: Context, shouldReplace: boolean = false): Promise<boolean> {
        const databaseDirectory: string = context.databaseDir + "/rdb/app";
        const desPath: string = databaseDirectory + "/" + APP_DATABASE_FILE_NAME;
        const temporaryPath: string = desPath + ".copying";
        try {
            const srcFileName: string = "app.sqlite3";
            const srcPath: string = context.resourceDir + "/" + srcFileName;
            const srcSize: number = fs.statSync(srcPath).size;
            if (!shouldReplace && fs.accessSync(desPath) && fs.statSync(desPath).size === srcSize) {
                console.debug("app database path: " + desPath);
                return true;
            }
            if (!fs.accessSync(databaseDirectory)) {
                fs.mkdirSync(databaseDirectory, true);
            }
            if (fs.accessSync(temporaryPath)) {
                fs.unlinkSync(temporaryPath);
            }
            console.debug("src database path: " + srcPath);
            console.debug("des database path: " + desPath);
            const sourceFile = fs.openSync(srcPath, fs.OpenMode.READ_ONLY);
            try {
                const destinationFile = fs.openSync(temporaryPath, fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
                try {
                    const buffer: ArrayBuffer = new ArrayBuffer(1024 * 1024);
                    while (true) {
                        const bytesRead: number = await fs.read(sourceFile.fd, buffer);
                        if (bytesRead < 1) {
                            break;
                        }
                        let bytesWritten: number = 0;
                        while (bytesWritten < bytesRead) {
                            const remaining: ArrayBuffer = buffer.slice(bytesWritten, bytesRead);
                            const count: number = await fs.write(destinationFile.fd, remaining);
                            if (count < 1) {
                                throw new Error("Failed to write app database");
                            }
                            bytesWritten += count;
                        }
                    }
                } finally {
                    fs.closeSync(destinationFile);
                }
            } finally {
                fs.closeSync(sourceFile);
            }
            if (fs.statSync(temporaryPath).size !== srcSize) {
                throw new Error("Copied app database has an unexpected size");
            }
            fs.renameSync(temporaryPath, desPath);
            return true;
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error("copyAppDatabase() failed, message: " + err.message + ", code: " + err.code);
            try {
                if (fs.accessSync(temporaryPath)) {
                    fs.unlinkSync(temporaryPath);
                }
            } catch (cleanupError) {
                const err: BusinessError = cleanupError as BusinessError;
                console.error("Failed to delete temporary app database, message: " + err.message + ", code: " + err.code);
            }
            return false;
        }
    }
    private store: relationalStore.RdbStore | undefined = undefined;
    private async obtainStore(context: Context): Promise<void> {
        let storeConfig: relationalStore.StoreConfig = {
            name: APP_DATABASE_FILE_NAME,
            securityLevel: relationalStore.SecurityLevel.S1,
            encrypt: false,
            customDir: 'app',
            isReadOnly: true
        };
        try {
            this.store = await relationalStore.getRdbStore(context, storeConfig);
        } catch (error) {
            const err: BusinessError = error as BusinessError;
            console.error(`Error in getRdbStore(). message: ${err.message}, code: ${err.code}`);
        }
    }
    private async closeStore(): Promise<void> {
        const store = this.store;
        this.store = undefined;
        try {
            await store?.close();
        } catch (error) {
            const err: BusinessError = error as BusinessError;
            console.error("error at closing data store, message: " + err.message + ", code: " + err.code);
        }
    }
    private storePreparation: Promise<void> | undefined = undefined;
    private async prepareStore(): Promise<void> {
        if (this.storePreparation) {
            await this.storePreparation;
            return;
        }
        this.storePreparation = this.prepareStoreOnce();
        try {
            await this.storePreparation;
        } finally {
            this.storePreparation = undefined;
        }
    }
    private async prepareStoreOnce(): Promise<void> {
        let shouldReplace: boolean = false;
        if (this.store) {
            const rowID: number = CantoneseDataHelper.test(this.store);
            if (rowID > 0) {
                return;
            }
            await this.closeStore();
            shouldReplace = true;
        }
        const context = this.getUIContext().getHostContext();
        if (!context) {
            return;
        }
        const copied: boolean = await this.copyAppDatabase(context, shouldReplace);
        if (!copied) {
            return;
        }
        await this.obtainStore(context);
        if (this.store && CantoneseDataHelper.test(this.store) > 0) {
            await this.deleteOldDatabases(context);
            return;
        }
        await this.closeStore();
        if (shouldReplace || !(await this.copyAppDatabase(context, true))) {
            return;
        }
        await this.obtainStore(context);
        if (this.store && CantoneseDataHelper.test(this.store) > 0) {
            await this.deleteOldDatabases(context);
        } else {
            await this.closeStore();
        }
    }
    private async searchSubmittedText(): Promise<void> {
        const submittedText: string = this.submittedText;
        if (!submittedText) {
            this.lexicons = [];
            this.yingWaaLexicons = [];
            this.choHokLexicons = [];
            this.fanWanLexicons = [];
            this.gwongWanLexicons = [];
            return;
        }
        await this.prepareStore();
        if (submittedText !== this.submittedText || !this.store) {
            return;
        }
        this.lexicons = CantoneseDataHelper.search(submittedText, this.store);
        this.yingWaaLexicons = YingWaaHelper.search(submittedText, this.store);
        this.choHokLexicons = ChoHokHelper.search(submittedText, this.store);
        this.fanWanLexicons = FanWanHelper.search(submittedText, this.store);
        this.gwongWanLexicons = GwongWanHelper.search(submittedText, this.store);
    }

    /*
    @Local private shouldShowInputMethodButtons: boolean = true;
    private detectInputMethodState(): void {
        const packageName: string = "org.jyutping.jyutping";
        // const identifier: string = "InputMethodExtensionAbility";
        try {
            let currentInputMethod = inputMethod.getCurrentInputMethod();
            this.shouldShowInputMethodButtons = (currentInputMethod.name != packageName);
        } catch (error) {
            const err: BusinessError = error as BusinessError;
            console.error(`Failed to getCurrentInputMethod, message: ${err.message}}, code: ${err.code}}`);
        }
    }
    */

    aboutToAppear(): void {
        this.prepareStore();
    }

    build() {
        HdsNavigation() {
            List({ space: 20 }) {
                ListItem() {
                    Search({ value: this.inputText, placeholder: $r('app.string.search_placeholder') })
                        .keyboardAppearance(KeyboardAppearance.IMMERSIVE)
                        .backgroundBlurStyle(BlurStyle.COMPONENT_REGULAR)
                        .onEditChange((changed: boolean) => {
                            if (changed) {
                                this.prepareStore();
                            }
                        })
                        .onSubmit((text: string) => {
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

                ListItem() {
                    Button() {
                        Row({ space: 12 }) {
                            Blank()
                            SymbolGlyph($r('sys.symbol.keyboard')).fontColor([Color.White])
                            Text($r('app.string.home_button_enable_keyboard')).fontColor(Color.White)
                            SymbolGlyph($r('sys.symbol.arrow_right_up_and_square')).fontColor([Color.White])
                            Blank()
                        }
                        .padding({ top: 10, bottom: 10 })
                    }
                    .backgroundColor($r('app.color.accent'))
                    .width('100%')
                    .onClick(() => {
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

                ListItemGroup({ space: 8 }) {
                    ListItem() {
                        Image($r("app.media.full_mode")).borderRadius(8).padding(2)
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Row({ space: 10 }) {
                            Stack() {
                                SymbolGlyph($r('sys.symbol.circle')).fontSize(22).fontColor([$r('app.color.apple_green')])
                                Text("i").fontSize(16).fontColor($r('app.color.apple_green'))
                            }
                            Text($r("app.string.full_mode_notes_title")).fontWeight(FontWeight.Bold)
                        }
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Text($r("app.string.full_mode_notes_row1"))
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Text($r("app.string.full_mode_notes_row2"))
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)

                ListItemGroup({ space: 8 }) {
                    ListItem() {
                        Row({ space: 10 }) {
                            Stack() {
                                SymbolGlyph($r('sys.symbol.circle')).fontSize(22).fontColor([$r('app.color.apple_blue')])
                                Text("#").fontSize(16).fontColor($r('app.color.apple_blue'))
                            }
                            Text($r("app.string.guide_abbreviated_input_heading")).fontWeight(FontWeight.Bold)
                        }
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Text($r('app.string.guide_abbreviated_input_body_row1'))
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Text($r('app.string.guide_abbreviated_input_body_row2'))
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)

                ListItemGroup({ space: 8 }) {
                    ListItem() {
                        Row({ space: 10 }) {
                            Stack() {
                                SymbolGlyph($r('sys.symbol.circle')).fontSize(22).fontColor([$r('app.color.apple_purple')])
                                Text("R").fontSize(16).fontColor($r('app.color.apple_purple'))
                            }
                            Text($r('app.string.guide_pinyin_reverse_lookup_heading')).fontWeight(FontWeight.Bold)
                        }
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Text($r('app.string.guide_pinyin_reverse_lookup_body'))
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)

                ListItemGroup({ space: 8 }) {
                    ListItem() {
                        Row({ space: 10 }) {
                            Stack() {
                                SymbolGlyph($r('sys.symbol.circle')).fontSize(22).fontColor([$r('app.color.apple_indigo')])
                                Text("Q").fontSize(16).fontColor($r('app.color.apple_indigo'))
                            }
                            Text($r('app.string.guide_structure_reverse_lookup_heading')).fontWeight(FontWeight.Bold)
                        }
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Text($r('app.string.guide_structure_reverse_lookup_body'))
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)

                ListItemGroup({ space: 8 }) {
                    ListItem() {
                        Row({ space: 10 }) {
                            Stack() {
                                SymbolGlyph($r('sys.symbol.circle')).fontSize(22).fontColor([$r('app.color.apple_orange')])
                                Text("6").fontSize(16).fontColor($r('app.color.apple_orange'))
                            }
                            Text($r('app.string.guide_tones_input_heading')).fontWeight(FontWeight.Bold)
                        }
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Text($r('app.string.guide_tones_input_body')).fontFamily('Noto Sans Mono')
                    }
                    ListItem() { Divider() }
                    ListItem() {
                        Text($r('app.string.guide_tones_input_examples'))
                    }
                }
                .padding(8)
                .backgroundColor(this.groupBackgroundColor)
                .borderRadius(this.groupBorderRadius)

                /*
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
                */

            }
            .padding({ left: 16, right: 16 })
            .contentStartOffset($r('app.float.app_content_medium_offset'))
            .contentEndOffset($r('app.float.app_content_large_offset'))
            .width('100%')
            .height('100%')
        }
        .mode(NavigationMode.Stack)
        .titleBar({
            content: {
                title: {
                    mainTitle: $r("app.string.home_screen_title")
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
        .background($r('app.color.window_background'))
    }
}
