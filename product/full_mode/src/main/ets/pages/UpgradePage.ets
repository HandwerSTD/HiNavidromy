import { GlobalStore, ImageTitleWelcomeTemplate, SymbolTitle, SystemImageUtils } from 'hinavi_main'
import { promptAction, router } from '@kit.ArkUI';
import appOption from 'hinavi_main/src/main/ets/model/appOption';
import { preferences } from '@kit.ArkData';
import { application, common, Want } from '@kit.AbilityKit';
import { NavidromeServerUtils, ServerLoadStatus } from 'hinavi_main/src/main/ets/common/utils/NavidromeServerUtils';
import WebTerminal from 'hinavi_main/src/main/ets/components/WebTerminal';
import { RetryUtil } from 'hinavi_main/src/main/ets/common/utils/CommonUtil';
import { DialogHelper } from '@pura/harmony-dialog';

@Entry
@ComponentV2
struct UpgradePage {

  @Local isForce: boolean = true

  aboutToAppear(): void {
    this.checkForceUpdate()
    GlobalStore.isFirstOpenFinished = true
    NavidromeServerUtils.checkConnectionOnStart()
  }

  private async checkForceUpdate() {
    const context = this.getUIContext().getHostContext()!.getApplicationContext()
    this.isForce = await SystemImageUtils.hasForceUpdateTillNow(context)
  }

  @Builder Title() {
    SymbolTitle({
      icon: $r('sys.symbol.arrowshape_up_frame_fill'),
      gradientColor: ['#317af7', '#0a59f7']
    })
  }

  @Builder Footer() {
    if (GlobalStore.serverStatus !== ServerLoadStatus.LOADING) {
      Column({ space: 12 }) {
        if (!this.isForce) {
          Button('跳过更新')
            .onClick(() => {
              this.onSkipClick()
            })
            .width('100%')
            .constraintSize({
              maxWidth: 640
            })
            .buttonStyle(ButtonStyleMode.NORMAL)
        }

        Button('立即更新')
          .onClick(() => {
            this.onUpgradeClick()
          })
          .width('100%')
          .constraintSize({
            maxWidth: 640
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    } else {
      LoadingProgress().height(40)
    }
  }

  private async onUpgradeClick() {
    const id = DialogHelper.showLoadingDialog({
      content: '请等待数据库备份完成'
    })
    RetryUtil.retryIf(30, async () => {
      if (!GlobalStore.todayBackupFinished) throw Error()
    }, () => { return !GlobalStore.todayBackupFinished})
      .then(async () => {
        const context = this.getUIContext().getHostContext()!.getApplicationContext()
        const pref = await preferences.getPreferences(context, appOption.preferenceName)
        // 标记重置 Linux
        await pref.put(appOption.resetLinuxFlag, true)
        // 更新系统版本号
        await SystemImageUtils.updateToCurrentVersionByPref(pref)
        await pref.flush()
        this.restartApp()
      })
      .catch(() => {
        DialogHelper.closeDialog(id)
        this.getUIContext().showAlertDialog({
          message: '等待数据库备份失败，请点击退出程序，等待一分钟后再打开应用尝试',
          primaryButton: {
            value: '退出程序',
            action: () => {
              (this.getUIContext().getHostContext()! as common.UIAbilityContext).terminateSelf()
            }
          }
        })
      })
  }

  private restartApp() {
    const applicationContext = this.getUIContext().getHostContext()!.getApplicationContext()
    const want: Want = {
      bundleName: 'top.handwer.hish.hinavidromy',
      abilityName: 'EntryAbility',
      parameters: {
        "upgrade": true
      }
    }
    applicationContext.restartApp(want)
  }

  private async onSkipClick() {
    const context = this.getUIContext().getHostContext()!.getApplicationContext()
    await SystemImageUtils.ignoreCurrentVersionUpdate(context)
    this.getUIContext().getRouter().replaceUrl({
      url: 'pages/HiNaviEntry'
    })
  }

  private getSubtitle(): string {
    let baseText = 'HiNavidromy 的系统软件包有重大升级，升级新版本可以获得更流畅、更稳定的体验。新版本包含性能优化和问题修复，建议您立即更新以获得最佳使用体验。'
    if (!this.isForce) {
      baseText += '\n\n本次更新为可选更新，您可以选择忽略此更新，忽略更新不会影响您的正常使用。'
    } else {
      baseText += '\n\n本次更新为强制更新，这意味着应用引入了重大、与前代版本不兼容的升级优化，您必须更新才能继续正常使用。'
    }
    return baseText + '\n\n软件更新不会导致您的音乐库、听歌数据发生损坏或丢失，在更新完成后，您可以像往常一样继续使用。'
  }

  build() {
    Column() {
      ImageTitleWelcomeTemplate({
        title: '系统更新',
        customImage: () => { this.Title() },
        subtitle: this.getSubtitle(),
        footer: () => { this.Footer() }
      })
      WebTerminal().height(1).opacity(0)
    }
    .height('100%')
    .width('100%')
  }
}
