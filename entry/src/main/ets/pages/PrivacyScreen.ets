import { common, Want } from "@kit.AbilityKit";
import { preferences } from "@kit.ArkData";
import { BusinessError } from '@kit.BasicServicesKit';

@Component
export struct PrivacyScreen {
    @Link privacy: string
    private groupBackgroundColor = $r('app.color.group_background');
    private groupBorderRadius: Length = 12;
    build() {
        List() {
            ListItem() {
                Text("粤拼输入法隐私布告")
                    .fontSize(20)
                    .fontWeight(FontWeight.Bold)
            }
            .padding(8)
            ListItemGroup() {
                ListItem() {
                    Text(this.contentText.trimStart())
                        .fontSize(14)
                }
                ListItem() {
                    Row() {
                        Text("详情可参阅：").fontSize(11)
                        Button() {
                            Text("粤拼输入法隐私政策").fontSize(11).foregroundColor($r('app.color.accent'))
                        }
                        .backgroundColor(Color.Transparent)
                        .onClick((event: ClickEvent) => {
                            let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
                            let want: Want = {
                                action: 'ohos.want.action.viewData',
                                entities: ['entity.system.browsable'],
                                abilityName: 'MainAbility',
                                uri: "https://jyutping.app/harmony/privacy"
                            }
                            context.startAbility(want).catch(() => {
                                console.warn("Failed to open the Privacy Policy web page.")
                            });
                        })
                    }
                }
            }
            .padding(10)
            .backgroundColor(this.groupBackgroundColor)
            .borderRadius(this.groupBorderRadius)
            ListItem() {
                Button() {
                    Text("我已阅读并同意")
                        .fontColor(Color.White)
                        .padding(8)
                }
                .backgroundColor($r('app.color.accent'))
                .width('100%')
                .onClick((event: ClickEvent) => {
                    const options: preferences.Options = {
                        name: "shared"
                    };
                    try {
                        let sharedPreferences = preferences.getPreferencesSync(this.getUIContext().getHostContext(), options);
                        sharedPreferences.putSync("privacy", "2025");
                        sharedPreferences.flush().then(() => {
                            this.privacy = "2025";
                        }).catch(() => {
                            console.log("Failed to perform sharedPreferences.flush()")
                        });
                    } catch (error) {
                        let err: BusinessError = error as BusinessError;
                        console.error("Failed to save agreements value, message: " + err.message + ", code: " + err.code);
                    }
                })
            }
            .padding({ left: 8, right: 8, top: 16 })
        }
        .padding({ left: 16, right: 16, top: 72, bottom: 72 })
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.window_background'))
    }

    private contentText: string = `
我们不会收集或分享用户个人信息。
这句话概括了我们的隐私政策。
下面是更多细节描述。

主应用程式：
应用程式不会记录或收集任何个人信息。
应用程式自身的各项功能无需访问网络。
应用程式里面的各个网络链接会通过跳转到系统默认的浏览器来打开。
应用程式无需各种权限即可正常使用。
应用程式不会记录或关联设备的任何信息、ID、标识等。
应用程式不与任何第三方应用或服务相关联。

键盘：
键盘不会记录或收集任何个人信息。
键盘的各项功能无需访问网络。
键盘无需各种权限即可正常使用。
无论开启「完整体验模式」与否，键盘与主应用程式之间都不会传递信息、资料。
键盘不会记录或关联设备的任何信息、ID、标识等。
键盘不与任何第三方应用或服务相关联。
`;

}
