import { BusinessError } from '@kit.BasicServicesKit';
import { InputKeyEvent } from "./InputKeyEvent";
import { relationalStore } from "@kit.ArkData";

export class Syllable {
    readonly aliasCode: number;
    readonly originCode: number;
    readonly alias: InputKeyEvent[];
    readonly origin: InputKeyEvent[];
    constructor(aliasCode: number, originCode: number) {
        this.aliasCode = aliasCode;
        this.originCode = originCode;
        this.alias = this.matchedEvents(aliasCode);
        this.origin = this.matchedEvents(originCode);
    }
    private matchedEvents(value: number): InputKeyEvent[] {
        let num = value;
        const codes: number[] = [];
        while (num > 0) {
            codes.push(num % 100);
            num = Math.floor(num / 100);
        }
        return codes.reverse().map((code) => InputKeyEvent.matchEvent(code)).filter(Boolean) as InputKeyEvent[];
    }
}

export type Scheme = Syllable[];
export type Segmentation = Scheme[];

export class Segmenter {
    private static match(code: number, store: relationalStore.RdbStore): number | undefined {
        const command: string = `SELECT origincode FROM syllabletable WHERE aliascode = ${code} LIMIT 1;`;
        let res: relationalStore.ResultSet | undefined = undefined;
        let originCode: number | undefined = undefined;
        try {
            res = store.querySqlSync(command);
            if (res.goToNextRow()) {
                originCode = res.getLong(0);
            }
        } catch (error) {
            let err: BusinessError = error as BusinessError;
            console.error(`message: ${err.message}, code: ${err.code}`);
        } finally {
            res?.close();
        }
        return originCode;
    }
    private static splitLeading(events: InputKeyEvent[], store: relationalStore.RdbStore): Syllable[] {
        const maxLength = Math.min(events.length, 6);
        if (maxLength == 0) {
            return [];
        }
        const syllables: Syllable[] = [];
        for (let num = maxLength - 1; num >= 0; num--) {
            const code = events.slice(0, num).reduce((acc, event) => acc * 100 + event.code, 0);
            const originCode: number = Segmenter.match(code, store) ?? 0;
            if (originCode > 0) {
                const syllable = new Syllable(code, originCode);
                syllables.push(syllable);
            }
        }
        return syllables;
    }
    private static split(events: InputKeyEvent[], store: relationalStore.RdbStore): Segmentation {
        const leadingTokens = Segmenter.splitLeading(events, store);
        if (leadingTokens.length === 0) {
            return [];
        }
        const eventCount = events.length;
        const segmentation: Segmentation = leadingTokens.map((token) => [token]);
        let previousSubelementCount = segmentation.reduce((acc, scheme) => acc + scheme.length, 0);
        let shouldContinue: boolean = true;
        while (shouldContinue) {
            for (const scheme of segmentation) {
                const schemeEventCount = scheme.reduce((acc, syllable) => acc + syllable.alias.length, 0)
                if (schemeEventCount >= eventCount) {
                    continue
                }
                const tailEvents = events.slice(schemeEventCount, undefined);
                const tailTokens = Segmenter.splitLeading(tailEvents, store);
                if (tailTokens.length > 0) {
                    const newSegmentation: Segmentation = tailTokens.map((token) => [token]);
                    for (const element of newSegmentation) {
                        segmentation.push(element);
                    }
                }
            }
            const currentSubelementCount = segmentation.reduce((acc, scheme) => acc + scheme.length, 0);
            if (currentSubelementCount !== previousSubelementCount) {
                previousSubelementCount = currentSubelementCount;
            } else {
                shouldContinue = false;
            }
        }
        return segmentation;
    }
    static segment(events: InputKeyEvent[], store: relationalStore.RdbStore): Segmentation {
        return Segmenter.split(events, store);
    }
}
