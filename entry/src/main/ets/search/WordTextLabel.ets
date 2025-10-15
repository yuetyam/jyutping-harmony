import { SeparatorMark } from "./SeparatorMark";

@ComponentV2
export struct WordTextLabel {
    @Param @Require word: string;
    build() {
        Row({ space: 16 }) {
            Row({ space: 2 }) {
                Text("文字")
                    .fontSize('15vp')
                    .opacity(0.9)
                SeparatorMark()
                Text(this.word)
            }
            if (this.word.length === 1) {
                Text("U+" + this.word.codePointAt(0)?.toString(16).toUpperCase())
                    .fontSize('13vp')
                    .opacity(0.75)
            }
        }
    }
}
