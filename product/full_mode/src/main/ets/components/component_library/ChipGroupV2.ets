import { ThemeManager } from "@ohos/base"

export interface ChipGroupItemInfo {
  leadingIcon?: Resource
  title: ResourceStr
  trailingIcon?: Resource
  onClick?: () => void
  fontColor?: ResourceColor
  iconColor?: ResourceColor
  bgColor?: ResourceColor
}

@ComponentV2
@Preview
export struct TestChipGroup {
  @Local items: ChipGroupItemInfo[] = [{
    title: '标题1'
  }, {
    title: '标题2',
    leadingIcon: $r('sys.symbol.star'),
    trailingIcon: $r('sys.symbol.xmark'),
    fontColor: $r('sys.color.font_primary'),
    iconColor: $r('sys.color.font_secondary'),
    bgColor: $r('sys.color.comp_background_secondary')
  }, {
    title: '标题3',
    onClick: () => {
      this.items[0] = {
        title: '标题变换'
      }
    }
  }]
  build() {
    ChipGroupV2({
      items: this.items
    })
  }
}

@ComponentV2
export struct ChipGroupV2 {
  @Param @Require items: ChipGroupItemInfo[]
  @Param bgColor: ResourceColor = ThemeManager.getTheme().colors!.brand!
  @Param fontColor: ResourceColor = $r('sys.color.font_on_primary')
  @Param iconColor: ResourceColor = $r('sys.color.font_on_primary')
  @Param scroller: Scroller | null = null
  @Param useShadow: boolean = false
  @Param customLRPadding: number = 0

  build() {
    Row() {
      List({scroller: this.scroller}) {
        ListItem() .width(this.customLRPadding)
        ForEach(this.items, (item: ChipGroupItemInfo) => {
          ListItem() {
            ChipV2({
              title: item.title,
              leadingIcon: item.leadingIcon,
              trailingIcon: item.trailingIcon,
              clickAction: item.onClick ?? (() => {}),
              bgColor: item.bgColor ?? this.bgColor,
              fontColor: item.fontColor ?? this.fontColor,
              iconColor: item.iconColor ?? this.iconColor,
              useShadow: this.useShadow
            }).margin({right: 8})
              .transition(TransitionEffect.OPACITY.animation({
                duration: 300
              }))
          }
        })
        ListItem() .width(this.customLRPadding)
      }.listDirection(Axis.Horizontal)
      .scrollBar(BarState.Off)
    }
    .height(34)
    .borderRadius(this.useShadow ? 0 : 24)
    .alignItems(VerticalAlign.Center)
  }
}

@ComponentV2
export struct ChipV2 {
  @Param @Require title: ResourceStr
  @Param leadingIcon: Resource | null = null
  @Param trailingIcon: Resource | null = null
  @Param bgColor: ResourceColor = ThemeManager.getTheme().colors!.brand!
  @Param fontColor: ResourceColor = $r('sys.color.font_on_primary')
  @Param iconColor: ResourceColor = $r('sys.color.font_on_primary')
  @Param useShadow: boolean = false
  @Param clickAction: () => void = () => {}

  build() {
    Row() {
      if (this.leadingIcon) {
        SymbolGlyph(this.leadingIcon)
          .fontColor([this.iconColor])
          .fontWeight(FontWeight.Medium)
      }
      Text(this.title)
        .fontColor(this.fontColor)
        .margin({left: 8, right: 8})
      if (this.trailingIcon) {
        SymbolGlyph(this.trailingIcon)
          .fontColor([this.iconColor])
          .fontWeight(FontWeight.Medium)
      }
    }.padding({top: 8, bottom: 8, left: 8, right: 8})
    // .shadow(this.useShadow ? ShadowStyle.OUTER_DEFAULT_MD : null)
    .borderRadius(24)
    .backgroundColor(this.bgColor)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.clickAction()
    })
  }
}