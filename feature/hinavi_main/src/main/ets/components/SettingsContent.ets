import { CustomContentDialog, promptAction, window } from '@kit.ArkUI';
import { bundleManager, common, Want } from '@kit.AbilityKit';
import preference from '@ohos.data.preferences';
import appOption from '../model/appOption';
import { OpenSourceContent } from './OpenSourceContent';
import { BlockTitle, LinkItem, SettingBlockStyle, SettingItem } from './SettingsBase';
import { fileIo as fs } from '@kit.CoreFileKit'
import { ListFileOptions } from '@kit.CoreFileKit';
import { BackgroundTaskManager } from '../common/utils/BackgroundTaskManager';
import { geoLocationManager } from '@kit.LocationKit';
import { PermissionUtil } from '@pura/harmony-utils';
import { CommonItemContainer } from './component_library/CommonListItem';
import GlobalStore from '../common/statemgmt/GlobalStore';
import { MiscUtils } from '../common/utils/Misc';

const cpuOptions: number[] = [1, 2, 4, 6, 8, 10, 16, 24, 32]
const memOptions: number[] = [512, 1024, 2 * 1024, 4 * 1024, 6 * 1024, 8 * 1024, 12 * 1024, 16 * 1024]

function getCpuCount(): number {
  try {
    let filesDir = "/sys/devices/system/cpu";
    let listFileOption: ListFileOptions = {
      recursion: false,
      listNum: 0,
      filter: {}
    };
    if (listFileOption.filter != undefined) {
      listFileOption.filter.displayName = ['cpu*'];
    }

    let files = fs.listFileSync(filesDir, listFileOption);
    let count = 0;
    for (let i = 0; i < files.length; i++) {
      if (files[i].toString().length > 3 && !isNaN(parseInt(files[i].toString()[3]))) {
        count++;
      }
    }
    return count
  } catch (e) {
    return 4
  }
}

function getMemSize(): number {

  try {
    const info = fs.readLinesSync('/proc/meminfo')
    let item = info.next()
    do {
      if (item.value.indexOf('MemTotal') >= 0) {
        //  parse mem
        const line = item.value.trim().toUpperCase()
        const match = line.match(/MEMTOTAL.*?(\d+)/i)
        if (match) {
          return Math.max(parseInt(match[1]) / 1024, 4 * 1024)
        }
        break
      }
      item = info.next();
    } while (!item.done);
    return 8 * 1024
  } catch (e) {
    return 8 * 1024
  }
}

@Component
export default struct SettingsContent {
  @Watch('saveVmCpuCount') @StorageProp(appOption.cpuCountName) vmCpuCount: number = 1
  @Watch('saveVmMemSize') @StorageProp(appOption.memSizeName) vmMemSize: number = 512
  @Watch('saveKeepScreenOn') @StorageProp(appOption.keepScreenOn) keepScreenOn: boolean = false
  @Watch('saveSimulateBg') @StorageProp(appOption.simulateBg) simulateBg: boolean = false
  @Watch('saveDeveloperMode') @StorageProp(appOption.developerMode) developerMode: boolean = false

