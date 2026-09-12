import { KeyboardCase } from "./KeyboardCase";
import { VirtualInputKey } from "./VirtualInputKey";

export class BasicInputEvent {
    readonly key: VirtualInputKey;
    readonly kbCase: KeyboardCase;
    constructor(key: VirtualInputKey, kbCase: KeyboardCase) {
        this.key = key;
        this.kbCase = kbCase;
    }

    static normalizedPreviewMark(events: BasicInputEvent[]): string {
        let result = "";
        let index = 0;
        while (index < events.length) {
            const event = events[index];
            const key = event.key;
            const paired = index + 1 < events.length && key === events[index + 1].key;
            const tone = key === VirtualInputKey.letterV ? 1 : key === VirtualInputKey.letterX ? 2 : key === VirtualInputKey.letterQ ? 3 : 0;
            if (tone > 0) {
                result += (paired ? tone + 3 : tone).toString();
                index += paired ? 2 : 1;
                if (index < events.length) result += " ";
            } else {
                result += event.kbCase === KeyboardCase.lowercased ? key.text : key.text.toUpperCase();
                index++;
                if (!key.isLetter && index < events.length) result += " ";
            }
        }
        return result;
    }
}
