import { Candidate } from "../model/Candidate"
import { CircleShape } from "@kit.ArkUI";
import controller from "../InputController";
import CandidateView from "./CandidateView";
import { KeyboardForm } from "../model/KeyboardForm";

@ComponentV2
export default struct CandidateBoard {
    private buttonLength = '44vp';
    private shape = new CircleShape({ width: this.buttonLength, height: this.buttonLength });
    private scroller: Scroller = new Scroller();
    build() {
        Stack() {
            Row() {
                Grid(this.scroller) {
                    ForEach(controller.candidates, (item: Candidate) => {
                        GridItem() {
                            CandidateView({ candidate: item })
                        }
                        .height('56vp')
                        .onClick((event: ClickEvent) => {
                            controller.playInputSound();
                            controller.selectCandidate(item);
                            this.scroller.scrollToIndex(0);
                        })
                    }, (item: Candidate) => item.text + item.comment)
                }
                .columnsTemplate(`repeat(auto-fit, 64)`)
                .scrollBar(BarState.Off)
                .width('calc(100% - 44vp)')
                .height('100%')
            }
            .width('100%')
            .height('100%')
            Stack() {
                Button() {
                    Image($r('app.media.chevron_up'))
                        .fillColor($r('sys.color.ohos_id_color_primary'))
                        .width('20vp')
                        .height('20vp')
                }
                .backgroundColor($r('app.color.key_shallow'))
                .clipShape(this.shape)
                .width(this.buttonLength)
                .height(this.buttonLength)
            }
            .width(this.buttonLength)
            .height(this.buttonLength)
            .onClick((event: ClickEvent) => {
                controller.playModifierSound();
                controller.transformTo(KeyboardForm.Alphabetic);
            })
        }
        .width('100%')
        .height('100%')
        .alignContent(Alignment.TopEnd)
    }
}
