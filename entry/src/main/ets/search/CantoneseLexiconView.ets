import { Pronunciation } from "./Pronunciation";
import { PronunciationView } from "./PronunciationView";
import { CantoneseLexicon } from "./CantoneseLexicon";
import { WordTextLabel } from "./WordTextLabel";
import { SeparatorMark } from "./SeparatorMark";

@ComponentV2
export struct CantoneseLexiconView {
    @Param @Require @Once lexicon: CantoneseLexicon;
    build() {
        Column({ space: 6 }) {
            WordTextLabel({ word: this.lexicon.text })
            ForEach(this.lexicon.pronunciations, (item: Pronunciation) => {
                Divider()
                PronunciationView({ pronunciation: item })
            }, (item: Pronunciation) => item.romanization)
            if (this.lexicon?.unihanDefinition) {
                Divider()
                Row({ space: 2 }) {
                    Text("英文")
                        .fontSize(15)
                        .opacity(0.9)
                    SeparatorMark()
                    Text(this.lexicon.unihanDefinition)
                }
            }
        }
        .alignItems(HorizontalAlign.Start)
    }
}
