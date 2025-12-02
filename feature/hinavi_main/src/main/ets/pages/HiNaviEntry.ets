import { AegStrUtil } from '@hw-agconnect/petal-aegis'
import common from '@ohos.app.ability.common'
import preference from '@ohos.data.preferences'
import { SpinKit } from '@pura/harmony-dialog'
import { Base64Util, WantUtil } from '@pura/harmony-utils'
import GlobalStore from '../common/statemgmt/GlobalStore'
import appOption from '../model/appOption'
import { NavidromeServerUtils, ServerLoadStatus, VMUtils } from '../common/utils/NavidromeServerUtils'
import { CommonItemContainer, CommonListItem } from '../components/component_library/CommonListItem'
import SettingsContent from '../components/SettingsContent'
import { SharedFolderContent } from '../components/SharedFolderContent'
import WebTerminal from '../components/WebTerminal'
import { NavidromeWeb } from '../hinavi/views/NavidromeWeb'
import { UsefulTerminalView } from '../hinavi/views/UsefulTerminalView'
import { FirstOpenPage } from './FirstOpenPages/FirstOpenPage'
import { VMSwitcher } from '../lib/VMSwitcher'

export interface NavidromeRequestContext {
  baseUrl: string; // Navidrome API 根地址
  username: string;
  password?: string; // 可选（明文登录）
  token?: string; // 可选（已生成的 token）
  salt?: string;  // 用于 Subsonic API token 生成
  apiVersion?: string; // 默认 '1.16.1'
  clientName?: string; // 客户端标识
}

@ComponentV2
export struct HiNaviEntry {
  @Local showTerminal: boolean = true
  @Local showFirstStart: boolean = false

  scroller = new Scroller()
  context = this.getUIContext().getHostContext()! as common.UIAbilityContext
  preferences?: preference.Preferences
  fakeProgressInterval?: number

