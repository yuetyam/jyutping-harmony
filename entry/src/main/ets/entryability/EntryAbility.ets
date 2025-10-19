import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import fs from '@ohos.file.fs';
import { BusinessError } from '@kit.BasicServicesKit';
import { bundleManager } from '@kit.AbilityKit';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {

    private async copyAppDatabase() {
        let bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
        let sourcePath: string = this.context.resourceDir + "/appdb.sqlite3";
        let fileName: string = `appdb-${bundleInfo.versionName}-${bundleInfo.versionCode}-tmp.sqlite3`;
        let destinationPath: string = this.context.databaseDir + "/rdb/app/" + fileName;
        try {
            if (!fs.accessSync(destinationPath)) {
                fs.copyFile(sourcePath, destinationPath).catch(() => {
                    // TODO: Implement error handling.
                });
            }
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error("copyAppDatabase() failed with error message: " + err.message + ", error code: " + err.code);
        }
    }

    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        try {
            this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
        } catch (error) {
            // TODO: Implement error handling.
        }
        hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
        this.copyAppDatabase();
    }

    onDestroy(): void {
        hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
    }

    onWindowStageCreate(windowStage: window.WindowStage): void {
        // Main window is created, set main page for this ability
        hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

        windowStage.loadContent('pages/Index', (err) => {
            if (err.code) {
                hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
                return;
            }
            hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');

            let windowClass: window.Window = windowStage.getMainWindowSync();
            windowClass.setWindowLayoutFullScreen(true);

            let type = window.AvoidAreaType.TYPE_SYSTEM;
            let avoidArea = windowClass.getWindowAvoidArea(type);
            let topRectHeight = avoidArea.topRect.height;
            AppStorage.setOrCreate('topRectHeight', topRectHeight);

            type = window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR;
            avoidArea = windowClass.getWindowAvoidArea(type);
            let bottomRectHeight = avoidArea.bottomRect.height;
            AppStorage.setOrCreate('bottomRectHeight', bottomRectHeight);

            windowClass.on('avoidAreaChange', (data) => {
                if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
                    let topRectHeight = data.area.topRect.height;
                    AppStorage.setOrCreate('topRectHeight', topRectHeight);
                } else if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
                    let bottomRectHeight = data.area.bottomRect.height;
                    AppStorage.setOrCreate('bottomRectHeight', bottomRectHeight);
                }
            });
        });
    }

    onWindowStageDestroy(): void {
        // Main window is destroyed, release UI related resources
        hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
    }

    onForeground(): void {
        // Ability has brought to foreground
        hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
    }

    onBackground(): void {
        // Ability has back to background
        hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
    }
}
