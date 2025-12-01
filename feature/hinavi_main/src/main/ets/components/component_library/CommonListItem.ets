import { hdsEffect } from "@kit.UIDesignKit"
import { TextModifier } from '@kit.ArkUI'

@ComponentV2
export struct CommonListItem {
  @Param icon: Resource | null = null
  @Param isSymbol: boolean = true
  @Param @Require title: ResourceStr
  @Param subtitle: ResourceStr | null = null
  @Param filled: boolean = true
  @Param trailingOnBottom: boolean = false
  @Param highlightBorder: boolean = false
  @Param isCompose: boolean = false

  @Param fontColor: ResourceColor = $r('sys.color.font')
  @Param titleModifier: TextModifier | undefined = undefined
  @Param hintFontColor: ResourceColor = $r('sys.color.font_on_secondary')
  @BuilderParam trailing?: () => void

  @Builder Build() {
    Column() {
      Row() {
        if (this.icon) {
          if (this.isSymbol) {
            SymbolGlyph(this.icon)
              .fontSize(24)
              .margin({ right: 12 })
              .fontColor([this.fontColor])
          } else {
            Image(this.icon)
              .width(24.29)
              .margin({ right: 12 })
              .draggable(false)
          }
        }
        Column() {
          Text(this.title)
            .attributeModifier(this.titleModifier)
            .fontColor(this.fontColor)
          if (this.subtitle) {
            Text(this.subtitle)
              .fontSize(12)
              .fontColor(this.hintFontColor)
          }
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
        if (this.trailing && !this.trailingOnBottom) {
          this.trailing()
        } else {
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(24)
            .fontColor([this.fontColor])
        }
      }
      .justifyContent(FlexAlign.Start)
      if (this.trailing && this.trailingOnBottom) {
        this.trailing()
      }
    }
    .hoverEffect(HoverEffect.Highlight)
    .padding({ left: 12, right: 12, bottom: this.trailingOnBottom ? 12 : 8, top: 8 })
    .justifyContent(FlexAlign.Center)
    .constraintSize({
      minHeight: 54
    })
  }
  build() {
    if (this.isCompose) {
      this.Build()
    } else {
      Column() {
        this.Build()
      }.backgroundColor($r('sys.color.ohos_fa_list_card_bg'))
      .borderRadius(20)
    }
  }
}

@ComponentV2
export struct CommonItemContainer {
  @Param spc: number = 0
  @BuilderParam child: () => void

  build() {
    Column({space: this.spc}) {
      this.child()
    }.backgroundColor($r('sys.color.ohos_fa_list_card_bg'))
    .borderRadius(20)
  }
}