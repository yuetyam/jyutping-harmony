import { SeparatorMark } from "./SeparatorMark";

@ComponentV2
export struct WordTextLabel {
    @Param @Require @Once word: string;
    build() {
        Row({ space: 16 }) {
            Row({ space: 2 }) {
                Text("文字")
                    .fontSize(15)
                    .opacity(0.9)
                SeparatorMark()
                Text(this.word)
            }
            if (this.isSingular(this.word)) {
                Text("U+" + this.word.codePointAt(0)?.toString(16).toUpperCase())
                    .fontSize(13)
                    .opacity(0.75)
            }
            Blank()
        }
        .width('100%')
    }
    private isSingular(text: string): boolean {
        let count: number = 0;
        for (let _ of text) {
            count += 1;
        }
        return count === 1;
    }
}
