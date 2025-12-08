import { ImageTitleWelcomeTemplate, SymbolTitle } from 'hinavi_main'
import appOption from 'hinavi_main/src/main/ets/model/appOption';
import { preferences } from '@kit.ArkData';
import { Want } from '@kit.AbilityKit';

@Entry
@ComponentV2
struct RecoveryPage {

  @Builder Title() {
    SymbolTitle({
      icon: $r('sys.symbol.mainboard_fault'),
      gradientColor: ['#FF9500', '#FF5E3A']
    })
  }

  private async markResetLinuxAndRestart() {
    const pref = await preferences.getPreferences(this.getUIContext().getHostContext()!.getApplicationContext(), appOption.preferenceName)
    await pref.put(appOption.resetLinuxFlag, true);
    await pref.flush();
    this.restartApp()
  }
  private async restartApp() {
    let applicationContext = this.getUIContext().getHostContext()!.getApplicationContext();
    let want: Want = {
      bundleName: 'top.handwer.hish.hinavidromy',
      abilityName: 'EntryAbility'
    };
    applicationContext.restartApp(want);
  }
  build() {
    Column() {
      ImageTitleWelcomeTemplate({
        title: '恢复模式',
        customImage: this.Title,
        subtitle: '由于应用多次意外退出导致数据库损坏，HiNavidromy 已进入恢复模式，点击下方按钮可进行数据库重建。\n\n您的音乐文件将会被完整保留，不会受到任何损坏，但您在 Navidrome 中的用户数据（包括红心歌曲、建立的歌单、收藏的专辑、听歌数据）将被清空。数据库重建后，HiNavidromy 即可恢复正常。',
        useButtonFooter: true,
        buttonFooterOnClick: () => {
          this.markResetLinuxAndRestart()
        },
        buttonFooterText: '启动恢复'
      })
    }
    .height('100%')
    .width('100%')
  }
}