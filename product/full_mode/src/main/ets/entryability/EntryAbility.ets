import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { window, KeyboardAvoidMode, promptAction } from '@kit.ArkUI';
import { deviceInfo } from '@kit.BasicServicesKit';
import appOption from 'hinavi_main/src/main/ets/model/appOption'
import { ServiceInitUtils } from 'hinavi_main';
import { preferences } from '@kit.ArkData';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  private isShouldInRecoveryMode: boolean = false

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    if (launchParam.lastExitDetailInfo) {
      console.info(`pid: ${launchParam.lastExitDetailInfo.pid}
      \n processName: ${launchParam.lastExitDetailInfo.processName}
      \n uid: ${launchParam.lastExitDetailInfo.uid}
      \n exitSubReason: ${launchParam.lastExitDetailInfo.exitSubReason}
      \n exitMsg: ${launchParam.lastExitDetailInfo.exitMsg}
      \n rss: ${launchParam.lastExitDetailInfo.rss}
      \n pss: ${launchParam.lastExitDetailInfo.pss}
      \n timestamp: ${launchParam.lastExitDetailInfo.timestamp}
      \n processState: ${launchParam.lastExitDetailInfo.processState}.`
      );
    }
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    this.onHandleWant(want)
    // hiAppEvent.addWatcher({
    //   name: 'NATIVE_EXIT_WATCHER',
    //   appEventFilters: [{
    //     domain: hiAppEvent.domain.OS,
    //     names: [hiAppEvent.event.APP_CRASH]
    //   }],
    //   onReceive: (d, g) => {
    //     const msg = JSON.stringify(g)
    //     console.log('fault message = ' + msg)
    //     if (msg.includes('Unexpected call: exit(1)')) {
    //       promptAction.showToast({
    //         message: '正在进入恢复模式'
    //       })
    //       this.context.getApplicationContext().restartApp({
    //         abilityName: 'EntryAbility',
    //         bundleName: 'top.handwer.hish.hinavidromy',
    //         parameters: {
    //           "recovery": true
    //         }
    //       })
    //     } else if (msg.includes('Unexpected call: exit(0)')) {
    //       promptAction.showToast({
    //         message: '上次正常退出'
    //       })
    //     }
    //   }
    // })
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onHandleWant(want: Want) {
    if (want.parameters) {
      if (want.parameters['recovery']) {
        this.isShouldInRecoveryMode = true
      }
    }
  }
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    if (want.parameters?.['recovery']) {
      promptAction.showToast({
        message: '正在进入恢复模式'
      })
      setTimeout(() => {
        this.context.getApplicationContext().restartApp({
          bundleName: 'top.handwer.hish.hinavidromy',
          abilityName: 'EntryAbility',
          parameters: {
            "recovery": true
          }
        })
      }, 2000)
    }
  }

  async onWindowStageCreate(windowStage: window.WindowStage) {
    if (this.isShouldInRecoveryMode) {
      windowStage.loadContent('pages/RecoveryPage', (err) => {
        if (err.code) {
          hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
          return;
        }
        hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
      });
      return;
    }
    await ServiceInitUtils.onWindowStageCreate(this.context)
    const pref = await preferences.getPreferences(this.context.getApplicationContext(), appOption.preferenceName)
    const firstOpenCompleted = await pref.get(appOption.firstOpenCompleted, false) as boolean
    let jumpPage = 'pages/HiNaviEntry'
    if (!firstOpenCompleted) jumpPage = 'pages/FirstOpenPlaceholder'

    windowStage.loadContent(jumpPage, (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');

      let mainWindow = windowStage.getMainWindowSync();
      ServiceInitUtils.startSimulateBg(this.context)
      mainWindow.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE);
      mainWindow.setWindowKeepScreenOn(AppStorage.get(appOption.keepScreenOn) as boolean);

      AppStorage.setOrCreate('mainWindow', mainWindow)

      if (canIUse('SystemCapability.Window.SessionManager')
        && deviceInfo.deviceType === '2in1') {
        mainWindow.setWindowDecorVisible(false);
        mainWindow.setWindowDecorHeight(48);
      }
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}