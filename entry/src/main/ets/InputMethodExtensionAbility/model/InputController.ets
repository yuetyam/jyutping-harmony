import { display } from '@kit.ArkUI';
import { inputMethodEngine, InputMethodExtensionContext } from '@kit.IMEKit';
import { audio } from '@kit.AudioKit';
import { media } from '@kit.MediaKit';
import { InputKeyEvent } from './InputKeyEvent';
import { InputMode } from './InputMode';
import { KeyboardForm } from './KeyboardForm';

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
    handle(event: InputKeyEvent): void {
        this.inputClient?.insertText(event.text).catch(() => {
            // TODO: Implement error handling.
        });
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
        this.inputClient?.deleteForward(length).catch(() => {
            // TODO: Implement error handling.
        });
    }
    rightDelete(length: number = 1): void {
        this.inputClient?.deleteBackward(length).catch(() => {
            // TODO: Implement error handling.
        });
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
    transformTo(destination: KeyboardForm): void {
        this.keyboardForm = destination;
    }

    @Trace inputMode: InputMode = InputMode.Cantonese;
    updateInputMode(newInputMode: InputMode): void {
        this.inputMode = newInputMode;
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
}

const controller = new InputController();
export default controller;
