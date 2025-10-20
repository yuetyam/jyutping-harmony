import { Pronunciation } from "./Pronunciation";
import { SeparatorMark } from "./SeparatorMark";

@ComponentV2
export struct PronunciationView {
    @Param @Require @Once pronunciation: Pronunciation;
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
            }
            if (this.pronunciation.collocations.length > 0) {
                Row({ space: 2 }) {
                    Text("詞例")
                        .fontSize('15vp')
                        .opacity(0.9)
                    SeparatorMark()
                    Text(this.pronunciation.collocations.slice(0, 5).join(" "))
                }
                .alignItems(VerticalAlign.Top)
            }
            ForEach(this.pronunciation.descriptions, (item: string) => {
                Row({ space: 2 }) {
                    Text("釋義")
                        .fontSize('15vp')
                        .opacity(0.9)
                    SeparatorMark()
                    Text(item)
                }
                .alignItems(VerticalAlign.Top)
            }, (item: string) => item)
        }
        .alignItems(HorizontalAlign.Start)
        .width('85%')
        // TODO: Better width value
    }
}
