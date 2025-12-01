import { hdsEffect } from "@kit.UIDesignKit"
import { LightUpLinedContainer } from "./LightUpContainer"

@ComponentV2
export struct CommonListToggleItem {
  @Param icon: Resource | null = null
  @Param isSymbol: boolean = true
  @Param @Require title: ResourceStr
  @Param subtitle: ResourceStr | null = null
  @Param filled: boolean = true
  @Param highlightBorder: boolean = false
  
  @Param fontColor: ResourceColor = $r('sys.color.font_on_primary')
  @Param hintFontColor: ResourceColor = $r('sys.color.font_on_secondary')
  
  @Param @Require isOn: boolean
  @Param toggleType: ToggleType = ToggleType.Switch
  @Param @Require onToggleChange: (isOn: boolean) => void
  @Param isDisabledSwitch: boolean = false

  @Param useLightUpLine: boolean = false

  @Builder Build() {
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
          .fontColor(this.fontColor)
        if (this.subtitle) {
          Text(this.subtitle)
            .fontSize(12)
            .fontColor(this.hintFontColor)
        }
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      
      Toggle({
        isOn: this.isOn,
        type: this.toggleType
      })
        .onChange((val) => {
          this.onToggleChange(val)
        })
        .enabled(!this.isDisabledSwitch)
    }
    .hoverEffect(HoverEffect.Highlight)
    .borderRadius(24)
    .border(this.highlightBorder ? {
      width: 2,
      color: Color.White,
      radius: 24
    } : {
      width: 0,
      radius: 24
    })
    .padding({ left: 12, right: 12 })
    .justifyContent(FlexAlign.Start)
    .height(54)
  }

  build() {
    if (this.useLightUpLine) {
      LightUpLinedContainer() {
        this.Build()
      }
    } else {
      this.Build()
    }
  }
}

@ComponentV2
export struct LightedCommonListToggleItem {
  @Param icon: Resource | null = null
  @Param isSymbol: boolean = true
  @Param @Require title: ResourceStr
  @Param subtitle: ResourceStr | null = null
  @Param filled: boolean = true
  @Param highlightBorder: boolean = false
  
  @Param @Require isOn: boolean
  @Param toggleType: ToggleType = ToggleType.Switch
  @Param @Require onToggleChange: (isOn: boolean) => void
  @Param isDisabledSwitch: boolean = false

  build() {
    Column() {
      LightUpLinedContainer() {
        CommonListToggleItem({
          icon: this.icon,
          title: this.title,
          isSymbol: this.isSymbol,
          subtitle: this.subtitle,
          filled: this.filled,
          highlightBorder: this.highlightBorder,
          isOn: this.isOn,
          toggleType: this.toggleType,
          onToggleChange: this.onToggleChange,
          isDisabledSwitch: this.isDisabledSwitch
        })
      }
    }.backgroundColor($r('app.color.play_list_single_item_bg'))
    .borderRadius(20)
    .visualEffect(new hdsEffect.HdsEffectBuilder().pointLight({
      illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
    }).buildEffect())
    .opacity(this.isDisabledSwitch ? 0.8 : 1)
  }
}
