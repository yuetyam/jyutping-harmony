import { display } from '@kit.ArkUI';
import { inputMethodEngine, InputMethodExtensionContext } from '@kit.IMEKit';
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
    constructor() {
    }
    onCreate(context: InputMethodExtensionContext): void {
        this.ctx = context;
        try {
            let defaultDisplay = display.getDefaultDisplaySync();
            this.initWindow(defaultDisplay)
        } catch (error) {
            // TODO: Implement error handling.
        }
        this.registerListener()
    }
    onDestroy(): void {
        this.unRegisterListener()
        if(this.panel) {
            inputMethodAbility.destroyPanel(this.panel);
        }
        if(this.ctx) {
            this.ctx.destroy();
        }
    }
    handle(event: InputKeyEvent): void {
        try {
            this.inputClient?.insertTextSync(event.text);
        } catch (error) {
            // TODO: Implement error handling.
        }
    }
    process(text: string): void {
        try {
            this.inputClient?.insertTextSync(text);
        } catch (error) {
            // TODO: Implement error handling.
        }
    }
    insert(text: string): void {
        this.inputClient?.insertText(text).catch(() => {
            // TODO: Implement error handling.
        });
    }
    backspace(length: number = 1): void {
        try {
            this.inputClient?.deleteForwardSync(length);
        } catch (error) {
            // TODO: Implement error handling.
        }
    }
    rightDelete(length: number = 1): void {
        try {
            this.inputClient?.deleteBackwardSync(length);
        } catch (error) {
            // TODO: Implement error handling.
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

const inputController = new InputController();
export default inputController;
