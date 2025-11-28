import { FanWanLexicon, FanWanUnit } from "./FanWanUnit";
import { SeparatorMark } from "./SeparatorMark";
import { WordTextLabel } from "./WordTextLabel";

@ComponentV2
export struct FanWanLexiconView {
    @Param @Require @Once lexicon: FanWanLexicon;
    build() {
        Column({ space: 6 }) {
            WordTextLabel({ word: this.lexicon.word })
            ForEach(this.lexicon.units, (item: FanWanUnit) => {
                Divider()
                FanWanUnitView({ unit: item })
            }, (item: FanWanUnit) => item.romanization)
        }
        .alignItems(HorizontalAlign.Start)
    }
}

@ComponentV2
struct FanWanUnitView {
    @Param @Require @Once unit: FanWanUnit;
    private abstract: string = `${this.unit.initial}母　${this.unit.final}韻　${this.unit.yamyeung}${this.unit.tone}　${this.unit.rhyme}小韻`;
    build() {
        Column({ space: 6 }) {
            Row({ space: 2 }) {
                Text("讀音")
                    .fontSize(15)
                    .opacity(0.9)
                SeparatorMark()
                Text(this.abstract)
            }
            Row({ space: 2 }) {
                Text("轉寫")
                    .fontSize(15)
                    .opacity(0.9)
                SeparatorMark()
                Text(this.unit.romanization)
            }
            if (this.unit.homophones.length > 0) {
                Row({ space: 2 }) {
                    Text("同音")
                        .fontSize(15)
                        .opacity(0.9)
                    SeparatorMark()
                    Text(this.unit.homophones.join(" "))
                }
            }
            Row({ space: 2 }) {
                Text("釋義")
                    .fontSize(15)
                    .opacity(0.9)
                SeparatorMark()
                Text(this.unit.interpretation)
            }
            .alignItems(VerticalAlign.Top)
        }
        .alignItems(HorizontalAlign.Start)
        .width('85%')
        // TODO: Better width value
    }
}
