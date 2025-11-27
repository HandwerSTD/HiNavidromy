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