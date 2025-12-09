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
import { ServiceInitUtils } from '../../../../Index'
import { MiscUtils } from '../common/utils/Misc'
import { CommonConst } from '../common/constants/CommonConsts'
import { privacyManager } from '@kit.AppGalleryKit'
import { MyLogUtil } from '../common/utils/Logger'

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
    GlobalStore.isFirstOpenFinished = firstOpenCompleted

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
    return `https://handwer.space/cloudpureplay?action=shareConfig&type=plain&api=Navidrome&data=${data}`
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

  @Builder RecommendActions() {
    if (VMSwitcher.isTCI) {
      ListItem() {
        CommonListItem({
          icon: $r('sys.symbol.camera_mode_slow'),
          title: '正在以兼容模式运行，Navidrome 运行速度将显著变慢，推荐使用开源版本以提升性能',
          subtitle: '点击查看说明'
        }).onClick(() => {
          this.getUIContext().showAlertDialog({
            title: '兼容模式',
            message: 'HiNavidromy 正在以兼容模式运行，此模式下内部代码会经过一层转译，因此运行速度可能显著变慢。进入兼容模式的原因可能有：\n' +
              '1. 由于权限限制，在 AppGallery 应用市场安装时，仅支持兼容模式运行\n' +
              '2. 您的设备开启了「坚盾守护模式」，此模式下应用运行权限受限，仅能使用兼容模式运行\n' +
              '对于第一种情况，您可以自行构建开源版本，并使用开发者模式安装，可不经过转译高速运行，同时也可提升性能与耗电表现。',
            primaryButton: {
              value: '去查看开源仓库',
              action: () => {
                MiscUtils.openSourceRepo(this.getUIContext())
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
    if (!GlobalStore.simulateBg) {
      ListItem() {
        CommonListItem({
          icon: $r('sys.symbol.background_blurred'),
          title: '应用在后台可能被冻结，Navidrome 可能无法连接',
          subtitle: '点击启用模拟后台'
        }).onClick(() => {
          ServiceInitUtils.startSimulateBg(this.getUIContext().getHostContext()! as common.UIAbilityContext, true)
        })
      }
    }
  }

  @Builder MainList() {
    List({space: 12, scroller: this.scroller}) {
      this.RecommendActions()
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
              MiscUtils.requestForceBg(this.getUIContext(), () => {
              (this.getUIContext().getHostContext()! as common.UIAbilityContext).openLink('https://handwer.space/cloudpureplay')
              })
            })
            CommonListItem({
              icon: $r('sys.symbol.arrowshape_up'),
              title: '拉起云净听添加配置',
              isCompose: true,
            }).onClick(() => {
              MiscUtils.requestForceBg(this.getUIContext(), () => {
              (this.getUIContext().getHostContext()! as common.UIAbilityContext).openLink(this.sharePlainAPILink())
              })
            })
          }
        }.transition(TransitionEffect.OPACITY.animation({duration: 300}))
      }
      ListItem() {
        CommonListItem({
          icon: $r('sys.symbol.globe_badge_heart'),
          title: 'Navidrome 主页'
        }).onClick(() => {
          GlobalStore.pageStack.push('NavidromeWeb', [])
        })
      }
      ListItem() {
        CommonListItem({
          icon: $r('sys.symbol.music_note_list'),
          title: '音乐文件管理'
        })
          .onClick(() => {
            GlobalStore.pageStack.push('MusicFolder',[])
          })
      }
      ListItem() {
        Column(){
          CommonListItem({
            icon: $r('sys.symbol.gearshape'),
            title: '应用设置'
          })
            .onClick(() => {
              GlobalStore.pageStack.push('Settings',[])
            })
          if (!GlobalStore.showTerminal) {
            WebTerminal().height(1).clip(true).opacity(0).hitTestBehavior(HitTestMode.Block)
          }
        }
      }
      // if (GlobalStore.isServerOnline) {
      //   ListItem() {
      //     Button('正常关机').width('100%').backgroundColor($r('sys.color.warning'))
      //       .onClick(() => {
      //         this.getUIContext().showAlertDialog({
      //           message: '确定要关机吗？',
      //           primaryButton: {
      //             value: $r('sys.string.general_confirm'),
      //             fontColor: $r('sys.color.warning'),
      //             action: () => {
      //               this.showTerminal = true
      //               VMUtils.suspendAndExecuteCommand('poweroff')
      //             }
      //           },
      //           secondaryButton: {
      //             value: $r('sys.string.general_cancel'),
      //             // fontColor: $r('sys.color.warning'),
      //             action: () => {}
      //           }
      //         })
      //       })
      //   }
      // }
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
                this.getUIContext().showAlertDialog({
                  title: '终端管理',
                  message: '终端仅提供给高级用户进行自定义操作，不当操作可能会导致 Navidrome 服务器损坏、数据丢失甚至您的设备损坏，在执行前请确保你知道自己在做什么。对于不当使用终端导致的软件、硬件损坏或数据丢失，本软件与开发者对此不负任何责任。',
                  primaryButton: {
                    action:  ()=>{
                      GlobalStore.pageStack.push('CommonCommands',[])
                    },
                    value: $r('sys.string.general_confirm')
                  },
                  secondaryButton: {
                    action: ()=>{},
                    value: $r('sys.string.general_cancel')
                  }
                })
              })
            }
            CommonListItem({
              icon: $r('sys.symbol.rectangle_stack'),
              title: '终端管理',
              isCompose: true
            })
              .onClick(() => {
                this.getUIContext().showAlertDialog({
                  title: '实时终端',
                  message: '终端仅提供给高级用户进行自定义操作，不当操作可能会导致 Navidrome 服务器损坏、数据丢失甚至您的设备损坏，在执行前请确保你知道自己在做什么。对于不当使用终端导致的软件、硬件损坏或数据丢失，本软件与开发者对此不负任何责任。',
                  primaryButton: {
                    action:  ()=>{
                      GlobalStore.showTerminal = true
                    },
                    value: $r('sys.string.general_confirm')
                  },
                  secondaryButton: {
                    action: ()=>{},
                    value: $r('sys.string.general_cancel')
                  }
                })
              })
          }
        }
      }
      ListItem() {
        CommonItemContainer() {
          CommonListItem({
            icon: $r('sys.symbol.doc_text_badge_magnifyingglass'),
            title: '重新查看新手引导',
            isCompose: true
          }).onClick(() => {
            this.showFirstStart = !this.showFirstStart
          })
          CommonListItem({
            icon: $r('sys.symbol.doc_plaintext_and_pencil'),
            title: '加入交流群',
            isCompose: true
          }).onClick(() => {
            WantUtil.toWebBrowser('https://qm.qq.com/q/6Gn9dWgmME')
          })
          CommonListItem({
            icon: $r('sys.symbol.lightbulb_max'),
            title: '开源仓库',
            isCompose: true
          }).onClick(() => {
            MiscUtils.openSourceRepo(this.getUIContext())
          })
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
        GlobalStore.isFirstOpenFinished = true
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
      .navBarWidth('40%')
      .backgroundColor($r('sys.color.background_secondary'))
      .expandSafeArea()
      .bindSheet(this.showFirstStart!!, this.FirstStart(), {
        showClose: false, onWillDismiss: (action) => {
          if (!this.showFirstStart) action.dismiss()
        },backgroundColor: $r('sys.color.ohos_id_color_panel_bg'),
        preferType: SheetType.CENTER
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
        '2. 虚拟机内服务器启动失败\n' +
        '如果您不知道为什么会这样，可以选择重启应用，在大多数情况下会恢复正常',
      primaryButton: {
        value: '重启应用',
        action: () => {
          (this.getUIContext().getHostContext()!).getApplicationContext().restartApp({
            bundleName: CommonConst.bundleName,
            abilityName: CommonConst.fullModeAbility
          })
        }
      },
      secondaryButton: {
        value: $r('sys.string.general_confirm'),
        action: () => {}
      }
    })
  }
}