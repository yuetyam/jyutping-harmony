import { pasteboard } from '@kit.BasicServicesKit';
import controller from '../InputController';

@ComponentV2
export default struct EditingSystemPasteKey {
    build() {
        Stack() {
            PasteButton()
                .onClick((event: ClickEvent, result: PasteButtonOnClickResult, error?: BusinessError<void> | undefined) => {
                    switch (result) {
                        case PasteButtonOnClickResult.SUCCESS:
                            try {
                                const text = pasteboard.getSystemPasteboard().getDataSync().getPrimaryText();
                                controller.insert(text);
                                controller.playInputSound();
                                controller.triggerHapticFeedback();
                            } catch (caughtError) {
                                let err: BusinessError = caughtError as BusinessError;
                                console.error("Failed to paste pasteboard text, message: " + err.message + ", code: " + err.code);
                            }
                            break;
                        case PasteButtonOnClickResult.TEMPORARY_AUTHORIZATION_FAILED:
                            console.error("Failed to paste pasteboard text, result: TEMPORARY_AUTHORIZATION_FAILED");
                            break;
                        default:
                            console.error("Failed to paste pasteboard text, message: " + error?.message + ", code: " + error?.code);
                            break
                    }
                })
                .width('calc(100% - 8vp)')
                .height('calc(100% - 16vp)')
        }
        .width('100%')
        .height('100%')
    }
}
