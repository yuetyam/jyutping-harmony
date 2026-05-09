import { display } from '@kit.ArkUI';
import { preferences, relationalStore } from '@kit.ArkData';
import { audio } from '@kit.AudioKit';
import { BusinessError, pasteboard } from '@kit.BasicServicesKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { inputMethodEngine, InputMethodExtensionContext } from '@kit.IMEKit';
import { media } from '@kit.MediaKit';
import { vibrator } from '@kit.SensorServiceKit';
import { InputMode, InputModeCompanion } from './model/InputMode';
import { KeyboardForm } from './model/KeyboardForm';
import { Researcher } from './model/Researcher';
import { Candidate } from './model/Candidate';
import { CandidateType } from './model/CandidateType';
import { EditingAction } from './editing/EditingAction';
import { KeyboardCase, KeyboardCaseCompanion } from './model/KeyboardCase';
import { InputMemory } from './model/InputMemory';
import { Lexicon } from './model/Lexicon';
import { Converter } from './model/Converter';
import { HapticEffectId, HapticType } from './model/HapticType';
import { VirtualInputKey } from './model/VirtualInputKey';
import { BasicInputEvent } from './model/BasicInputEvent';
import { KeyboardLayout, KeyboardLayoutCompanion } from './model/KeyboardLayout';
import { Combo } from './ninekey/Combo';
import { NineKeyPinyinResearcher } from './model/NineKeyPinyinResearcher';
import { NineKeyResearcher } from './model/NineKeyResearcher';
import { PinyinResearcher } from './model/PinyinResearcher';
import { PinyinSegmentation, PinyinSegmenter } from './model/PinyinSegmenter';
import { Scheme, Segmentation, Segmenter } from './model/Segmenter';

@ObservedV2
export class InputController {
    private ctx: InputMethodExtensionContext | undefined = undefined;
    private panel: inputMethodEngine.Panel | undefined = undefined;
    private attribute: inputMethodEngine.EditorAttribute | undefined = undefined
    private inputClient: inputMethodEngine.InputClient | undefined = undefined;
    private keyboardController: inputMethodEngine.KeyboardController | undefined = undefined;
    private ability: inputMethodEngine.InputMethodAbility = inputMethodEngine.getInputMethodAbility();

    private soundPool: media.SoundPool | undefined = undefined;
    private inputSoundID: number = 0;
    private inputStreamID: number = 0;
    private modifierSoundID: number = 0;
    private modifierStreamID: number = 0;
    private deleteSoundID: number = 0;
    private deleteStreamID: number = 0;
    private async prepareSoundPool() {
        try {
            let audioRendererInfo: audio.AudioRendererInfo = {
                usage: audio.StreamUsage.STREAM_USAGE_MUSIC,
                rendererFlags: 0
            }
            this.soundPool = await media.createSoundPool(14, audioRendererInfo);
            let inputDescriptor = await this.ctx?.resourceManager.getRawFd('click.m4a').catch(() => { console.error("Failed to get click.m4a") });
            if (inputDescriptor) {
                this.inputSoundID = await this.soundPool.load(inputDescriptor.fd, inputDescriptor.offset, inputDescriptor.length);
            }
            let clickDescriptor = await this.ctx?.resourceManager.getRawFd('modifier.m4a').catch(() => { console.error("Failed to get modifier.m4a") });
            if (clickDescriptor) {
                this.modifierSoundID = await this.soundPool.load(clickDescriptor.fd, clickDescriptor.offset, clickDescriptor.length);
            }
            let deleteDescriptor = await this.ctx?.resourceManager.getRawFd('delete.m4a').catch(() => { console.error("Failed to get delete.m4a") });
            if (deleteDescriptor) {
                this.deleteSoundID = await this.soundPool.load(deleteDescriptor.fd, deleteDescriptor.offset, deleteDescriptor.length);
            }
        } catch (error) {
            let err = error as BusinessError;
            console.error('Error in prepareSoundPool(), message: ' + err.message + ", code: " + err.code);
        }
    }
    private async releaseSoundPool() {
        try {
            await this.soundPool?.stop(this.inputStreamID);
            await this.soundPool?.unload(this.inputSoundID);
            await this.soundPool?.stop(this.modifierStreamID);
            await this.soundPool?.unload(this.modifierSoundID);
            await this.soundPool?.stop(this.deleteStreamID);
            await this.soundPool?.unload(this.deleteSoundID);
            await this.soundPool?.release();
        } catch (error) {
            let err = error as BusinessError;
            console.error('Error in releaseSoundPool(), message: ' + err.message + ", code: " + err.code);
        }
    }
    private playParameters: media.PlayParameters = {
        loop: 0,
        rate: 1,
        leftVolume: 1,
        rightVolume: 1,
        priority: 99,
    };
    playInputSound() {
        if (this.isAudioFeedbackOn) {
            this.soundPool?.play(this.inputSoundID, this.playParameters, (error, streamID: number) => {
                if (error) {
                    console.error('Error in playInputSound(), message: ' + error.message + ", code: " + error.code);
                } else {
                    this.inputStreamID = streamID;
                }
            });
        }
    }
    playModifierSound() {
        if (this.isAudioFeedbackOn) {
            this.soundPool?.play(this.modifierSoundID, this.playParameters, (error, streamID: number) => {
                if (error) {
                    console.error('Error in playModifierSound(), message: ' + error.message + ", code: " + error.code);
                } else {
                    this.modifierStreamID = streamID;
                }
            });
        }
    }
    playDeleteSound() {
        if (this.isAudioFeedbackOn) {
            this.soundPool?.play(this.deleteSoundID, this.playParameters, (error, streamID: number) => {
                if (error) {
                    console.error('Error in playDeleteSound(), message: ' + error.message + ", code: " + error.code);
                } else {
                    this.deleteStreamID = streamID;
                }
            });
        }
    }
    @Trace isAudioFeedbackOn: boolean = true;
    updateAudioFeedbackState(isOn: boolean) {
        this.isAudioFeedbackOn = isOn;
        const value: number = isOn ? 1 : 2;
        try {
            this.sharedPreferences?.putSync("audio", value);
            this.sharedPreferences?.flush().catch(() => {
                console.error("Failed to save value to the audio preferences");
            });
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error("Failed to save value to the audio preferences, message: " + err.message + ", code: " + err.code);
        }
    }

