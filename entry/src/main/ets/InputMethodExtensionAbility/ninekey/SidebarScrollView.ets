import controller from '../InputController';
import { SidebarSyllable } from './SidebarSyllable';
import { util } from '@kit.ArkTS';

@ComponentV2
export default struct SidebarScrollView {
    private scroller: Scroller = new Scroller();
    build() {
        List({ scroller: this.scroller }) {
            ForEach(controller.sidebarSyllables, (item: SidebarSyllable, index: number) => {
                ListItem() {
                    Button() {
                        Text(item.text)
                            .textAlign(TextAlign.Center)
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                            .fontSize(15)
                    }
                    .borderRadius(0)
                    .backgroundColor(item.isSelected ? $r('app.color.key_emphatic') : Color.Transparent)
                    .width('100%')
                    .height(item.isSelected ? '15%' : '25%')
                    .onClick(() => {
                        controller.playInputSound();
                        controller.triggerHapticFeedback();
                        controller.handleSidebarTapping(index);
                        this.scroller.scrollToIndex(0);
                    })
                }
                ListItem() { Divider() }
            }, (item: SidebarSyllable) => (item.text + util.generateRandomUUID()))
        }
        .listDirection(Axis.Vertical)
        .scrollBar(BarState.Off)
        .width('100%')
        .height('100%')
    }
}
