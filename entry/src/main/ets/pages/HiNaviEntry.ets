import { SpinKit } from '@pura/harmony-dialog'
import GlobalStore from '../common/statemgmt/GlobalStore'
import { NavidromeServerUtils, ServerLoadStatus, VMUtils } from '../common/utils/NavidromeServerUtils'
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

  scroller = new Scroller()

  aboutToAppear(): void {
    NavidromeServerUtils.checkConnectionOnStart()
      .catch(() => {
        GlobalStore.serverStatus = ServerLoadStatus.TIMEOUT
        this.showTimeoutDialog()
      })
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
    } else if (GlobalStore.serverStatus === ServerLoadStatus.LOADING) {
      LoadingProgress().width(24)
    } else {
      SymbolGlyph($r('sys.symbol.exclamationmark')).fontColor([$r('sys.color.warning')]).fontWeight(FontWeight.Bold)
        .fontSize(16)
    }
  }

  @Builder MainList() {
    List({space: 12, scroller: this.scroller}) {
      ListItem() {
        CommonListItem({
          icon: $r('sys.symbol.planets'),
          title: '服务器状态',
          subtitle: GlobalStore.isServerOnline ? '已连接' : (GlobalStore.serverStatus === ServerLoadStatus.LOADING ? '连接中' : '连接失败')
        }) {
          this.UpStatus()
        }
      }.onClick(() => {
        if (GlobalStore.serverStatus === ServerLoadStatus.TIMEOUT) {
          this.showTimeoutDialog()
        }
      })
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
        Button('正常关机').width('100%').backgroundColor($r('sys.color.warning'))
          .onClick(() => {
            this.getUIContext().showAlertDialog({
              message: '确定要关机吗？',
              primaryButton: {
                value: $r('sys.string.general_confirm'),
                fontColor: $r('sys.color.warning'),
                action: () => {
                  this.showTerminal = true
                  VMUtils.breakAndExecuteCommand('poweroff')
                }
              },
              secondaryButton: {
                value: $r('sys.string.general_cancel'),
                // fontColor: $r('sys.color.warning'),
                action: () => {}
              }
            })
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

  showTimeoutDialog() {
    this.getUIContext().showAlertDialog({
      title: '服务器连接超时',
      message: '无法连接到位于 localhost:4533 的服务器，可能有以下原因：\n' +
        '1. 上次虚拟机退出时未正常关机\n' +
        '2. 向外部端口映射失败或 4533 端口被占用\n' +
        '3. 虚拟机内服务器启动失败',
    })
  }
}