import { display } from '@kit.ArkUI';
import { relationalStore } from '@kit.ArkData';
import { audio } from '@kit.AudioKit';
import { BusinessError, pasteboard } from '@kit.BasicServicesKit'
import { fileIo as fs } from '@kit.CoreFileKit';
import { inputMethodEngine, InputMethodExtensionContext } from '@kit.IMEKit';
import { media } from '@kit.MediaKit';
import { InputKeyEvent } from './model/InputKeyEvent';
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
            let inputDescriptor = await this.ctx?.resourceManager.getRawFd('click.m4a').catch(() => {
                // TODO: Implement error handling.
            });
            if (inputDescriptor) {
                this.inputSoundID = await this.soundPool.load(inputDescriptor.fd, inputDescriptor.offset, inputDescriptor.length);
            }
            let clickDescriptor = await this.ctx?.resourceManager.getRawFd('modifier.m4a').catch(() => {
                // TODO: Implement error handling.
            });
            if (clickDescriptor) {
                this.modifierSoundID = await this.soundPool.load(clickDescriptor.fd, clickDescriptor.offset, clickDescriptor.length);
            }
            let deleteDescriptor = await this.ctx?.resourceManager.getRawFd('delete.m4a').catch(() => {
                // TODO: Implement error handling.
            });
            if (deleteDescriptor) {
                this.deleteSoundID = await this.soundPool.load(deleteDescriptor.fd, deleteDescriptor.offset, deleteDescriptor.length);
            }
        } catch (e) {
            console.error('createSoundPool error: ' + e);
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
        } catch (e) {
            console.error('createSoundPool error: ' + e);
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
        this.soundPool?.play(this.inputSoundID, this.playParameters, (error, streamID: number) => {
            if (error) {
                console.error(`play sound Error: errCode is ${error.code}, errMessage is ${error.message}`)
            } else {
                this.inputStreamID = streamID;
            }
        });
    }
    playModifierSound() {
        this.soundPool?.play(this.modifierSoundID, this.playParameters, (error, streamID: number) => {
            if (error) {
                console.error(`play sound Error: errCode is ${error.code}, errMessage is ${error.message}`)
            } else {
                this.modifierStreamID = streamID;
            }
        });
    }
    playDeleteSound() {
        this.soundPool?.play(this.deleteSoundID, this.playParameters, (error, streamID: number) => {
            if (error) {
                console.error(`play sound Error: errCode is ${error.code}, errMessage is ${error.message}`)
            } else {
                this.deleteStreamID = streamID;
            }
        });
    }

    private async deleteOldDatabases(context: Context) {
        const fileNames: string[] = ["imedb-20251125-tmp.sqlite3"];
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
        const srcFileName: string = "imedb.sqlite3";
        const desFileName: string = "imedb-20251129-tmp.sqlite3";
        const srcPath: string = context.resourceDir + "/" + srcFileName;
        const desPath: string = context.databaseDir + "/rdb/ime/" + desFileName;
        try {
            if (fs.accessSync(desPath)) {
                console.debug("keyboard database path: " + desPath);
            } else {
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
        const fileName: string = "imedb-20251129-tmp.sqlite3";
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
    }

    constructor() {}
    onCreate(context: InputMethodExtensionContext): void {
        this.ctx = context;
        try {
            let defaultDisplay = display.getDefaultDisplaySync();
            this.initWindow(defaultDisplay)
        } catch (error) {
            // TODO: Implement error handling.
        }
        this.registerListener();
        this.prepareSoundPool();
        this.prepareStore();
        this.prepareMemory();
        setTimeout(() => {
            this.prepareStore();
            this.prepareMemory();
        }, 1000);
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
    @Trace markedText: string = "";
    @Trace isBuffering: boolean = false;
    private bufferEvents: InputKeyEvent[] = [];
    get isBufferEmpty(): boolean {
        const hasBuffer = this.bufferEvents.length > 0;
        if (this.isBuffering != hasBuffer) {
            this.isBuffering = hasBuffer;
        }
        return !hasBuffer
    }
    handle(event: InputKeyEvent): void {
        if (InputModeCompanion.isABC(this.inputMode)) {
            const text: string = KeyboardCaseCompanion.isLowercased(this.keyboardCase) ? event.text : event.text.toUpperCase();
            this.insert(text);
        } else {
            this.bufferEvents.push(event);
            this.runInputSession();
        }
    }
    private async runInputSession() {
        this.candidates = [];
        if (this.isBufferEmpty) {
            this.markedText = "";
            this.selectedCandidates = [];
            if (this.keyboardForm === KeyboardForm.CandidateBoard) {
                this.transformTo(KeyboardForm.Alphabetic);
            }
            return;
        }
        this.markedText = this.bufferEvents.map(item => item.text).join("");
        const needsConversion: boolean = this.isMutilated;
        const newCandidates: Candidate[] = [];
        let newLexicons: Lexicon[] = [];
        if (this.memory) {
            if (this.isCoreStoreFunctional) {
                newLexicons = InputMemory.search(this.bufferEvents, this.memory);
            } else {
                const memoryLexicons = InputMemory.search(this.bufferEvents, this.memory);
                const fallbackLexicons = InputMemory.fallbackSearch(this.bufferEvents, this.memory);
                newLexicons = [...memoryLexicons, ...fallbackLexicons];
            }
        } else {
            this.prepareMemory();
        }
        if (this.store) {
            const searched = await Researcher.search(this.bufferEvents, this.store);
            if (searched.length > 0) {
                this.isCoreStoreFunctional = true;
                newLexicons = newLexicons.concat(searched);
                // sort((a, b) => b.inputCount - a.inputCount);
            }
        } else {
            this.prepareStore();
        }
        for (let index = 0; index < newLexicons.length; index++) {
            const item = newLexicons[index];
            let instance: Candidate = {
                type: CandidateType.Cantonese,
                text: needsConversion ? Converter.convert(item.text, true, this.memory) : item.text,
                comment: item.romanization,
                lexicon: item,
                number: index,
            };
            newCandidates.push(instance);
        }
        this.candidates = newCandidates;
    }
    selectCandidateBy(index: number) {
        if (this.candidates.length > index) {
            const selected = this.candidates[index];
            const text = selected.text;
            this.insert(text);
            this.selectedCandidates.push(selected);
            const inputLength = selected.lexicon.inputCount;
            this.bufferEvents.splice(0, inputLength);
            if (this.bufferEvents.length < 1) {
                if (this.memory) {
                    InputMemory.process(this.selectedCandidates, this.memory);
                }
                this.selectedCandidates = [];
            }
            this.runInputSession();
        }
    }
    selectCandidate(selected: Candidate) {
        const candidate = this.candidates.find((item) => item.text === selected.text && item.comment === selected.comment);
        if (candidate) {
            const text = candidate.text;
            this.insert(text);
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
    }
    process(text: string): void {
        this.inputClient?.insertText(text).catch(() => {
            // TODO: Implement error handling.
        });
    }
    insert(text: string): void {
        this.inputClient?.insertText(text).catch(() => {
            // TODO: Implement error handling.
        });
    }
    backspace(length: number = 1): void {
        if (this.isBufferEmpty) {
            this.inputClient?.deleteForward(length).catch(() => {
                // TODO: Implement error handling.
            });
        } else {
            this.bufferEvents.pop();
            this.runInputSession();
        }
    }
    clearBuffer(): void {
        this.bufferEvents = [];
        this.runInputSession();
    }
    rightDelete(length: number = 1): void {
        this.inputClient?.deleteBackward(length).catch(() => {
            // TODO: Implement error handling.
        });
    }
    space(): void {
        if (this.candidates.length > 0) {
            this.selectCandidateBy(0);
        } else {
            let text = " ";
            this.insert(text);
        }
    }
    enterKeyAction(): void {
        if (this.isBuffering) {
            const text = this.bufferEvents.map(event => event.text).join('');
            this.insert(text);
            this.clearBuffer();
        } else {
            let actionCode = this.attribute?.enterKeyType ?? inputMethodEngine.ENTER_KEY_TYPE_DONE;
            this.inputClient?.sendKeyFunction(actionCode).catch(() => {
                console.error(`Failed to sendKeyFunction() in enterKeyAction(), actionCode: ${actionCode}`);
            })
        }
    }
    dismissKeyboard(): void {
        this.panel?.hide();
    }

    @Trace keyboardForm: KeyboardForm = KeyboardForm.Alphabetic;
    @Trace previousKeyboardForm: KeyboardForm = KeyboardForm.Alphabetic;
    transformTo(destination: KeyboardForm): void {
        this.previousKeyboardForm = this.keyboardForm;
        this.keyboardForm = destination;
    }

    @Trace inputMode: InputMode = InputMode.Cantonese;
    toggleInputMode(): void {
        this.inputMode = InputModeCompanion.isCantonese(this.inputMode) ? InputMode.ABC : InputMode.Cantonese;
    }

    @Trace keyboardCase: KeyboardCase = KeyboardCase.lowercased;
    updateKeyboardCase(newCase: KeyboardCase): void {
        this.keyboardCase = newCase;
    }
    shift() {
        const newCase: KeyboardCase = KeyboardCaseCompanion.isCapitalized(this.keyboardCase) ? KeyboardCase.lowercased : KeyboardCase.uppercased;
        this.updateKeyboardCase(newCase);
    }

    @Trace keyHeight: Length = 53;
    @Trace keyboardHeight: Length = 268;
    private initWindow(screen: display.Display): void {
        if(this.ctx === undefined) {
            return;
        }
        let displayWidth = screen.width;
        let displayHeight = screen.height;
        let density = screen.scaledDensity;
        const widthInPoint = displayWidth / density;
        const keyHeight = 53 + Math.floor((widthInPoint - 300) / 20);
        const toolBarHeight = 56;
        const bufferBarHeight = 13;
        const keyboardHeight = (keyHeight * 4) + toolBarHeight + bufferBarHeight;
        this.keyHeight = keyHeight;
        this.keyboardHeight = keyboardHeight;
        const panelHeight = keyboardHeight * density;
        const nonBarPosition = displayHeight - panelHeight;
        let panelInfo: inputMethodEngine.PanelInfo = {
            type: inputMethodEngine.PanelType.SOFT_KEYBOARD,
            flag: inputMethodEngine.PanelFlag.FLG_FIXED
        };
        this.ability.createPanel(this.ctx, panelInfo)
            .then(async (inputPanel: inputMethodEngine.Panel) => {
                this.panel = inputPanel;
                if(this.panel) {
                    await this.panel.resize(displayWidth, panelHeight);
                    await this.panel.moveTo(0, nonBarPosition);
                    await this.panel.setUiContent('InputMethodExtensionAbility/pages/Index');
                }
            })
            .catch(() => {
                // TODO: Implement error handling.
            });
    }

    private registerListener(): void {
        this.ability.on('inputStart', (kbController, inputClient) => {
            this.inputClient = inputClient;
            try {
                this.attribute = inputClient.getEditorAttributeSync()
            } catch (error) {
                // TODO: Implement error handling.
            }
            this.keyboardController = kbController;
        })
        this.ability.on('inputStop', () => {
            this.onDestroy();
        });
        this.ability.on('keyboardHide', () => {
            this.clearBuffer();
            this.keyboardCase = KeyboardCase.lowercased;
        })
    }
    private unRegisterListener(): void {
        this.ability.off('inputStart');
        this.ability.off('inputStop', () => {});
        this.ability.off('keyboardHide', () => {});
    }

    performEditing(action: EditingAction): void {
        switch (action) {
            case EditingAction.Paste:
                this.inputClient?.sendExtendAction(inputMethodEngine.ExtendAction.PASTE).catch(() => {
                    // TODO: Implement error handling.
                });
                break;
            case EditingAction.ClearSystemClipboard:
                pasteboard.getSystemPasteboard().clearData();
                break;
            case EditingAction.CopyAllText:
                this.inputClient?.sendExtendAction(inputMethodEngine.ExtendAction.SELECT_ALL).catch(() => {
                    // TODO: Implement error handling.
                });
                this.inputClient?.sendExtendAction(inputMethodEngine.ExtendAction.COPY).catch(() => {
                    // TODO: Implement error handling.
                });
                this.inputClient?.moveCursor(inputMethodEngine.Direction.CURSOR_DOWN).catch(() => {
                    // TODO: Implement error handling.
                });
                break;
            case EditingAction.CutAllText:
                this.inputClient?.sendExtendAction(inputMethodEngine.ExtendAction.SELECT_ALL).catch(() => {
                    // TODO: Implement error handling.
                });
                this.inputClient?.sendExtendAction(inputMethodEngine.ExtendAction.CUT).catch(() => {
                    // TODO: Implement error handling.
                });
                break;
            case EditingAction.ClearAllText:
                this.inputClient?.sendExtendAction(inputMethodEngine.ExtendAction.SELECT_ALL).catch(() => {
                    // TODO: Implement error handling.
                });
                this.inputClient?.deleteForward(1).catch(() => {
                    // TODO: Implement error handling.
                });
                break;
            case EditingAction.ConvertAllText:
                break;
            case EditingAction.MoveLeft:
                this.inputClient?.moveCursor(inputMethodEngine.Direction.CURSOR_LEFT).catch(() => {
                    // TODO: Implement error handling.
                });
                break;
            case EditingAction.MoveRight:
                this.inputClient?.moveCursor(inputMethodEngine.Direction.CURSOR_RIGHT).catch(() => {
                    // TODO: Implement error handling.
                });
                break;
            case EditingAction.MoveUp:
                this.inputClient?.moveCursor(inputMethodEngine.Direction.CURSOR_UP).catch(() => {
                    // TODO: Implement error handling.
                });
                break;
            case EditingAction.MoveDown:
                this.inputClient?.moveCursor(inputMethodEngine.Direction.CURSOR_DOWN).catch(() => {
                    // TODO: Implement error handling.
                });
                break;
            case EditingAction.JumpToStart:
                this.inputClient?.moveCursor(inputMethodEngine.Direction.CURSOR_UP).catch(() => {
                    // TODO: Implement error handling.
                });
                break;
            case EditingAction.JumpToEnd:
                this.inputClient?.moveCursor(inputMethodEngine.Direction.CURSOR_DOWN).catch(() => {
                    // TODO: Implement error handling.
                });
                break;
            default:
                break;
        }
    }
}

const controller = new InputController();
export default controller;
