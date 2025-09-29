import { Want } from '@kit.AbilityKit';
import { InputMethodExtensionAbility } from '@kit.IMEKit';
import controller from './model/InputController'

export default class InputService extends InputMethodExtensionAbility {
    onCreate(want: Want): void {
        controller.onCreate(this.context);
    }
    onDestroy(): void {
        controller.onDestroy();
    }
}
