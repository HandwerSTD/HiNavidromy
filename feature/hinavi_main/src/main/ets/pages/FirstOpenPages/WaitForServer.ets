import GlobalStore from "../../common/statemgmt/GlobalStore";
import { ServerLoadStatus } from "../../common/utils/NavidromeServerUtils";
import { ImageTitleWelcomeTemplate, SymbolTitle } from "./CommonTemplate";
import { common } from "@kit.AbilityKit";

@ComponentV2
export struct WaitForServer {
  @Builder icon() {
    SymbolTitle({
      icon: $r('sys.symbol.planets'),
      gradientColor: [0x02c1f8, 0x025fea]
    })
  }

  @Builder footer() {
    if (GlobalStore.serverStatus === ServerLoadStatus.LOADING) {
      Row() {
        Progress({ value: GlobalStore.fakeLoadingProgress, total: 100, type: ProgressType.Linear })
          .style({ strokeWidth: 4 })
          .layoutWeight(1)
      }.width('100%')
      .padding({left: 12, right: 12, bottom: 12})
    } else {
      Button('尝试重启')
        .width('100%')
        .onClick(() => {
          (this.getUIContext().getHostContext()! as common.UIAbilityContext).getApplicationContext().restartApp({
            bundleName: 'top.handwer.hish.hinavidromy',
            abilityName: 'EntryAbility'
          })
        })
    }
  }

  build() {
    ImageTitleWelcomeTemplate({
      customImage: this.icon,
      title: '应用启动中',
      subtitle: GlobalStore.serverStatus === ServerLoadStatus.LOADING ? '正在加载服务器，此过程可能持续约一分钟，请不要退至后台或锁屏' : '服务器上线失败',
      footer: () => { this.footer() }
    })
  }
}