import { SpinKit } from '@pura/harmony-dialog'
import GlobalStore from '../common/statemgmt/GlobalStore'
import { NavidromeServerUtils } from '../common/utils/NavidromeServerUtils'
import { CommonListItem } from '../components/component_library/CommonListItem'
import SettingsContent from '../components/SettingsContent'
import { SharedFolderContent } from '../components/SharedFolderContent'
import WebTerminal from '../components/WebTerminal'
import { NavidromeWeb } from '../hinavi/views/NavidromeWeb'
import { Index } from './Index'


@Entry
@ComponentV2
struct HiNaviEntry {
  @Local showTerminal: boolean = true

  aboutToAppear(): void {
    NavidromeServerUtils.checkConnectionOnStart()
  }

  @Builder PageMap(name: string) {
    if (name === 'MusicFolder') {
      NavDestination() {
        SharedFolderContent()
      }.title('文件管理')
      .width('100%').height('100%')
    } else if (name === 'NavidromeWeb') {
      NavidromeWeb()
    } else if (name === 'Settings') {
      NavDestination() {
        SettingsContent()
      }.title('应用设置')
    }
  }

  @Builder Terminal() {
    Column() {
      Button(this.showTerminal ? '隐藏' : '显示').width('100%')
        .onClick(() => {
          this.showTerminal = !this.showTerminal
        })
      WebTerminal({
        showVirtKey: true
      }).layoutWeight(1)
        .visibility(this.showTerminal ? Visibility.Visible : Visibility.None)
        // .transition(TransitionEffect.OPACITY.animation({duration: 300}))
        .padding({top: 12, bottom: 12})
    }.width('100%')
    .height(this.showTerminal ? 500 : 40)
    .animation({duration: 300})
  }

  @Builder UpStatus() {
    if (GlobalStore.isServerOnline) {
      SymbolGlyph($r('sys.symbol.checkmark')).fontColor([$r('sys.color.font')]).fontWeight(FontWeight.Bold)
        .fontSize(16)
    } else {
      LoadingProgress().width(24)
    }
  }

  @Builder MainList() {
    List({space: 12}) {
      ListItem() {
        CommonListItem({
          icon: $r('sys.symbol.planets'),
          title: '服务器状态'
        }) {
          this.UpStatus()
        }
      }
      ListItem() {
        CommonListItem({
          icon: $r('sys.symbol.globe_badge_heart'),
          title: 'Navidrome 主页'
        }).onClick(() => {
          GlobalStore.pageStack.pushPathByName('NavidromeWeb', [])
        })
      }
      ListItem() {
        CommonListItem({
          icon: $r('sys.symbol.music_note_list'),
          title: '音乐文件管理'
        })
          .onClick(() => {
            GlobalStore.pageStack.pushPathByName('MusicFolder',[])
          })
      }
      ListItem() {
        CommonListItem({
          icon: $r('sys.symbol.gearshape'),
          title: '应用设置'
        })
          .onClick(() => {
            GlobalStore.pageStack.pushPathByName('Settings',[])
          })
      }
      ListItem() {
        CommonListItem({
          icon: $r('sys.symbol.text_alignleft'),
          title: '终端管理',
          trailing: () => {
            this.Terminal()
          },
          trailingOnBottom: true
        })
      }
    }
    .padding({left: 12, right: 12})
    .expandSafeArea()
    .edgeEffect(EdgeEffect.Spring, {alwaysEnabled: true})
    .layoutWeight(1)
  }

  build() {
    Navigation(GlobalStore.pageStack) {
      this.MainList()
    }.width('100%')
    .height('100%')
    .navDestination(this.PageMap)
    .title($r('app.string.app_name'))
    .backgroundColor($r('sys.color.background_secondary'))
    .expandSafeArea()
  }
}