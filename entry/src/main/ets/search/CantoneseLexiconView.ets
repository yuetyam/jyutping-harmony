import { Pronunciation } from "./Pronunciation";
import { PronunciationView } from "./PronunciationView";
import { CantoneseLexicon } from "./CantoneseLexicon";
import { WordTextLabel } from "./WordTextLabel";
import { SeparatorMark } from "./SeparatorMark";

@ComponentV2
export struct CantoneseLexiconView {
    @Param @Require lexicon: CantoneseLexicon;
    build() {
        Column({ space: 6 }) {
            WordTextLabel({ word: this.lexicon.text })
            Repeat(this.lexicon.pronunciations)
                .each((obj: RepeatItem<Pronunciation>) => {
                    Divider()
                    PronunciationView({ pronunciation: obj.item })
                })
            if (this.lexicon?.unihanDefinition) {
                Divider()
                Row({ space: 2 }) {
                    Text("英文")
                        .fontSize('15vp')
                        .opacity(0.9)
                    SeparatorMark()
                    Text(this.lexicon.unihanDefinition)
                }
            }
        }
        .alignItems(HorizontalAlign.Start)
    }
}
