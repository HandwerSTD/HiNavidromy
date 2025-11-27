import GlobalStore from '../../common/statemgmt/GlobalStore'
import { ServerLoadStatus } from '../../common/utils/NavidromeServerUtils'
import { ImageTitleWelcomeTemplate } from './CommonTemplate'
import { OpenWelcome } from './OpenWelcome'
import { WaitForServer } from './WaitForServer'

@Entry
@ComponentV2
struct FirstOpenPage {

  private jumpToApp() {

  }


  build() {
    Column() {
      if (GlobalStore.isServerOnline) {
        Swiper() {
          OpenWelcome()
        }.width('100%').height('100%')
        .loop(false)
        .layoutWeight(1)
        .clip(false)
      } else if (GlobalStore.serverStatus === ServerLoadStatus.LOADING) {
        WaitForServer()
      }
    }
    .width('100%').height('100%')
    .backgroundColor($r('sys.color.background_secondary'))
  }
}
