import { ResponsiveUtil } from "../../common/utils/BreakpointSystem"
import { LengthMetrics } from "@kit.ArkUI"


@ComponentV2
export struct ImageTitleWelcomeTemplate {
  @Param image: Resource = $r('sys.symbol.questionmark_circle')
  @BuilderParam customImage?: () => void
  @Param @Require title: ResourceStr
  @Param subtitle: ResourceStr | undefined = undefined
  @BuilderParam footer: () => void
  @Param useButtonFooter: boolean = false
  @Param buttonFooterOnClick: () => void = () => {}
  @Param buttonFooterText: ResourceStr = ''
  @Param useDefaultTextColor: boolean = false

  build() {
    Scroll() {
      Column() {
        Column() {
          Column() {
            if (this.customImage) {
              this.customImage()
            } else {
              Image(this.image)
                .width(100)
                .height(100)
                .borderRadius(24)
                .shadow(ShadowStyle.OUTER_FLOATING_SM)
            }
          }
          .justifyContent(FlexAlign.Center)
          .padding(48)
          .height(ResponsiveUtil.PuraXOuterCheck() ? undefined : '40%')

          Column({space: 24}) {
            Text(this.title)
              .fontSize(24)
              .fontWeight(FontWeight.Bolder)
              .fontColor(this.useDefaultTextColor ? $r('sys.color.font_primary') : Color.White)
              .textShadow(this.useDefaultTextColor ? undefined: {
                color: '#66ffffff',
                radius: 24,
                offsetY: 4
              })
            Text(this.subtitle)
              .fontColor(this.useDefaultTextColor ? $r('sys.color.font_primary') : Color.White)
          }
          .margin(24)

          Blank()
            .layoutWeight(1)

          Row() {
            if (this.footer) {
              this.footer()
            }
            if (this.useButtonFooter) {
              Button(this.buttonFooterText)
                .onClick(() => {this.buttonFooterOnClick()})
                .width('100%')
            }
          }.margin(24).justifyContent(FlexAlign.Center)
        }
      }
      .padding(ResponsiveUtil.chooseByWidth<Padding>([{bottom: 48}, {bottom: 48, left: '10%', right: '10%'}, {bottom: 48, left: '20%', right: '20%'}]))
    }.width('100%').height('100%')
    .edgeEffect(EdgeEffect.Spring, {
      alwaysEnabled: false
    }).scrollBar(BarState.Off)
    .fadingEdge(true, {
      fadingEdgeLength: LengthMetrics.percent(10)
    })
    .clip(false)
  }
}

@ComponentV2
export struct SymbolTitle {
  @Param @Require icon: Resource
  @Param iconSize: number = 50
  @Param @Require gradientColor: ResourceColor[]

  @Builder customHeader() {
    Stack() {
      Column() {
        SymbolGlyph(this.icon)
          .fontColor([Color.White])
          .fontWeight(FontWeight.Normal)
          .fontSize(this.iconSize)
      }
      .width(100)
      .height(100)
      .justifyContent(FlexAlign.Center)
      .borderRadius(24)
      .linearGradient({
        angle: 135,
        colors: [[this.gradientColor[0], 0], [this.gradientColor[1], 1]]
      })
      .foregroundEffect({
        radius: 128
      })
      // .borderRadius(24)
      .brightness(1.1)
      .saturate(3)
      .translate({y: 8})
      // .scale({x: 1.2, y: 1.2})

      Column() {
        SymbolGlyph(this.icon)
          .fontColor([Color.White])
          .fontWeight(FontWeight.Normal)
          .fontSize(this.iconSize)
      }
      .width(100)
      .height(100)
      .justifyContent(FlexAlign.Center)
      .borderRadius(24)
      .linearGradient({
        angle: 135,
        colors: [[this.gradientColor[0], 0], [this.gradientColor[1], 1]]
      })
      .shadow(ShadowStyle.OUTER_DEFAULT_SM)
    }
  }
  build() {
    this.customHeader()
  }
}

