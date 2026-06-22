import { describe, it, expect } from "@ohos/hypium";
import { CharCode } from "../main/ets/InputMethodExtensionAbility/model/CharCode";
import { VirtualInputKey } from "../main/ets/InputMethodExtensionAbility/model/VirtualInputKey";

export default function localUnitTest() {
    describe("CharCode", () => {
        it("maps lowercase letters to radix100 codes", 0, () => {
            expect(CharCode.interCode("a")).assertEqual(20);
            expect(CharCode.interCode("z")).assertEqual(45);
            expect(CharCode.charCode("abc")).assertEqual(202122);
            expect(CharCode.charCode("A")).assertUndefined();
        });

        it("maps lowercase letters to nine-key decimal codes", 0, () => {
            expect(CharCode.nineKeyInterCode("a")).assertEqual(2);
            expect(CharCode.nineKeyInterCode("s")).assertEqual(7);
            expect(CharCode.nineKeyInterCode("v")).assertEqual(8);
            expect(CharCode.nineKeyInterCode("z")).assertEqual(9);
            expect(CharCode.nineKeyCharCode("adgjmptw")).assertEqual(23456789);
        });

        it("maps virtual key input characters", 0, () => {
            expect(CharCode.virtualKeyInputCode("0")).assertEqual(10);
            expect(CharCode.virtualKeyInputCode("9")).assertEqual(19);
            expect(CharCode.virtualKeyInputCode("j")).assertEqual(29);
            expect(CharCode.virtualKeyInputCode("/")).assertUndefined();
        });

        it("combines and decodes virtual input keys", 0, () => {
            const keys: VirtualInputKey[] = [VirtualInputKey.letterJ, VirtualInputKey.letterY];
            expect(CharCode.keysText(keys)).assertEqual("jy");
            expect(CharCode.keysCode(keys)).assertEqual(2944);
            expect(CharCode.anchorsCode(keys)).assertEqual(2929);
            expect(CharCode.comboCode([{ digit: 2 }, { digit: 3 }, { digit: 4 }])).assertEqual(234);
            expect(CharCode.matchedInputKeys(202122).map((key) => key.text).join("")).assertEqual("abc");
        });

        it("rejects values beyond safe numeric query length", 0, () => {
            expect(CharCode.charCode("abcdefghi")).assertUndefined();
            expect(CharCode.radix100Combined([20, 21, 22, 23, 24, 25, 26, 27, 28])).assertEqual(0);
            expect(CharCode.nineKeyCharCode("abcdefghijklmnop")).assertUndefined();
            expect(CharCode.decimalCombined([2, 3, 4, 5, 6, 7, 8, 9, 2, 3, 4, 5, 6, 7, 8, 9])).assertEqual(0);
        });
    });
}
