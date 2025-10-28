import { SeparatorMark } from "./SeparatorMark";
import { WordTextLabel } from "./WordTextLabel";
import { YingWaaLexicon, YingWaaUnit } from "./YingWaaUnit"

@ComponentV2
export struct YingWaaLexiconView {
    @Param @Require @Once lexicon: YingWaaLexicon;
    build() {
        Column({ space: 6 }) {
            WordTextLabel({ word: this.lexicon.word })
            ForEach(this.lexicon.units, (item: YingWaaUnit) => {
                Divider()
                YingWaaUnitView({ unit: item })
            }, (item: YingWaaUnit) => item.romanization)
        }
        .alignItems(HorizontalAlign.Start)
    }
}

@ComponentV2
struct YingWaaUnitView {
    @Param @Require @Once unit: YingWaaUnit;
    build() {
        Column({ space: 6 }) {
            Row({ space: 16 }) {
                Row({ space: 2 }) {
                    Text("讀音")
                        .fontSize('15vp')
                        .opacity(0.9)
                    SeparatorMark()
                    Text(this.unit.pronunciation)
                }
                if (this.unit.pronunciationMark) {
                    Text(this.unit.pronunciationMark)
                        .fontStyle(FontStyle.Italic)
                }
            }
            Row({ space: 2 }) {
                Text("轉寫")
                    .fontSize('15vp')
                    .opacity(0.9)
                SeparatorMark()
                Text(this.unit.romanization)
            }
            if (this.unit.homophones.length > 0) {
                Row({ space: 2 }) {
                    Text("同音")
                        .fontSize('15vp')
                        .opacity(0.9)
                    SeparatorMark()
                    Text(this.unit.homophones.join(" "))
                }
            }
            if (this.unit.interpretation) {
                Row({ space: 2 }) {
                    Text("釋義")
                        .fontSize('15vp')
                        .opacity(0.9)
                    SeparatorMark()
                    Text(this.unit.interpretation)
                }
                .alignItems(VerticalAlign.Top)
            }
        }
        .alignItems(HorizontalAlign.Start)
        .width('85%')
        // TODO: Better width value
    }
}
