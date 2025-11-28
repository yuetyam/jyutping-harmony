import { GwongWanLexicon, GwongWanUnit } from "./GwongWanUnit";
import { SeparatorMark } from "./SeparatorMark";
import { WordTextLabel } from "./WordTextLabel";

@ComponentV2
export struct GwongWanLexiconView {
    @Param @Require @Once lexicon: GwongWanLexicon;
    build() {
        Column({ space: 6 }) {
            WordTextLabel({ word: this.lexicon.word })
            ForEach(this.lexicon.units, (item: GwongWanUnit) => {
                Divider()
                GwongWanUnitView({ unit: item })
            }, (item: GwongWanUnit) => item.interpretation)
        }
        .alignItems(HorizontalAlign.Start)
    }
}

@ComponentV2
struct GwongWanUnitView {
    @Param @Require @Once unit: GwongWanUnit;
    private faancit: string = (this.unit.upper + this.unit.lower + "切");
    private hierarchy(): string {
        const leading: string = `${this.unit.initial}母　${this.unit.rhyme}韻　${this.unit.tone}聲`;
        const parts: string[] = [leading];
        const division: string = this.unit.division;
        const rounding: string = this.unit.repeating;
        if (division !== "X") parts.push(`${division}等`);
        if (rounding !== "X") parts.push(`${rounding}口`);
        return parts.join("　");
    }
    build() {
        Column({ space: 6 }) {
            Row({ space: 16 }) {
                Row({ space: 2 }) {
                    Text("讀音")
                        .fontSize(15)
                        .opacity(0.9)
                    SeparatorMark()
                    Text(this.faancit)
                }
                Text(this.hierarchy())
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
