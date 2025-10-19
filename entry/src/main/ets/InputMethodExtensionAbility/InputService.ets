import { Want, bundleManager } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { InputMethodExtensionAbility } from '@kit.IMEKit';
import fs from '@ohos.file.fs';
import controller from './InputController'

export default class InputService extends InputMethodExtensionAbility {
    private async copyKeyboardDatabase() {
        let bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
        let sourcePath: string = this.context.resourceDir + "/imedb.sqlite3";
        let fileName: string = `imedb-${bundleInfo.versionName}-${bundleInfo.versionCode}-tmp.sqlite3`;
        let destinationPath: string = this.context.databaseDir + "/rdb/ime/" + fileName;
        try {
            if (!fs.accessSync(destinationPath)) {
                fs.copyFile(sourcePath, destinationPath).catch(() => {
                    // TODO: Implement error handling.
                });
            }
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error("copyKeyboardDatabase() failed with error message: " + err.message + ", error code: " + err.code);
        }
    }
    onCreate(want: Want): void {
        this.copyKeyboardDatabase();
        controller.onCreate(this.context);
    }
    onDestroy(): void {
        controller.onDestroy();
    }
}
