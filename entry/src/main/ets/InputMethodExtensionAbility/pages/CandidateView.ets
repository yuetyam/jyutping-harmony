import { Candidate } from "../model/Candidate"

@ComponentV2
export default struct CandidateView {
    @Param @Require @Once candidate: Candidate;
    build() {
        Stack({ alignContent: Alignment.Center }) {
            Stack({ alignContent: Alignment.Top }) {
                Text(this.candidate.comment)
                    .maxLines(1)
                    .fontSize('12vp')
                    .padding({ top: 4 })
            }
            .height('100%')
            Text(this.candidate.text)
                .maxLines(1)
        }
        .padding({ left: 5, right: 5 })
        .height('100%')
    }
}
