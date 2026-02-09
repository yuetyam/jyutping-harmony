import { KeyboardCase } from "./KeyboardCase";
import { VirtualInputKey } from "./VirtualInputKey";

export class BasicInputEvent {
    readonly key: VirtualInputKey;
    readonly kbCase: KeyboardCase;
    constructor(key: VirtualInputKey, kbCase: KeyboardCase) {
        this.key = key;
        this.kbCase = kbCase;
    }
}
