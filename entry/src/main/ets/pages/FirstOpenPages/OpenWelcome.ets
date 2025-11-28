import { WantUtil } from "@pura/harmony-utils"
import { ImageTitleWelcomeTemplate } from "./CommonTemplate"

@ComponentV2
export struct OpenWelcome {

  build() {
    Column() {
      ImageTitleWelcomeTemplate({
        title: '欢迎！',
        subtitle: 'HiNavidromy',
        image: $r('app.media.startIcon'),
      })
    }.width('100%').height('100%')
  }
}
@ComponentV2
export struct FinalWelcome {
  @Event onFinish: () => void

  build() {
    Column() {
      ImageTitleWelcomeTemplate({
        title: '欢迎使用 HiNavidromy',
        subtitle: '装进口袋里的 Navidrome 服务器',
        image: $r('app.media.startIcon'),
        useButtonFooter: true,
        buttonFooterText: '开始使用',
        buttonFooterOnClick: () => {
          this.onFinish()
        }
      })
    }.width('100%').height('100%')
  }
}