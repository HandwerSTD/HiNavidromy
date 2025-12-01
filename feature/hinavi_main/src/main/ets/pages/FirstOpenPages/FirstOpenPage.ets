import GlobalStore from '../../common/statemgmt/GlobalStore'
import { ServerLoadStatus } from '../../common/utils/NavidromeServerUtils'
import { ImageTitleWelcomeTemplate } from './CommonTemplate'
import { NavServer } from './NavServer'
import { FinalWelcome, OpenWelcome } from './OpenWelcome'
import { WaitForServer } from './WaitForServer'
import { HdsNavigation } from '@hms.hds.hdsBaseComponent'
import { SharedFolderContent } from '../../components/SharedFolderContent'
import { NavidromeWeb } from '../../hinavi/views/NavidromeWeb'
import { ImportMusic } from './ImportMusic'
import { NavWebPage } from './NavWebPage'
import { CloudPurePlay } from './CloudPurePlay'

@ComponentV2
export struct FirstOpenPage {
  @Event onClose: () => void

  @Provider('firstOpenStack') pageStack: NavPathStack = new NavPathStack()

  @Builder PageMap(name: string) {
    if (name === 'SharedFolder') {
      NavDestination() {
        SharedFolderContent()
      }.title('文件管理')
    } else if (name === 'NavidromeWeb') {
      NavidromeWeb()
    }
  }

  build() {
    Column() {
      if (GlobalStore.isServerOnline) {
        Navigation(this.pageStack) {
          Swiper() {
            OpenWelcome()
            NavServer()
            ImportMusic()
            NavWebPage()
            CloudPurePlay()
            FinalWelcome({
              onFinish: () => { this.onClose() }
            })
          }.width('100%').height('100%')
          .loop(false)
          .layoutWeight(1)
          .indicator(new DotIndicator().bottom('24vp'))
          .clip(false)
        }.hideTitleBar(true)
        .navDestination(this.PageMap)
        .mode(NavigationMode.Stack)
      } else {
        WaitForServer()
      }
    }
    .width('100%').height('100%')
    // .backgroundColor($r('sys.color.background_secondary'))
  }
}