    triggerHapticFeedback(type: HapticType = HapticType.Hard) {
        if (!(this.isHapticFeedbackOn)) {
            return;
        }
        try {
            const effectId = HapticEffectId.of(type);
            vibrator.isSupportEffect(effectId, (error: BusinessError, state: boolean) => {
                if (error) {
                    console.error(`Failed to query effect. Code: ${error.code}, message: ${error.message}`);
                    return;
                }
                if (state) {
                    try {
                        vibrator.startVibration({
                            type: 'preset',
                            effectId: effectId,
                            count: 1,
                        }, {
                            usage: 'notification'
                        }, (error: BusinessError) => {
                            if (error) {
                                console.error(`Failed to start vibration. Code: ${error.code}, message: ${error.message}`);
                                return;
                            }
                        });
                    } catch (caughtError) {
                        let err: BusinessError = caughtError as BusinessError;
                        console.error(`An unexpected error occurred. Code: ${err.code}, message: ${err.message}`);
                    }
                }
            })
        } catch (caughtError) {
            let err: BusinessError = caughtError as BusinessError;
            console.error(`An unexpected error occurred. Code: ${err.code}, message: ${err.message}`);
        }
    }
    @Trace isHapticFeedbackOn: boolean = true;
    updateHapticFeedbackState(isOn: boolean) {
        this.isHapticFeedbackOn = isOn;
        const value: number = isOn ? 1 : 2;
        try {
            this.sharedPreferences?.putSync("haptic", value);
            this.sharedPreferences?.flush().catch(() => {
                console.error("Failed to save value to the haptic preferences");
            });
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error("Failed to save value to the haptic preferences, message: " + err.message + ", code: " + err.code);
        }
    }

    @Trace keyboardLayout: KeyboardLayout = KeyboardLayout.Qwerty;
    updateKeyboardLayout(layout: KeyboardLayout) {
        if (this.keyboardLayout === layout) {
            return;
        }
        this.keyboardLayout = layout;
        this.clearBuffer();
        this.updateKeyboardCase(KeyboardCase.lowercased);
        try {
            this.sharedPreferences?.putSync("layout", layout);
            this.sharedPreferences?.flush().catch(() => {
                console.error("Failed to save value to the keyboard layout preferences");
            });
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error("Failed to save value to the keyboard layout preferences, message: " + err.message + ", code: " + err.code);
        }
    }

