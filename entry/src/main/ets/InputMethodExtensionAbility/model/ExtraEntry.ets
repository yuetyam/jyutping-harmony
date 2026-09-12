import { CharCode } from "./CharCode";
import { EngineCode } from "./EngineCode";
import { Lexicon } from "./Lexicon";
import { LexiconType } from "./LexiconType";
import { VirtualInputKey } from "./VirtualInputKey";
import { Combo } from "../ninekey/Combo";

class ExtraWord {
    readonly word: string;
    readonly romanization: string;
    readonly complex: number;
    readonly spell: string;
    readonly nineKey: string;
    constructor(word: string, romanization: string, complex: number, spell: string, nineKey: string) {
        this.word = word;
        this.romanization = romanization;
        this.complex = complex;
        this.spell = spell;
        this.nineKey = nineKey;
    }
}

export class ExtraEntry {
    static search(keys: VirtualInputKey[]): Lexicon[] {
        const code = EngineCode.keys(keys);
        return ExtraEntry.entries.filter((entry) => entry.spell === code && entry.complex === keys.length).map((entry) => ExtraEntry.lexicon(entry, CharCode.keysText(keys)));
    }

    static nineKeySearch(combos: Combo[]): Lexicon[] {
        const code = EngineCode.combos(combos);
        return ExtraEntry.entries.filter((entry) => entry.nineKey === code && entry.complex === combos.length).map((entry) => ExtraEntry.lexicon(entry, entry.romanization.replace(/[^a-z]/g, "")));
    }

    private static lexicon(entry: ExtraWord, input: string): Lexicon {
        return { type: LexiconType.Cantonese, text: entry.word, romanization: entry.romanization, input: input, inputCount: input.length, mark: entry.romanization.replace(/[1-6]/g, ""), number: 0 };
    }

