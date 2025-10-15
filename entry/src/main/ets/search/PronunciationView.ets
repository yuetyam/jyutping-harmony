import { Pronunciation } from "./Pronunciation";
import { SeparatorMark } from "./SeparatorMark";

@ComponentV2
export struct PronunciationView {
    @Param @Require pronunciation: Pronunciation;
    build() {
        Column({ space: 6 }) {
            Row({ space: 2 }) {
                Text("讀音")
                    .fontSize('15vp')
                    .opacity(0.9)
                SeparatorMark()
                Text(this.pronunciation.romanization)
            }
            if (this.pronunciation.homophones.length > 0) {
                Row({ space: 2 }) {
                    Text("同音")
                        .fontSize('15vp')
                        .opacity(0.9)
                    SeparatorMark()
                    Text(this.pronunciation.homophones.join(" "))
                }
                .alignItems(VerticalAlign.Top)
            }
            if (this.pronunciation.collocations.length > 0) {
                Row({ space: 2 }) {
                    Text("詞例")
                        .fontSize('15vp')
                        .opacity(0.9)
                    SeparatorMark()
                    Text(this.pronunciation.collocations.join(" "))
                }
                .alignItems(VerticalAlign.Top)
            }
            Repeat(this.pronunciation.descriptions)
                .each((obj: RepeatItem<string>) => {
                    Row({ space: 2 }) {
                        Text("釋義")
                            .fontSize('15vp')
                            .opacity(0.9)
                        SeparatorMark()
                        Text(obj.item)
                    }
                    .alignItems(VerticalAlign.Top)
                })
        }
        .alignItems(HorizontalAlign.Start)
    }
}
