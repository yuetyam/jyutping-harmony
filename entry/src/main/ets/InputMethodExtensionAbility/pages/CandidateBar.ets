import { Candidate } from '../model/Candidate';
import { CircleShape } from '@kit.ArkUI';
import controller from '../InputController';
import CandidateView from './CandidateView';
import { KeyboardForm } from '../model/KeyboardForm';

@ComponentV2
export default struct CandidateBar {
    private buttonLength = '44vp';
    private shape = new CircleShape({ width: this.buttonLength, height: this.buttonLength });
    private scroller: Scroller = new Scroller();
    build() {
        Row() {
            Stack() {
                Text(controller.inlinePreEditText)
                    .fontSize(11)
                    .padding({ left: 8, bottom: 4 })
                    .opacity(0.8)
                List({ scroller: this.scroller }) {
                    ForEach(controller.candidates, (item: Candidate) => {
                        ListItem() {
                            CandidateView({ candidate: item })
                                .onClick(() => {
                                    controller.playInputSound();
                                    controller.selectCandidate(item);
                                    this.scroller.scrollToIndex(0);
                                })
                        }
                    }, (item: Candidate) => item.text + item.comment)
                }
                .listDirection(Axis.Horizontal)
                .scrollBar(BarState.Off)
                .width('100%')
                .height('100%')
            }
            .alignContent(Alignment.BottomStart)
            .width('calc(100% - 44vp)')
            .height('100%')
            Stack() {
                Button() {
                    Image($r('app.media.chevron_down'))
                        .fillColor($r('sys.color.ohos_id_color_primary'))
                        .width('20vp')
                        .height('20vp')
                }
                .backgroundColor(Color.Transparent)
                .clipShape(this.shape)
                .width(this.buttonLength)
                .height(this.buttonLength)
            }
            .width(this.buttonLength)
            .height('100%')
            .onClick(() => {
                controller.playModifierSound();
                controller.transformTo(KeyboardForm.CandidateBoard);
            })
        }
        .width('100%')
        .height('100%')
    }
}