  async aboutToAppear(): Promise<void> {
    this.preferences = await preference.getPreferences(this.context.getApplicationContext(), appOption.preferenceName)
    const firstOpenCompleted = await this.preferences.get(appOption.firstOpenCompleted, false) as boolean
    this.showFirstStart = !firstOpenCompleted

    // 初始化假进度条
    GlobalStore.fakeLoadingProgress = 0
    const totalDuration = VMSwitcher.isTCI ? 70000 : 10000 // TCI: 70秒, 非TCI: 10秒
    const intervalMs = 100
    const increment = 100 / (totalDuration / intervalMs)
    this.fakeProgressInterval = setInterval(() => {
      if (GlobalStore.fakeLoadingProgress < 100) {
        GlobalStore.fakeLoadingProgress = Math.min(100, GlobalStore.fakeLoadingProgress + increment)
      } else {
        clearInterval(this.fakeProgressInterval)
      }
    }, intervalMs)

    NavidromeServerUtils.checkConnectionOnStart()
      .catch(() => {
        GlobalStore.serverStatus = ServerLoadStatus.TIMEOUT
        this.showTimeoutDialog()
      })
    const portUsedByOthers = AppStorage.get(appOption.portUsedByOthers) as number[]
    if (portUsedByOthers.length > 0) {
      try {
        GlobalStore.serverStatus = ServerLoadStatus.TIMEOUT
        this.showTimeoutDialog()
      } catch (e) {
        console.error(`showToast error`, e);
      }
    }
  }
  sharePlainAPILink() {
    const raw_data = (new AegStrUtil()).ohAegStringToUint8Array(JSON.stringify({
      baseUrl: 'http://localhost:4533/',
      username: 'CloudPurePlay',
      password: 'localhostPurePlay'
    } as NavidromeRequestContext))
    const data = Base64Util.encodeToStrSync(raw_data)
    return `cloudpureplay://shareConfig/share?type=plain&api=Navidrome&data=${data}`
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
    } else if (name === 'CommonCommands') {
      UsefulTerminalView()
    }
  }

  @Builder Terminal() {
    Column() {
      Button(this.showTerminal ? '隐藏' : '显示').width('100%')
        .onClick(() => {
          this.showTerminal = !this.showTerminal
        })
    }.width('100%')
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
      if (VMSwitcher.isTCI) {
        ListItem() {
          CommonListItem({
            icon: $r('sys.symbol.camera_mode_slow'),
            title: '您正在以兼容模式运行，Navidrome 性能可能会受到影响',
            subtitle: '点击查看说明'
          }).onClick(() => {
            this.getUIContext().showAlertDialog({
              title: '兼容模式',
              message: 'HiNavidromy 正在以兼容模式运行，此模式下内部代码会经过一层转译，因此运行速度可能显著变慢。进入兼容模式的原因可能有：\n' +
                '1. 由于权限限制，部分设备在 AppGallery 应用市场安装时，仅支持兼容模式运行\n' +
                '2. 您的设备开启了「坚盾守护模式」，此模式下应用运行权限受限，仅能使用兼容模式运行\n' +
                '对于第一种情况，您可以自行构建开源版本，并使用开发者模式进行运行。',
              primaryButton: {
                value: '去查看开源仓库',
                action: () => {
                  WantUtil.toWebBrowser('https://github.com/HandwerSTD/hinavidromy')
                }
              },
              secondaryButton: {
                value: $r('sys.string.general_confirm'),
                action: () => {}
              },
              buttonDirection: DialogButtonDirection.VERTICAL
            })
          })
        }
      }
      ListItem() {
        CommonItemContainer() {
          CommonListItem({
            icon: $r('sys.symbol.planets'),
            title: '服务器状态',
            subtitle: GlobalStore.isServerOnline ? '已连接' : (GlobalStore.serverStatus === ServerLoadStatus.LOADING ? '连接中' : '连接失败'),
            isCompose: true
          }) {
            this.UpStatus()
          }
          if (GlobalStore.serverStatus === ServerLoadStatus.LOADING) {
            Row() {
              Progress({ value: GlobalStore.fakeLoadingProgress, total: 100, type: ProgressType.Linear })
                .style({ strokeWidth: 4 })
                .layoutWeight(1)
            }.width('100%')
            .padding({left: 12, right: 12, bottom: 12})
          }
        }
      }.onClick(() => {
        if (GlobalStore.serverStatus === ServerLoadStatus.TIMEOUT) {
          this.showTimeoutDialog()
        }
      })
      if (GlobalStore.isServerOnline) {
        ListItem() {
          CommonItemContainer() {
            CommonListItem({
              icon: $r('sys.symbol.identify_song'),
              title: '快速启动云净听',
              isCompose: true,
            }).onClick(() => {
              (this.getUIContext().getHostContext()! as common.UIAbilityContext).openLink('https://handwer.space/cloudpureplay')
            })
            CommonListItem({
              icon: $r('sys.symbol.arrowshape_up'),
              title: '拉起云净听添加配置',
              isCompose: true,
            }).onClick(() => {
              (this.getUIContext().getHostContext()! as common.UIAbilityContext).openLink(this.sharePlainAPILink())
            })
          }
        }.transition(TransitionEffect.OPACITY.animation({duration: 300}))
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
        Button('正常关机').width('100%').backgroundColor($r('sys.color.warning'))
          .onClick(() => {
            this.getUIContext().showAlertDialog({
              message: '确定要关机吗？',
              primaryButton: {
                value: $r('sys.string.general_confirm'),
                fontColor: $r('sys.color.warning'),
                action: () => {
                  this.showTerminal = true
                  VMUtils.suspendAndExecuteCommand('poweroff')
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
      if (GlobalStore.developerMode) {
        ListItem() {
          CommonItemContainer() {
            CommonListItem({
              // icon: $r('sys.symbol.text_alignleft'),
              title: '终端管理',
              isCompose: true
            }) {}
            if (GlobalStore.isServerOnline) {
              CommonListItem({
                icon: $r('sys.symbol.bolt_fill'),
                title: '常用功能',
                isCompose: true
              }).onClick(() => {
                GlobalStore.pageStack.pushPathByName('CommonCommands',[])
              })
            }
            CommonListItem({
              icon: $r('sys.symbol.rectangle_stack'),
              title: '实时终端',
              isCompose: true
            })
              .onClick(() => {
                GlobalStore.showTerminal = true
              })
            if (!GlobalStore.showTerminal) {
              WebTerminal().height(1).clip(true).opacity(0).hitTestBehavior(HitTestMode.Block)
            }
          }
        }
      }
    }
    .padding({left: 12, right: 12})
    .expandSafeArea()
    .edgeEffect(EdgeEffect.Spring, {alwaysEnabled: true})
    .layoutWeight(1)
  }

  @Builder FirstStart() {
    FirstOpenPage({
      onClose: async () => {
        await this.preferences?.put(appOption.firstOpenCompleted, true)
        await this.preferences?.flush()
        this.showFirstStart = false
      }
    })
  }
  @Builder WebTerm() {
    Column({space: 12}) {
      WebTerminal()
        .layoutWeight(1).width('100%')
        .padding({bottom: 12})
      Button('关闭')
        .onClick(() => {
          GlobalStore.showTerminal = false
        })
        .width('100%')
    }.height('100%').padding({left: 12, right: 12, top: 12, bottom: 18})
  }

  build() {
    Column() {
      Navigation(GlobalStore.pageStack) {
        this.MainList()
      }.width('100%')
      .height('100%')
      .navDestination(this.PageMap)
      .title('HiNavidromy')
      .backgroundColor($r('sys.color.background_secondary'))
      .expandSafeArea()
      .bindSheet(this.showFirstStart!!, this.FirstStart(), {
        showClose: false, onWillDismiss: (action) => {
          if (!this.showFirstStart) action.dismiss()
        },backgroundColor: $r('sys.color.ohos_id_color_panel_bg')
      })
    }.bindSheet(GlobalStore.showTerminal!!, this.WebTerm(), {
      showClose: false,backgroundColor: $r('sys.color.ohos_id_color_panel_bg'),
      onDisappear: () => {
        GlobalStore.showTerminal = false;
      },
      preferType: SheetType.CENTER
    })
  }

  showTimeoutDialog() {
    this.getUIContext().showAlertDialog({
      title: '服务器连接超时',
      message: '无法连接到位于 localhost:4533 的服务器，可能有以下原因：\n' +
        '1. 向外部端口映射失败或 4533 端口被占用\n' +
        '2. 虚拟机内服务器启动失败',
    })
  }
}