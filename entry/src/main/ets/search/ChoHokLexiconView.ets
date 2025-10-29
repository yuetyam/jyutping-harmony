import { ChoHokLexicon, ChoHokUnit } from "./ChoHokUnit";
import { SeparatorMark } from "./SeparatorMark";
import { WordTextLabel } from "./WordTextLabel";

@ComponentV2
export struct ChoHokLexiconView {
    @Param @Require @Once lexicon: ChoHokLexicon;
    build() {
        Column({ space: 6 }) {
            WordTextLabel({ word: this.lexicon.word })
            ForEach(this.lexicon.units, (item: ChoHokUnit) => {
                Divider()
                ChoHokUnitView({ unit: item })
            }, (item: ChoHokUnit) => item.romanization)
        }
        .alignItems(HorizontalAlign.Start)
    }
}

@ComponentV2
struct ChoHokUnitView {
    @Param @Require @Once unit: ChoHokUnit;
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
                Text(this.unit.tone)
                Text(this.unit.faancit)
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
        }
        .alignItems(HorizontalAlign.Start)
        .width('85%')
        // TODO: Better width value
    }
}