  @StorageProp('bundleInfo') bundleInfo?: bundleManager.BundleInfo = undefined
  @StorageProp('versionCode') versionCode: number = 0
  @State cpuOptions: SelectOption[] = []
  @State memOptions: SelectOption[] = []
  openSourceController: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.open_source_license'),
      contentBuilder: () => {
        this.buildOpenSourceView();
      },
      buttons: [{
        value: $r('app.string.SettingComplete_label'),
        buttonStyle: ButtonStyleMode.TEXTUAL,
        action: () => {
          this.openSourceController.close();
        }
      }]
    })
  })
  aboutController: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.about_me'),
      contentBuilder: () => {
        this.buildAboutMe();
      },
      buttons: [{
        value: $r('app.string.SettingComplete_label'),
        buttonStyle: ButtonStyleMode.TEXTUAL,
        action: () => {
          this.aboutController.close();
        }
      }]
    })
  })
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  preferences?: preference.Preferences
  blockStyle: SettingBlockStyle = new SettingBlockStyle()

  async aboutToAppear(): Promise<void> {
    this.preferences = await preference.getPreferences(this.context.getApplicationContext(), appOption.preferenceName)

    const cpuCount = getCpuCount()
    this.cpuOptions = cpuOptions.filter(c => c <= cpuCount).map(c => ({ value: c.toString() } as SelectOption))

    const memSize = getMemSize()
    this.memOptions = memOptions.filter(c => c < memSize).map(c => ({ value: c.toString() } as SelectOption))
  }

  saveVmCpuCount() {
    this.preferences!.put(appOption.cpuCountName, this.vmCpuCount)
    this.preferences!.flush()
  }

  saveVmMemSize() {
    this.preferences!.put(appOption.memSizeName, this.vmMemSize)
    this.preferences!.flush()
  }

  saveKeepScreenOn() {
    this.preferences!.put(appOption.keepScreenOn, this.keepScreenOn)
    this.preferences!.flush()

    const mainWindow = AppStorage.get('mainWindow') as window.Window
    if (mainWindow) {
      mainWindow.setWindowKeepScreenOn(this.keepScreenOn)
    }
  }

  saveSimulateBg() {
    this.preferences!.put(appOption.simulateBg, this.simulateBg)
    this.preferences!.flush()
    if (this.simulateBg) {
      PermissionUtil.requestPermissionsEasy("ohos.permission.APPROXIMATELY_LOCATION")
        .then((res) => {
          if (!res) {
            promptAction.showToast({
              message: '请授予权限'
            })
            return;
          }
          geoLocationManager.on("locationChange", {
            interval: 10,
            locationScenario: geoLocationManager.PowerConsumptionScenario.NO_POWER_CONSUMPTION
          }, () => {})
          BackgroundTaskManager.startContinuousTask(this.getUIContext().getHostContext()! as common.UIAbilityContext)
          promptAction.showToast({
            message: '启动成功'
          })
        })
        GlobalStore.simulateBg = true

    } else {
      BackgroundTaskManager.stopContinuousTask(this.getUIContext().getHostContext()! as common.UIAbilityContext)
      GlobalStore.simulateBg = false
    }
  }

  saveDeveloperMode() {
    this.preferences!.put(appOption.developerMode, this.developerMode)
    this.preferences!.flush()
  }

  @Builder
  private cpuSetting() {
    Select(this.cpuOptions)
      .width(100)
      .value(this.vmCpuCount.toString())
      .onSelect((_i, value) => AppStorage.setOrCreate(appOption.cpuCountName, parseInt(value)))
  }

  @Builder
  private memorySetting() {
    Select(this.memOptions)
      .width(100)
      .value(this.vmMemSize.toString())
      .onSelect((_i, value) => AppStorage.setOrCreate(appOption.memSizeName, parseInt(value)))
  }

  @Builder
  private keepScreenSetting() {
    Checkbox()
      .select(this.keepScreenOn)
      .onChange((value: boolean) => {
        AppStorage.setOrCreate(appOption.keepScreenOn, value)
      })
  }
  @Builder
  private simulateBackground() {
    Checkbox()
      .select(this.simulateBg)
      .onChange((value: boolean) => {
        AppStorage.setOrCreate(appOption.simulateBg, value)
      })
  }

  @Builder
  private developerModeSetting() {
    Checkbox()
      .select(this.developerMode)
      .onChange((value: boolean) => {
        AppStorage.setOrCreate(appOption.developerMode, value)
      })
  }

  build() {
    Column() {
      Scroll() {
        Column({space: 12}) {

          BlockTitle({ content: $r("app.string.setting_block_system") })
          CommonItemContainer() {
            SettingItem({
              title: $r('app.string.setting_cpu'),
              subTitle: $r('app.string.setting_cpu_desc'),
              content: () => {
                this.cpuSetting()
              }
            })

            SettingItem({
              title: $r('app.string.setting_mem_size'),
              subTitle: '设置内存大小 (MB)，推荐 2048 MB',
              content: () => {
                this.memorySetting()
              }
            })

            SettingItem({
              title: $r('app.string.setting_reset_linux'),
              subTitle: $r('app.string.setting_reset_linux_desc'),
              icon: $r('sys.symbol.arrow_clockwise')
            }).onClick(() => {
              this.openResetLinuxDialog()
            })
          }

          BlockTitle({ content: $r("app.string.setting_block_display") })
          CommonItemContainer() {
            SettingItem({
              title: $r('app.string.setting_keep_screen_on'),
              subTitle: $r('app.string.setting_keep_screen_on_desc'),
              content: () => {
                this.keepScreenSetting()
              }
            })
              .onClick(() => {
                AppStorage.setOrCreate(appOption.keepScreenOn, !this.keepScreenOn)
              })
            SettingItem({
              title: '模拟后台运行',
              subTitle: '使用定位权限模拟后台运行',
              content: () => {
                this.simulateBackground()
              }
            })
              .onClick(() => {
                AppStorage.setOrCreate(appOption.simulateBg, !this.simulateBg)
              })
            // SettingItem({
            //   title: '开发者模式',
            //   subTitle: '开启后暴露终端入口',
            //   content: () => {
            //     this.developerModeSetting()
            //   }
            // })
            //   .onClick(() => {
            //     AppStorage.setOrCreate(appOption.developerMode, !this.developerMode)
            //   })
          }

          BlockTitle({ content: $r('app.string.setting_block_about') })
          CommonItemContainer() {
            LinkItem({
              icon: $r('sys.symbol.house'),
              title: $r('app.string.code_repository'),
              click: () => {
                MiscUtils.openSourceRepo(this.getUIContext())
              }
            })

            LinkItem({
              icon: $r('sys.symbol.doc_text_badge_checkmark'),
              title: $r('app.string.open_source_license'),
              click: () => {
                this.openSourceController.open();
              }
            })

            LinkItem({
              icon: $r('sys.symbol.info_circle'),
              title: $r('app.string.about_me'),
              click: () => {
                this.aboutController.open();
              }
            })
          }
        }
        .margin(12)
      }
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Auto)
      .scrollBarWidth(1)
      .layoutWeight(1)
      .align(Alignment.Top)
    }
  }

  @Builder
  buildOpenSourceView() {
    OpenSourceContent()
  }

  @Builder
  buildAboutMe() {
    Column() {

      Image($r('app.media.startIcon'))
        .width(50)

      Text('HiNavidromy')
        .margin({ top: 10 })

      Text(`${this.bundleInfo?.versionName}(${this.bundleInfo?.versionCode})`)
        .fontSize(14)
        .fontColor('#ccc')
        .margin({ top: 5 })
    }
    .width('100%')
  }

  private openResetLinuxDialog() {
    this.getUIContext().showAlertDialog({
      title: $r('app.string.setting_reset_linux_title'),
      message: $r('app.string.setting_reset_linux_content'),
      autoCancel: true,
      alignment: DialogAlignment.Center,
      buttons: [
        {
          value: $r('app.string.setting_generic_cancel'),
          action: () => {
          }
        },
        {
          enabled: true,
          style: DialogButtonStyle.HIGHLIGHT,
          backgroundColor: $r('sys.color.warning'),
          value: $r('app.string.setting_reset_linux_reset'),
          action: async () => {
            await this.markResetLinuxAndRestart();
          }
        }
      ],
    });
  }

  private async toWebBrowser(url: string): Promise<void> {
    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    let want: Want = {
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browsable'],
      uri: url,
      parameters: {
        bundleName: context.abilityInfo.bundleName
      }
    };
    await context.startAbility(want);
  }

  private async markResetLinuxAndRestart() {
    await this.preferences?.put(appOption.resetLinuxFlag, true);
    await this.preferences?.flush();
    this.restartApp();
  }

  private async restartApp() {
    let applicationContext = this.context.getApplicationContext();
    let want: Want = {
      bundleName: this.bundleInfo?.name,
      abilityName: 'EntryAbility'
    };
    applicationContext.restartApp(want);
  }
}