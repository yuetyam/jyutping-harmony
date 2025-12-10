import controller from '../InputController';
import { bottomTypes, emos } from "../model/EmojiData";

@ComponentV2
export struct EmojiKeyboard {
  @Local emoList: string[] = [];
  @Local emoTypeIndex: number = 1;

  getEmos(index: number) {
    this.emoList = [];
    let i: number = 0, start: number = 0, next: number = 0;
    while (i < emos[index].length) {
      start = Number.parseInt(emos[index][i], 16);
      next = i == emos[index].length - 1 ? start : Number.parseInt(emos[index][i+1], 16);
      while (start <= next) {
        this.emoList.push(String.fromCodePoint(start));
        start++;
      }
      i += 2;
    }
  }

  aboutToAppear() {
    this.getEmos(1);
  }

  build() {
    Column() {
      Row() {
        GridRow({ columns: 8, gutter: 5, direction: GridRowDirection.Row }) {
          ForEach(bottomTypes, (item: string, index: number) => {
            GridCol() {
              if (index == bottomTypes.length - 1) {
                Column() {
                  SymbolGlyph($r('sys.symbol.delete_left'))
                    .fontSize('22vp')
                    .fontColor([$r('sys.color.ohos_id_color_primary')])
                }
                .width('100%')
                .height('100%')
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .borderWidth({ left: 1, right: 1 })
                .backgroundColor($r('app.color.key_shallow'))
              } else {
                Text(index == 0 ? item : String.fromCodePoint(Number.parseInt(emos[index][0], 16)))
                  .width('100%')
                  .height('100%')
                  .textAlign(TextAlign.Center)
                  .borderWidth({ left: index == bottomTypes.length - 1 ? 1 : 0, right: index == 0 ? 1 : 0 })
                  .backgroundColor(this.emoTypeIndex == index ? $r('app.color.key_emphatic') :
                    $r('app.color.key_shallow'))
              }
            }.onClick(() => {
              if (index == 0) {
                controller.transformTo(controller.previousKeyboardForm);
              } else if (index == bottomTypes.length - 1) {
                controller.backspace();
              } else {
                this.emoTypeIndex = index;
                this.getEmos(index);
              }
            });
          })
        }.width('100%')
      }.width('100%')
      .height("20%")
      .padding({ bottom: '10vp' })

      Scroll() {
        GridRow({ columns: 10, gutter: 5, direction: GridRowDirection.Row }) {
          ForEach(this.emoList, (item: string) => {
            GridCol() {
              Text(item)
                .width('100%')
                .height("20%")
                .borderRadius(6)
                .textAlign(TextAlign.Center)
                .onClick(() => {
                  controller.process(item);
                })
            }
          })
        }.width('100%')
      }.width('100%')
      .scrollBarColor(Color.Transparent)
    }
  }
}