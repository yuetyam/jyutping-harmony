import { Candidate } from '../model/Candidate';

@ComponentV2
export default struct CandidateAltView {
    @Param @Require @Once candidate: Candidate;
    build() {
        Stack({ alignContent: Alignment.Center }) {
            Stack({ alignContent: Alignment.Top }) {
                Text(this.candidate.comment)
                    .maxLines(1)
                    .fontSize(11)
                    .padding({ top: 3 })
            }
            .height('100%')
            Text(this.candidate.text)
                .maxLines(1)
                .fontSize(18)
        }
        .width('100%')
        .height('100%')
    }
}
