import { display } from '@kit.ArkUI';
import { inputMethodEngine, InputMethodExtensionContext } from '@kit.IMEKit';

const inputMethodAbility: inputMethodEngine.InputMethodAbility = inputMethodEngine.getInputMethodAbility();
export class InputController {
    private mContext: InputMethodExtensionContext | undefined = undefined;
    private panel: inputMethodEngine.Panel | undefined = undefined;
    private attribute: inputMethodEngine.EditorAttribute | undefined = undefined
    private inputClient: inputMethodEngine.InputClient | undefined = undefined;
    // private keyboardController: inputMethodEngine.KeyboardController | undefined = undefined;
    constructor() {
    }
    public onCreate(context: InputMethodExtensionContext): void {
        this.mContext = context;
        this.initWindow();
        this.registerListener()
    }
    public onDestroy(): void {
        this.unRegisterListener()
        if(this.panel) {
            inputMethodAbility.destroyPanel(this.panel);
        }
        if(this.mContext) {
            this.mContext.destroy();
        }
    }
    public insertText(text: string): void {
        if(this.inputClient) {
            this.inputClient.insertText(text).catch(() => {
                // TODO: Implement error handling.
            });
        }
    }
    public deleteForward(length: number): void {
        if(this.inputClient) {
            this.inputClient.deleteForward(length).catch(() => {
                // TODO: Implement error handling.
            });
        }
    }
    public enterKeyAction() {
        let actionCode = this.attribute?.enterKeyType ?? inputMethodEngine.ENTER_KEY_TYPE_DONE;
        this.inputClient?.sendKeyFunction(actionCode).catch(() => {
            // TODO: Implement error handling.
        })
    }

    private initWindow(): void {
        if(this.mContext === undefined) {
            return;
        }
        let defaultDisplay = display.getDefaultDisplaySync();
        let displayWidth = defaultDisplay.width;
        let displayHeight = defaultDisplay.height;
        // let keyboardHeight = Math.min(displayWidth / 3.0 * 2, displayHeight / 3.0)
        let keyboardHeight = (52 * 4 + 56) * defaultDisplay.scaledDensity
        let nonBarPosition = displayHeight - keyboardHeight;
        let panelInfo: inputMethodEngine.PanelInfo = {
            type: inputMethodEngine.PanelType.SOFT_KEYBOARD,
            flag: inputMethodEngine.PanelFlag.FLG_FIXED
        };
        inputMethodAbility.createPanel(this.mContext, panelInfo)
            .then(async (inputPanel: inputMethodEngine.Panel) => {
                this.panel = inputPanel;
                if(this.panel) {
                    await this.panel.resize(displayWidth, keyboardHeight);
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
            // this.keyboardController = kbController;
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
