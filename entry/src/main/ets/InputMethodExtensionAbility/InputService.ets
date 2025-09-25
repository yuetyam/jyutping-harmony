import { Want } from '@kit.AbilityKit';
import { InputMethodExtensionAbility } from '@kit.IMEKit';
import inputController from './model/InputController'

export default class InputService extends InputMethodExtensionAbility {
    onCreate(want: Want): void {
        inputController.onCreate(this.context);
    }
    onDestroy(): void {
        inputController.onDestroy();
    }
}
