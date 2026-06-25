export class SidebarSyllable {
    readonly text: string;
    readonly isSelected: boolean;

    constructor(text: string, isSelected: boolean = false) {
        this.text = text;
        this.isSelected = isSelected;
    }
}