    private async deleteOldDatabases(context: Context) {
        const fileNames: string[] = ["imedb-20260311-tmp.sqlite3", "imedb-20260107-tmp.sqlite3", "imedb-20251217-tmp.sqlite3", "imedb-20251129-tmp.sqlite3"];
        const pathPrefix: string = context.databaseDir + "/rdb/ime/";
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
    private async copyKeyboardDatabase(context: Context) {
        const desFileName: string = "imedb-20260505-tmp.sqlite3";
        const desPath: string = context.databaseDir + "/rdb/ime/" + desFileName;
        try {
            if (fs.accessSync(desPath)) {
                console.debug("keyboard database path: " + desPath);
            } else {
                const srcFileName: string = "imedb.sqlite3";
                const srcPath: string = context.resourceDir + "/" + srcFileName;
                console.debug("src database path: " + srcPath);
                console.debug("des database path: " + desPath);
                await fs.copyFile(srcPath, desPath);
            }
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error("copyKeyboardDatabase() failed, message: " + err.message + ", code: " + err.code);
        }
        this.deleteOldDatabases(context);
    }
    private store: relationalStore.RdbStore | undefined = undefined;
    private async obtainStore() {
        const fileName: string = "imedb-20260505-tmp.sqlite3";
        let storeConfig: relationalStore.StoreConfig = {
            name: fileName,
            securityLevel: relationalStore.SecurityLevel.S1,
            encrypt: false,
            customDir: 'ime',
            isReadOnly: true
        };
        relationalStore.getRdbStore(this.ctx, storeConfig,
            async (err: BusinessError, rdbStore: relationalStore.RdbStore) => {
                if (err) {
                    console.error(`Error in getRdbStore(). message: ${err.message}, code: ${err.code}`);
                    return;
                }
                this.store = rdbStore;
            });
    }
    private isCoreStoreFunctional: boolean = false;
    private async prepareStore() {
        if (this.store) {
            const rowID: number = Researcher.test(this.store);
            if (rowID > 0) {
                this.isCoreStoreFunctional = true;
                return;
            }
            this.isCoreStoreFunctional = false;
            try {
                await this.store.close();
            } catch (error) {
                let err: BusinessError = error as BusinessError;
                console.error("error at closing data store, message: " + err.message + ", code: " + err.code);
            } finally {
                this.store = undefined;
            }
        }
        if (this.ctx) {
            await this.copyKeyboardDatabase(this.ctx);
            await this.obtainStore();
        }
    }
    private async prepareMemory() {
        if (this.memory) {
            InputMemory.prepare(this.memory);
        } else {
            await this.attachMemory();
            if (this.memory) {
                InputMemory.prepare(this.memory);
            }
        }
    }
    private memory: relationalStore.RdbStore | undefined = undefined;
    private async attachMemory() {
        let fileName: string = "memory.sqlite3";
        let storeConfig: relationalStore.StoreConfig = {
            name: fileName,
            securityLevel: relationalStore.SecurityLevel.S1,
            encrypt: false,
            customDir: 'ime',
            isReadOnly: false
        };
        relationalStore.getRdbStore(this.ctx, storeConfig,
            async (err: BusinessError, rdbStore: relationalStore.RdbStore) => {
                if (err) {
                    console.error(`Error in attachMemory(). message: ${err.message}, code: ${err.code}`);
                    return;
                }
                this.memory = rdbStore;
            });
    }
    @Trace isMutilated: boolean = false;
    toggleCharacterScriptVariant() {
        this.isMutilated = !(this.isMutilated);
        const value: number = this.isMutilated ? 51 : 1;
        try {
            this.sharedPreferences?.putSync("charset", value);
            this.sharedPreferences?.flush().catch(() => {
                console.error("Failed to save value to the charset preferences")
            });
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error("Failed to save value to the charset preferences, message: " + err.message + ", code: " + err.code);
        }
    }

    private sharedPreferences: preferences.Preferences | undefined = undefined;
    constructor() {}
    onCreate(context: InputMethodExtensionContext): void {
        this.ctx = context;
        try {
            const defaultDisplay = display.getDefaultDisplaySync();
            this.initWindow(defaultDisplay);
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error("Failed to getDefaultDisplaySync(), message: " + err.message + ", code: " + err.code);
        }
        this.registerListener();
        this.prepareSoundPool();
        this.prepareStore();
        this.prepareMemory();
        setTimeout(() => {
            this.prepareStore();
            this.prepareMemory();
        }, 1000);
        try {
            const options: preferences.Options = { name: "kbsettings" };
            this.sharedPreferences = preferences.getPreferencesSync(context, options);
            const savedAudioFeedbackValue: number = this.sharedPreferences.getSync("audio", 1) as number;
            this.isAudioFeedbackOn = (savedAudioFeedbackValue == 1);
            const savedHapticFeedbackValue: number = this.sharedPreferences.getSync("haptic", 1) as number;
            this.isHapticFeedbackOn = (savedHapticFeedbackValue == 1);
            const savedCharacterStandardValue: number = this.sharedPreferences.getSync("charset", 1) as number;
            this.isMutilated = (savedCharacterStandardValue == 51);
            const savedKeyboardLayoutValue: number = this.sharedPreferences.getSync("layout", KeyboardLayout.Qwerty) as number;
            this.keyboardLayout = KeyboardLayoutCompanion.layoutOf(savedKeyboardLayoutValue);
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error("Failed to load keyboard preferences, message: " + err.message + ", code: " + err.code);
        }
    }
    onDestroy(): void {
        this.releaseSoundPool();
        this.unRegisterListener();
        this.clearBuffer();
        if(this.panel) {
            this.ability.destroyPanel(this.panel);
        }
        if(this.ctx) {
            this.ctx.destroy();
        }
    }
    @Trace candidates: Candidate[] = [];
    private selectedCandidates: Candidate[] = [];
    @Trace isBuffering: boolean = false;
    private bufferEvents: BasicInputEvent[] = [];
    private comboBuffer: Combo[] = [];
    get isBufferEmpty(): boolean {
        const hasBuffer = this.bufferEvents.length > 0 || this.comboBuffer.length > 0;
        if (this.isBuffering != hasBuffer) {
            this.isBuffering = hasBuffer;
        }
        return !hasBuffer
    }
    handle(key: VirtualInputKey) {
        if (InputModeCompanion.isABC(this.inputMode)) {
            const text: string = KeyboardCaseCompanion.isLowercased(this.keyboardCase) ? key.text : key.text.toUpperCase();
            this.insert(text);
        } else {
            const newEvent = new BasicInputEvent(key, this.keyboardCase);
            this.bufferEvents.push(newEvent);
            this.runInputSession();
        }
        if (KeyboardCaseCompanion.isUppercased(this.keyboardCase)) {
            this.updateKeyboardCase(KeyboardCase.lowercased);
        }
    }
    handleNineKey(combo: Combo) {
        if (InputModeCompanion.isABC(this.inputMode)) {
            this.insert(combo.leadingLetter);
            return;
        }
        this.comboBuffer.push(combo);
        this.runInputSession();
    }
    private isTextPreviewSupported: boolean = true;
    @Trace inlinePreEditText: string = "";
    private async runInputSession() {
        this.candidates = [];
        if (this.isBufferEmpty) {
            this.inputClient?.setPreviewText("", { start: -1, end: -1 }).catch(() => { console.error("Failed to setPreviewText()"); });
            this.inputClient?.finishTextPreview().catch(() => { console.error("Failed to finishTextPreview()"); });
            this.inlinePreEditText = "";
            this.selectedCandidates = [];
            if (this.keyboardForm === KeyboardForm.CandidateBoard) {
                this.transformTo(KeyboardForm.Alphabetic);
            }
            return;
        }
        if (this.isNineKeyActive()) {
            this.runNineKeyInputSession();
            return;
        }
        const needsConversion: boolean = this.isMutilated;
        const newCandidates: Candidate[] = [];
        let newLexicons: Lexicon[] = [];
        const keys = this.bufferEvents.map(event => event.key);
        let segmentation: Segmentation = [];
        const isPinyinReverseLookup = this.isPinyinReverseLookup(keys);
        const reverseLookupKeys = isPinyinReverseLookup ? keys.slice(1) : [];
        let pinyinSegmentation: PinyinSegmentation = [];
        if (this.store) {
            if (isPinyinReverseLookup) {
                pinyinSegmentation = PinyinSegmenter.segment(reverseLookupKeys, this.store);
                newLexicons = PinyinResearcher.suggest(reverseLookupKeys, pinyinSegmentation, this.store);
                if (newLexicons.length > 0) {
                    this.isCoreStoreFunctional = true;
                }
            } else {
                segmentation = Segmenter.segment(keys, this.store);
                if (this.memory) {
                    if (this.isCoreStoreFunctional) {
                        newLexicons = InputMemory.suggest(keys, segmentation, this.memory, this.store);
                    } else {
                        const memoryLexicons = InputMemory.search(keys, this.memory);
                        const fallbackLexicons = InputMemory.fallbackSearch(keys, this.memory);
                        newLexicons = [...memoryLexicons, ...fallbackLexicons];
                    }
                } else {
                    this.prepareMemory();
                }
                const queried = await Researcher.suggest(keys, segmentation, this.store);
                if (queried.length > 0) {
                    this.isCoreStoreFunctional = true;
                    newLexicons = Converter.dispatch(newLexicons, queried);
                }
            }
        } else {
            this.prepareStore();
            if (!isPinyinReverseLookup && this.memory) {
                const memoryLexicons = InputMemory.search(keys, this.memory);
                const fallbackLexicons = InputMemory.fallbackSearch(keys, this.memory);
                newLexicons = [...memoryLexicons, ...fallbackLexicons];
            } else if (!isPinyinReverseLookup) {
                this.prepareMemory();
            }
        }
        if (isPinyinReverseLookup) {
            const text = this.joinedBufferTexts();
            this.updatePreviewText(this.buildPinyinReverseLookupPreview(text, reverseLookupKeys, pinyinSegmentation, newLexicons));
        } else {
            const text = this.joinedBufferTexts();
            this.updatePreviewText(this.buildPreviewText(text, keys, segmentation, newLexicons));
        }
        const conversionStore = isPinyinReverseLookup ? this.store : (this.isCoreStoreFunctional ? this.store : this.memory);
        for (let index = 0; index < newLexicons.length; index++) {
            const item = newLexicons[index];
            let instance: Candidate = {
                type: CandidateType.Cantonese,
                text: needsConversion ? Converter.convert(item.text, true, conversionStore) : item.text,
                comment: item.romanization,
                lexicon: item,
                number: index,
            };
            newCandidates.push(instance);
        }
        this.candidates = newCandidates;
    }
    private isNineKeyActive(): boolean {
        return KeyboardLayoutCompanion.isNineKey(this.keyboardLayout) && InputModeCompanion.isCantonese(this.inputMode);
    }
    private runNineKeyInputSession() {
        const needsConversion: boolean = this.isMutilated;
        const newCandidates: Candidate[] = [];
        let newLexicons: Lexicon[] = [];
        const combos = [...this.comboBuffer];
        const isPinyinReverseLookup = this.isNineKeyPinyinReverseLookup(combos);
        const reverseLookupCombos = isPinyinReverseLookup ? combos.slice(1) : [];
        if (this.store) {
            if (isPinyinReverseLookup) {
                newLexicons = NineKeyPinyinResearcher.suggest(reverseLookupCombos, this.store);
            } else {
                newLexicons = NineKeyResearcher.suggest(combos, this.store);
            }
            if (newLexicons.length > 0) {
                this.isCoreStoreFunctional = true;
            }
        } else {
            this.prepareStore();
        }
        if (isPinyinReverseLookup) {
            this.updatePreviewText(this.buildNineKeyPinyinReverseLookupPreview(reverseLookupCombos, newLexicons));
        } else {
            this.updatePreviewText(this.buildNineKeyPreviewText(combos, newLexicons));
        }
        for (let index = 0; index < newLexicons.length; index++) {
            const item = newLexicons[index];
            let instance: Candidate = {
                type: CandidateType.Cantonese,
                text: needsConversion ? Converter.convert(item.text, true, this.store) : item.text,
                comment: item.romanization,
                lexicon: item,
                number: index,
            };
            newCandidates.push(instance);
        }
        this.candidates = newCandidates;
    }
    private joinedBufferTexts(): string {
        return this.bufferEvents.map(event => KeyboardCaseCompanion.isLowercased(event.kbCase) ? event.key.text : event.key.text.toUpperCase()).join("");
    }
    private joinedNineKeyTexts(combos: Combo[] = this.comboBuffer): string {
        return combos.map((combo) => combo.leadingLetter).join("");
    }

    private updatePreviewText(text: string) {
        if (this.isTextPreviewSupported) {
            this.inputClient?.setPreviewText(text, { start: -1, end: -1 }).catch(() => { console.error("Failed to setPreviewText()"); });
        } else {
            this.inlinePreEditText = text;
        }
    }

    private buildPreviewText(bufferText: string, keys: VirtualInputKey[], segmentation: Segmentation, lexicons: Lexicon[]): string {
        if (lexicons.length < 1) {
            return bufferText;
        }
        if (this.isPeculiarInput(keys)) {
            return this.formatPreviewMark(this.toneConvertedText(bufferText));
        }
        const first = lexicons[0];
        if (first.inputCount === keys.length) {
            return first.mark ?? bufferText;
        }
        const bestScheme = segmentation[0];
        if (bestScheme === undefined) {
            return bufferText;
        }
        const leadingLength = this.schemeLength(bestScheme);
        if (leadingLength >= keys.length) {
            return this.schemeMark(bestScheme);
        }
        return `${this.schemeMark(bestScheme)} ${bufferText.slice(leadingLength)}`.trim();
    }

    private isPeculiarInput(keys: VirtualInputKey[]): boolean {
        return this.bufferEvents.some((event) => KeyboardCaseCompanion.isCapitalized(event.kbCase)) || keys.some((key) => !key.isSyllableLetter);
    }
    private toneConvertedText(text: string): string {
        return text
            .replace(/vv/g, "4")
            .replace(/xx/g, "5")
            .replace(/qq/g, "6")
            .replace(/v/g, "1")
            .replace(/x/g, "2")
            .replace(/q/g, "3");
    }
    private formatPreviewMark(text: string): string {
        let result = "";
        for (const character of text) {
            result += character;
            if (!/[A-Za-z]/.test(character)) {
                result += " ";
            }
        }
        return result;
    }
    private schemeLength(scheme: Scheme): number {
        return scheme.reduce((acc, syllable) => acc + syllable.alias.length, 0);
    }
    private schemeMark(scheme: Scheme): string {
        return scheme.map((syllable) => syllable.alias.map((key) => key.text).join("")).join(" ");
    }

    private isPinyinReverseLookup(keys: VirtualInputKey[]): boolean {
        return keys.length > 0 && keys[0] === VirtualInputKey.letterR;
    }

    private buildPinyinReverseLookupPreview(bufferText: string, keys: VirtualInputKey[], segmentation: PinyinSegmentation,
        lexicons: Lexicon[]): string {
        if (lexicons.length < 1) {
            return bufferText;
        }
        const first = lexicons[0];
        const prefix = bufferText.slice(0, 1);
        const reverseText = bufferText.slice(1);
        if (first.inputCount === keys.length) {
            return `${prefix} ${(first.mark ?? reverseText)}`.trim();
        }
        const bestScheme = segmentation[0];
        if (bestScheme === undefined) {
            return bufferText;
        }
        const leadingLength = PinyinSegmenter.schemeLength(bestScheme);
        if (leadingLength >= keys.length) {
            return `${prefix} ${PinyinSegmenter.schemeMark(bestScheme)}`.trim();
        }
        const tail = reverseText.slice(leadingLength);
        return `${prefix} ${PinyinSegmenter.schemeMark(bestScheme)} ${tail}`.trim();
    }
    private buildNineKeyPreviewText(combos: Combo[], lexicons: Lexicon[]): string {
        const bufferText = this.joinedNineKeyTexts(combos);
        if (lexicons.length < 1) {
            return bufferText;
        }
        const first = lexicons[0];
        if (first.inputCount >= combos.length) {
            return first.mark ?? bufferText;
        }
        const tail = this.joinedNineKeyTexts(combos.slice(first.inputCount));
        return `${first.mark ?? bufferText} ${tail}`.trim();
    }
    private isNineKeyPinyinReverseLookup(combos: Combo[]): boolean {
        return combos.length > 0 && combos[0]?.isSpecial;
    }
    private buildNineKeyPinyinReverseLookupPreview(combos: Combo[], lexicons: Lexicon[]): string {
        const prefix = Combo.Special.leadingLetter;
        const reverseText = this.joinedNineKeyTexts(combos);
        if (lexicons.length < 1) {
            return combos.length < 1 ? prefix : `${prefix} ${reverseText}`.trim();
        }
        const first = lexicons[0];
        if (first.inputCount >= combos.length) {
            return `${prefix} ${first.mark ?? reverseText}`.trim();
        }
        const tail = this.joinedNineKeyTexts(combos.slice(first.inputCount));
        return `${prefix} ${first.mark ?? reverseText} ${tail}`.trim();
    }

    selectCandidateBy(index: number) {
        if (this.candidates.length > index) {
            this.consumeCandidate(this.candidates[index]);
        }
    }
    selectCandidate(selected: Candidate) {
        const candidate = this.candidates.find((item) => item.text === selected.text && item.comment === selected.comment);
        if (candidate) {
            this.consumeCandidate(candidate);
        }
    }

    private consumeCandidate(candidate: Candidate) {
        if (this.isNineKeyActive()) {
            this.consumeNineKeyCandidate(candidate);
            return;
        }
        this.insert(candidate.text);
        if (this.isPinyinReverseLookup(this.bufferEvents.map((event) => event.key))) {
            this.selectedCandidates = [];
            let tailEvents = this.bufferEvents.slice(candidate.lexicon.inputCount + 1);
            while (tailEvents.length > 0 && tailEvents[0].key.isApostrophe) {
                tailEvents = tailEvents.slice(1);
            }
            if (tailEvents.length < 1) {
                this.clearBuffer();
                return;
            }
            this.bufferEvents = [this.bufferEvents[0], ...tailEvents];
            this.runInputSession();
            return;
        }
        this.selectedCandidates.push(candidate);
        const inputLength = candidate.lexicon.inputCount;
        this.bufferEvents.splice(0, inputLength);
        if (this.bufferEvents.length < 1) {
            if (this.memory) {
                InputMemory.process(this.selectedCandidates, this.memory);
            }
            this.selectedCandidates = [];
        }
        this.runInputSession();
    }
    private consumeNineKeyCandidate(candidate: Candidate) {
        this.insert(candidate.text);
        if (this.isNineKeyPinyinReverseLookup(this.comboBuffer)) {
            this.selectedCandidates = [];
            const tailCombos = this.comboBuffer.slice(candidate.lexicon.inputCount + 1);
            if (tailCombos.length < 1) {
                this.clearBuffer();
                return;
            }
            this.comboBuffer = [this.comboBuffer[0], ...tailCombos];
            this.runInputSession();
            return;
        }
        this.selectedCandidates.push(candidate);
        this.comboBuffer = this.comboBuffer.slice(candidate.lexicon.inputCount);
        if (this.comboBuffer.length < 1) {
            if (this.memory) {
                InputMemory.process(this.selectedCandidates, this.memory);
            }
            this.selectedCandidates = [];
        }
        this.runInputSession();
    }
    process(text: string) {
        this.inputClient?.insertText(text).catch(() => {
            console.error("Failed to insertText()");
        });
    }
    insert(text: string) {
        this.inputClient?.insertText(text).catch(() => {
            console.error("Failed to insertText()");
        });
    }
    backspace(length: number = 1) {
        if (this.isBufferEmpty) {
            this.inputClient?.deleteForward(length).catch(() => {
                console.error("Failed to deleteForward()");
            });
        } else {
            if (this.isNineKeyActive()) {
                this.comboBuffer.pop();
            } else {
                this.bufferEvents.pop();
            }
            this.runInputSession();
        }
    }
    clearBuffer() {
        this.bufferEvents = [];
        this.comboBuffer = [];
        this.runInputSession();
    }
    rightDelete(length: number = 1) {
        this.inputClient?.deleteBackward(length).catch(() => {
            console.error("Failed to deleteBackward()");
        });
    }
    space() {
        if (this.candidates.length > 0) {
            this.selectCandidateBy(0);
        } else if (this.isBuffering) {
            if (this.isTextPreviewSupported) {
                this.inputClient?.finishTextPreview().catch(() => { console.error("Failed to finishTextPreview()"); });
            } else {
                const text: string = this.isNineKeyActive() ? this.joinedNineKeyTexts() : this.joinedBufferTexts();
                this.insert(text);
            }
            this.clearBuffer();
        } else {
            let text = " ";
            this.insert(text);
        }
    }
    enterKeyAction() {
        if (this.isBuffering) {
            if (this.isTextPreviewSupported) {
                this.inputClient?.finishTextPreview().catch(() => { console.error("Failed to finishTextPreview()"); });
            } else {
                const text: string = this.isNineKeyActive() ? this.joinedNineKeyTexts() : this.joinedBufferTexts();
                this.insert(text);
            }
            this.clearBuffer();
        } else {
            let actionCode = this.attribute?.enterKeyType ?? inputMethodEngine.ENTER_KEY_TYPE_DONE;
            this.inputClient?.sendKeyFunction(actionCode).catch(() => {
                console.error(`Failed to sendKeyFunction() in enterKeyAction(), actionCode: ${actionCode}`);
            })
        }
    }
    dismissKeyboard() {
        this.panel?.hide();
    }

    @Trace keyboardForm: KeyboardForm = KeyboardForm.Alphabetic;
    @Trace previousKeyboardForm: KeyboardForm = KeyboardForm.Alphabetic;
    transformTo(destination: KeyboardForm) {
        this.previousKeyboardForm = this.keyboardForm;
        this.keyboardForm = destination;
    }

    @Trace inputMode: InputMode = InputMode.Cantonese;
    toggleInputMode() {
        this.inputMode = InputModeCompanion.isCantonese(this.inputMode) ? InputMode.ABC : InputMode.Cantonese;
    }

    @Trace keyboardCase: KeyboardCase = KeyboardCase.lowercased;
    updateKeyboardCase(newCase: KeyboardCase) {
        this.keyboardCase = newCase;
    }
    shift() {
        const newCase: KeyboardCase = KeyboardCaseCompanion.isCapitalized(this.keyboardCase) ? KeyboardCase.lowercased : KeyboardCase.uppercased;
        this.updateKeyboardCase(newCase);
    }
    doubleShift() {
        const newCase: KeyboardCase = KeyboardCaseCompanion.isCapsLocked(this.keyboardCase) ? KeyboardCase.lowercased : KeyboardCase.capsLocked;
        this.updateKeyboardCase(newCase);
    }

    @Trace keyHeight: Length = 53;
    @Trace keyboardHeight: Length = 268;
    @Trace isPhoneLandscape: boolean | undefined = undefined;
    private initWindow(screen: display.Display) {
        if(this.ctx === undefined) {
            return;
        }
        const panelHeight = this.responsiveKeyboard(screen);
        const panelInfo: inputMethodEngine.PanelInfo = {
            type: inputMethodEngine.PanelType.SOFT_KEYBOARD,
            flag: inputMethodEngine.PanelFlag.FLG_FIXED
        };
        this.ability.createPanel(this.ctx, panelInfo)
            .then(async (inputPanel: inputMethodEngine.Panel) => {
                this.panel = inputPanel;
                if(this.panel) {
                    await this.panel.resize(screen.width, panelHeight);
                    await this.panel.setUiContent('InputMethodExtensionAbility/pages/Index');
                }
            })
            .catch(() => { console.error("Failed to createPanel()"); });
    }
    private responsiveKeyboard(screen: display.Display): number | undefined {
        const displayWidth = screen.width;
        const displayHeight = screen.height;
        const density = screen.scaledDensity;
        const widthInPoint = displayWidth / density;
        const heightInPoint = displayHeight / density;
        const minDimension = Math.min(widthInPoint, heightInPoint);
        const isLandscape = (widthInPoint > heightInPoint) && (minDimension < 500);
        if (this.isPhoneLandscape === isLandscape) {
            return;
        }
        this.isPhoneLandscape = isLandscape;
        const toolBarHeight = 56;
        const landscapeKeyHeight = 36;
        const portraitKeyHeight = 53 + Math.floor((widthInPoint - 300) / 20);
        this.keyHeight = isLandscape ? landscapeKeyHeight : portraitKeyHeight;
        this.keyboardHeight = (this.keyHeight * 4) + toolBarHeight;
        const panelHeight = this.keyboardHeight * density;
        return panelHeight;
    }

    private registerListener() {
        this.ability.on('inputStart', (kbController, inputClient) => {
            this.inputClient = inputClient;
            try {
                this.attribute = inputClient.getEditorAttributeSync();
                this.isTextPreviewSupported = this.attribute.isTextPreviewSupported;
            } catch (error) {
                console.error("Failed to getEditorAttributeSync()");
            }
            try {
                const screen = display.getDefaultDisplaySync();
                const panelHeight = this.responsiveKeyboard(screen);
                if (panelHeight) {
                    this.panel?.resize(screen.width, panelHeight);
                    this.panel?.setUiContent('InputMethodExtensionAbility/pages/Index');
                }
            } catch (error) {
                let err: BusinessError = error as BusinessError;
                console.error(`Failed to responsive keyboard, error: ${err.message}}, code: ${err.code}}`);
            }
            this.keyboardController = kbController;
        })
        this.ability.on('inputStop', () => {
            this.onDestroy();
        });
        this.ability.on('keyboardHide', () => {
            this.clearBuffer();
            this.updateKeyboardCase(KeyboardCase.lowercased);
            this.transformTo(KeyboardForm.Alphabetic);
            this.inputMode = InputMode.Cantonese;
        })
    }
    private unRegisterListener() {
        this.ability.off('inputStart');
        this.ability.off('inputStop', () => {});
        this.ability.off('keyboardHide', () => {});
    }

    performEditing(action: EditingAction) {
        switch (action) {
            case EditingAction.Paste:
                this.inputClient?.sendExtendAction(inputMethodEngine.ExtendAction.PASTE).catch(() => { console.error("Failed to send PASTE action") });
                break;
            case EditingAction.ClearSystemClipboard:
                pasteboard.getSystemPasteboard().clearData();
                break;
            case EditingAction.CopyAllText:
                this.inputClient?.sendExtendAction(inputMethodEngine.ExtendAction.SELECT_ALL).catch(() => { console.error("Failed to send SELECT_ALL action") });
                this.inputClient?.sendExtendAction(inputMethodEngine.ExtendAction.COPY).catch(() => { console.error("Failed to send COPY action") });
                this.inputClient?.moveCursor(inputMethodEngine.Direction.CURSOR_DOWN).catch(() => { console.error("Failed to send CURSOR_DOWN action") });
                break;
            case EditingAction.CutAllText:
                this.inputClient?.sendExtendAction(inputMethodEngine.ExtendAction.SELECT_ALL).catch(() => { console.error("Failed to send SELECT_ALL action") });
                this.inputClient?.sendExtendAction(inputMethodEngine.ExtendAction.CUT).catch(() => { console.error("Failed to send CUT action") });
                break;
            case EditingAction.ClearAllText:
                this.inputClient?.sendExtendAction(inputMethodEngine.ExtendAction.SELECT_ALL).catch(() => { console.error("Failed to send SELECT_ALL action") });
                this.inputClient?.deleteForward(1).catch(() => { console.error("Failed to deleteForward()") });
                break;
            case EditingAction.ConvertAllText:
                break;
            case EditingAction.MoveLeft:
                this.inputClient?.moveCursor(inputMethodEngine.Direction.CURSOR_LEFT).catch(() => { console.error("Failed to MoveLeft") });
                break;
            case EditingAction.MoveRight:
                this.inputClient?.moveCursor(inputMethodEngine.Direction.CURSOR_RIGHT).catch(() => { console.error("Failed to MoveRight") });
                break;
            case EditingAction.MoveUp:
                this.inputClient?.moveCursor(inputMethodEngine.Direction.CURSOR_UP).catch(() => { console.error("Failed to MoveUp") });
                break;
            case EditingAction.MoveDown:
                this.inputClient?.moveCursor(inputMethodEngine.Direction.CURSOR_DOWN).catch(() => { console.error("Failed to MoveDown") });
                break;
            case EditingAction.JumpToStart:
                this.inputClient?.moveCursor(inputMethodEngine.Direction.CURSOR_UP).catch(() => { console.error("Failed to JumpToStart") });
                break;
            case EditingAction.JumpToEnd:
                this.inputClient?.moveCursor(inputMethodEngine.Direction.CURSOR_DOWN).catch(() => { console.error("Failed to JumpToEnd") });
                break;
            default:
                break;
        }
    }
}

const controller = new InputController();
export default controller;
