import { display } from '@kit.ArkUI';
import { inputMethodEngine, InputMethodExtensionContext } from '@kit.IMEKit';
import { InputMode } from './InputMode';

const inputMethodAbility: inputMethodEngine.InputMethodAbility = inputMethodEngine.getInputMethodAbility();
export class InputController {
    private ctx: InputMethodExtensionContext | undefined = undefined;
    private panel: inputMethodEngine.Panel | undefined = undefined;
    private attribute: inputMethodEngine.EditorAttribute | undefined = undefined
    private inputClient: inputMethodEngine.InputClient | undefined = undefined;
    private keyboardController: inputMethodEngine.KeyboardController | undefined = undefined;
    constructor() {
    }
    public onCreate(context: InputMethodExtensionContext): void {
        this.ctx = context;
        try {
            let defaultDisplay = display.getDefaultDisplaySync();
            this.initWindow(defaultDisplay)
        } catch (error) {
            // TODO: Implement error handling.
        }
        this.registerListener()
        let inputMode: InputMode | undefined = AppStorage.get('currentInputMode');
        if (inputMode === undefined) {
            AppStorage.setOrCreate('currentInputMode', InputMode.Cantonese);
        }
    }
    public onDestroy(): void {
        this.unRegisterListener()
        if(this.panel) {
            inputMethodAbility.destroyPanel(this.panel);
        }
        if(this.ctx) {
            this.ctx.destroy();
        }
    }
    public insert(text: string): void {
        this.inputClient?.insertText(text).catch(() => {
            // TODO: Implement error handling.
        });
    }
    public backspace(length: number = 1): void {
        try {
            this.inputClient?.deleteForwardSync(length);
        } catch (error) {
            // TODO: Implement error handling.
        }
    }
    public rightDelete(length: number = 1): void {
        try {
            this.inputClient?.deleteBackwardSync(length);
        } catch (error) {
            // TODO: Implement error handling.
        }
    }
    public enterKeyAction() {
        let actionCode = this.attribute?.enterKeyType ?? inputMethodEngine.ENTER_KEY_TYPE_DONE;
        this.inputClient?.sendKeyFunction(actionCode).catch(() => {
            // TODO: Implement error handling.
        })
    }
    public dismissKeyboard() {
        this.panel?.hide()
    }

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
        AppStorage.setOrCreate('keyHeight', keyHeight);
        AppStorage.setOrCreate('keyboardHeight', keyboardHeight);
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