    private static readonly entries: ExtraWord[] = [
        new ExtraWord("啤", "bi1", 2, "2128", "24"),
        new ExtraWord("啤女", "bi4 neoi2", 6, "212833243428", "246364"),
        new ExtraWord("啤仔", "bi1 zai2", 5, "2128452028", "24924"),
        new ExtraWord("啤啤", "bi4 bi1", 4, "21282128", "2424"),
        new ExtraWord("啤啤車", "bi4 bi1 ce1", 6, "212821282224", "242423"),
        new ExtraWord("啤啤牀", "bi4 bi1 cong4", 8, "2128212822343326", "24242664"),
        new ExtraWord("啤啤女", "bi4 bi1 neoi2", 8, "2128212833243428", "24246364"),
        new ExtraWord("啤啤衫", "bi4 bi1 saam1", 8, "2128212838202032", "24247226"),
        new ExtraWord("啤啤仔", "bi4 bi1 zai2", 7, "21282128452028", "2424924"),
        new ExtraWord("生啤啤", "saang1 bi4 bi1", 9, "382020332621282128", "722642424"),
        new ExtraWord("欸", "e6", 1, "24", "3"),
        new ExtraWord("誒", "e6", 1, "24", "3"),
        new ExtraWord("欸", "ei6", 2, "2428", "34"),
        new ExtraWord("誒", "ei6", 2, "2428", "34"),
        new ExtraWord("䊦", "et3", 2, "2439", "38"),
        new ExtraWord("𬖋", "et3", 2, "2439", "38"),
        new ExtraWord("覅", "fiu3", 3, "252840", "348"),
        new ExtraWord("𡠍", "fiu3", 3, "252840", "348"),
        new ExtraWord("𧟰", "fiu3", 3, "252840", "348"),
        new ExtraWord("𳄮", "he3", 2, "2724", "43"),
        new ExtraWord("𠺪", "he3", 2, "2724", "43"),
        new ExtraWord("嗗", "gut6", 3, "264039", "488"),
        new ExtraWord("摑", "gwaak3", 5, "2642202030", "49225"),
        new ExtraWord("嚕", "lu1", 2, "3140", "58"),
        new ExtraWord("𠁣", "ngi1", 3, "332628", "644"),
        new ExtraWord("𠃛", "nget1", 4, "33262439", "6438"),
        new ExtraWord("𠸊", "tap1", 3, "392035", "827"),
        new ExtraWord("扤", "at1", 2, "2039", "28"),
        new ExtraWord("扤實", "at1 sat6", 5, "2039382039", "28728"),
        new ExtraWord("扤死貓", "at1 sei2 maau1", 9, "203938242832202040", "287346228"),
        new ExtraWord("嗒", "dep1", 3, "232435", "337"),
        new ExtraWord("嗒嘢", "dep1 je5", 5, "2324352924", "33753"),
        new ExtraWord("嗒糖", "dep1 tong4", 7, "23243539343326", "3378664"),
        new ExtraWord("嗒落有味", "dep1 lok6 jau5 mei6", 12, "6338101551689960828", "337565528634"),
        new ExtraWord("嘰咭", "gi1 gat6", 5, "2628262039", "44428"),
        new ExtraWord("嘰嘰咭咭", "gi1 gi1 gat6 gat6", 10, "7835884188329710423", "4444428428"),
        new ExtraWord("嘰哩咕嚕", "gi1 li1 gu1 lu1", 8, "2628312826403140", "44544858"),
        new ExtraWord("喲", "jo1", 2, "2934", "56"),
        new ExtraWord("哎喲", "aai1 jo1", 5, "2020282934", "22456"),
        new ExtraWord("哎喲", "ai1 jo1", 4, "20282934", "2456"),
        new ExtraWord("𠸉", "kak1", 3, "302030", "525"),
        new ExtraWord("嘞𠸉", "lak1 kak1", 6, "312030302030", "525525"),
        new ExtraWord("嘞嘞𠸉𠸉", "lak1 lak1 kak1 kak1", 12, "3636023504964717390", "525525525525"),
        new ExtraWord("哩", "li1", 2, "3128", "54"),
        new ExtraWord("哩個", "li1 go3", 4, "31282634", "5446"),
        new ExtraWord("花哩綠", "faa1 li1 luk1", 8, "2520203128314030", "32254585"),
        new ExtraWord("𡃈", "kwak1", 4, "30422030", "5925"),
        new ExtraWord("𡃈", "kwaak1", 5, "3042202030", "59225"),
        new ExtraWord("𡁸", "kwaak1", 5, "3042202030", "59225"),
        new ExtraWord("𠽤嚦𡃈嘞", "kik1 lik1 kwak1 lak1", 13, "7661401431458112094", "5455455925525"),
        new ExtraWord("𠽤嚦𡃈嘞", "kik1 lik1 kwaak1 laak1", 15, "4686176365263980782", "545545592255225"),
        new ExtraWord("𠵇", "keu4", 3, "302440", "538"),
        new ExtraWord("𠺫", "leu1", 3, "312440", "538"),
        new ExtraWord("𠵇𠺫", "keu4 leu1", 6, "302440312440", "538538"),
        new ExtraWord("𠮩𠹌", "liu1 lang1", 7, "31284031203326", "5485264"),
        new ExtraWord("啤", "pe1", 2, "3524", "73"),
        new ExtraWord("啤牌", "pe1 paai2", 6, "352435202028", "737224"),
        new ExtraWord("𢚖", "ti4", 2, "3928", "84"),
        new ExtraWord("發𢚖騰", "faat3 ti4 tang4", 10, "6755295319129651710", "3228848264"),
        new ExtraWord("啫", "zoe1", 3, "453424", "963"),
        new ExtraWord("啫啫", "zoe1 zoe1", 6, "453424453424", "963963"),
        new ExtraWord("啫啫煲", "zoe1 zoe1 bou1", 9, "453424453424213440", "963963268"),
    ];
}
