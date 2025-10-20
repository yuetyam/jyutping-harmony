import { Candidate } from "../model/Candidate"
import { CircleShape } from "@kit.ArkUI";
import controller from "../InputController";
import CandidateView from "./CandidateView";

@ComponentV2
export default struct CandidateBar {
    private buttonLength = '44vp';
    private iconLength: Length = '24vp';
    private shape = new CircleShape({ width: this.buttonLength, height: this.buttonLength });
    private scroller: Scroller = new Scroller();
    build() {
        Row() {
            List({ scroller: this.scroller }) {
                ForEach(controller.candidates, (item: Candidate) => {
                    ListItem() {
                        CandidateView({ candidate: item })
                    }
                }, (item: Candidate) => item.text + item.comment)
            }
            .listDirection(Axis.Horizontal)
            .scrollBar(BarState.Off)
            .width('calc(100% - 44vp)')
            .height('100%')
            Stack() {
                Button() {
                    Image($r('app.media.chevron_down'))
                        .fillColor($r('sys.color.ohos_id_color_primary'))
                        .width(this.iconLength)
                        .height(this.iconLength)
                }
                .backgroundColor(Color.Transparent)
                .clipShape(this.shape)
                .width(this.buttonLength)
                .height(this.buttonLength)
            }
            .width(this.buttonLength)
            .height('100%')
            .onClick((event?: ClickEvent) => {
                if (event) {
                    controller.playModifierSound();
                    this.scroller.scrollToIndex(0);
                }
            })
        }
        .width('100%')
        .height('100%')
    }
}
