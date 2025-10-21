import { display } from '@kit.ArkUI';
import { relationalStore } from '@kit.ArkData';
import { bundleManager } from '@kit.AbilityKit';
import { audio } from '@kit.AudioKit';
import { BusinessError, pasteboard } from '@kit.BasicServicesKit'
import { inputMethodEngine, InputMethodExtensionContext } from '@kit.IMEKit';
import { media } from '@kit.MediaKit';
import { InputKeyEvent } from './model/InputKeyEvent';
import { InputMode, InputModeCompanion } from './model/InputMode';
import { KeyboardForm } from './model/KeyboardForm';
import { Researcher } from './model/Researcher';
import { Candidate } from './model/Candidate';
import { CandidateType } from './model/CandidateType';
import { EditingAction } from './editing/EditingAction';
import { KeyboardCase } from './model/KeyboardCase';

const inputMethodAbility: inputMethodEngine.InputMethodAbility = inputMethodEngine.getInputMethodAbility();

@ObservedV2
export class InputController {
    private ctx: InputMethodExtensionContext | undefined = undefined;
    private panel: inputMethodEngine.Panel | undefined = undefined;
    private attribute: inputMethodEngine.EditorAttribute | undefined = undefined
    private inputClient: inputMethodEngine.InputClient | undefined = undefined;
    private keyboardController: inputMethodEngine.KeyboardController | undefined = undefined;

    private soundPool: media.SoundPool | undefined = undefined;
    private inputSoundID: number = 0;
    private inputStreamID: number = 0;
    private modifierSoundID: number = 0;
    private modifierStreamID: number = 0;
    private deleteSoundID: number = 0;
    private deleteStreamID: number = 0;
    async prepareSoundPool() {
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
    async releaseSoundPool() {
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

    private store: relationalStore.RdbStore | undefined = undefined;
    private async obtainStore() {
        let bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
        let fileName: string = `imedb-${bundleInfo.versionName}-${bundleInfo.versionCode}-tmp.sqlite3`;
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
    private async prepareStore() {
        if (this.store === undefined) {
            this.obtainStore();
        } else if (this.store.version < 1) {
            this.obtainStore();
        }
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
    }
    onDestroy(): void {
        this.releaseSoundPool();
        this.unRegisterListener();
        if(this.panel) {
            inputMethodAbility.destroyPanel(this.panel);
        }
        if(this.ctx) {
            this.ctx.destroy();
        }
    }
    @Trace candidates: Candidate[] = [];
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
            this.insert(event.text);
        } else {
            this.bufferEvents.push(event);
            this.runInputSession();
        }
    }
    private async runInputSession() {
        if (this.isBufferEmpty) {
            this.candidates = [];
            return;
        }
        if (this.store) {
            const items = await Researcher.search(this.bufferEvents, this.store);
            this.candidates = items.map((item) => {
                let instance: Candidate = {
                    type: CandidateType.Cantonese,
                    text: item.text,
                    comment: item.romanization,
                    lexicon: item
                };
                return instance;
            });
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
            let first = this.candidates[0];
            let text = first.text;
            this.insert(text);
            let inputLength = first.lexicon.inputCount;
            let startIndex = this.bufferEvents.length - inputLength;
            this.bufferEvents.splice(startIndex, inputLength);
            this.runInputSession();
        } else {
            let text = " ";
            this.insert(text);
        }
    }
    enterKeyAction(): void {
        let actionCode = this.attribute?.enterKeyType ?? inputMethodEngine.ENTER_KEY_TYPE_DONE;
        this.inputClient?.sendKeyFunction(actionCode).catch(() => {
            // TODO: Implement error handling.
        })
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
    updateInputMode(newInputMode: InputMode): void {
        this.inputMode = newInputMode;
    }

    @Trace keyboardCase: KeyboardCase = KeyboardCase.lowercased;
    updateKeyboardCase(newCase: KeyboardCase): void {
        this.keyboardCase = newCase;
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
        let widthInPoint = displayWidth / density;
        let keyHeight = 53 + Math.floor((widthInPoint - 300) / 20);
        let keyboardHeight = keyHeight * 4 + 56;
        this.keyHeight = keyHeight;
        this.keyboardHeight = keyboardHeight;
        let panelHeight = keyboardHeight * density;
        let nonBarPosition = displayHeight - panelHeight;
        let panelInfo: inputMethodEngine.PanelInfo = {
            type: inputMethodEngine.PanelType.SOFT_KEYBOARD,
            flag: inputMethodEngine.PanelFlag.FLG_FIXED
        };
        inputMethodAbility.createPanel(this.ctx, panelInfo)
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
        inputMethodAbility.on('inputStart', (kbController, inputClient) => {
            this.inputClient = inputClient;
            try {
                this.attribute = inputClient.getEditorAttributeSync()
            } catch (error) {
                // TODO: Implement error handling.
            }
            this.keyboardController = kbController;
        })
        inputMethodAbility.on('inputStop', () => {
            this.onDestroy();
        });
    }
    private unRegisterListener(): void {
        inputMethodAbility.off('inputStart');
        inputMethodAbility.off('inputStop', () => {});
    }

    performEditing(action: EditingAction): void {
        switch (action) {
            case EditingAction.Paste:
                this.inputClient?.sendExtendAction(inputMethodEngine.ExtendAction.PASTE).catch(() => {
                    // TODO: Implement error handling.
                });
                break
            case EditingAction.ClearSystemClipboard:
                pasteboard.getSystemPasteboard().clearData();
                break
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
                break
            case EditingAction.CutAllText:
                this.inputClient?.sendExtendAction(inputMethodEngine.ExtendAction.SELECT_ALL).catch(() => {
                    // TODO: Implement error handling.
                });
                this.inputClient?.sendExtendAction(inputMethodEngine.ExtendAction.CUT).catch(() => {
                    // TODO: Implement error handling.
                });
                break
            case EditingAction.ClearAllText:
                this.inputClient?.sendExtendAction(inputMethodEngine.ExtendAction.SELECT_ALL).catch(() => {
                    // TODO: Implement error handling.
                });
                this.inputClient?.deleteForward(1).catch(() => {
                    // TODO: Implement error handling.
                });
                break
            case EditingAction.ConvertAllText:
                // TODO: Traditional-Simplified conversion
                let text: string = "Implement T-S conversion";
                this.insert(text);
                break
            case EditingAction.MoveLeft:
                this.inputClient?.moveCursor(inputMethodEngine.Direction.CURSOR_LEFT).catch(() => {
                    // TODO: Implement error handling.
                });
                break
            case EditingAction.MoveRight:
                this.inputClient?.moveCursor(inputMethodEngine.Direction.CURSOR_RIGHT).catch(() => {
                    // TODO: Implement error handling.
                });
                break
            case EditingAction.MoveUp:
                this.inputClient?.moveCursor(inputMethodEngine.Direction.CURSOR_UP).catch(() => {
                    // TODO: Implement error handling.
                });
                break
            case EditingAction.MoveDown:
                this.inputClient?.moveCursor(inputMethodEngine.Direction.CURSOR_DOWN).catch(() => {
                    // TODO: Implement error handling.
                });
                break
            case EditingAction.JumpToStart:
                this.inputClient?.moveCursor(inputMethodEngine.Direction.CURSOR_UP).catch(() => {
                    // TODO: Implement error handling.
                });
                break
            case EditingAction.JumpToEnd:
                this.inputClient?.moveCursor(inputMethodEngine.Direction.CURSOR_DOWN).catch(() => {
                    // TODO: Implement error handling.
                });
                break
            default:
                break
        }
    }
}

const controller = new InputController();
export default controller;
