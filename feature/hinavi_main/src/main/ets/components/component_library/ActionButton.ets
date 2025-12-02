
@ComponentV2
export struct ActionButton {
  @Param @Require icon: Resource
  @Param @Require clickAction: () => void
  @Param customBgColor: ResourceColor | undefined = undefined
  @Param customFontColor: ResourceColor[] | undefined = undefined
  @Param customFontSize: number | undefined = undefined
  @Param longPressAction: ((() => void) | undefined) = undefined
  @Param title: ResourceStr | undefined = undefined
  @Param forceRatio: boolean = false

  build() {
    Column({space: 4}) {
      Button() {
        SymbolGlyph(this.icon)
          .fontSize(this.customFontSize ? this.customFontSize: 24)
          .fontColor(this.customFontColor ? this.customFontColor : [$r('sys.color.font_primary')])
      }.onClick(() => { this.clickAction(); })
      .gesture((this.longPressAction === undefined) ? undefined : (LongPressGesture().onAction(() => {
        this.longPressAction!()
      })))
      .backgroundColor(this.customBgColor ? this.customBgColor : $r('sys.color.comp_background_secondary'))
      .padding(8)
      .clickEffect({
        level: ClickEffectLevel.LIGHT
      })
      .hoverEffect(HoverEffect.Highlight)
      if (this.title) {
        Text(this.title)
          .fontSize(10)
          .fontColor($r('sys.color.ohos_id_color_bottom_tab_text_off'))
      }
    }
  }
}