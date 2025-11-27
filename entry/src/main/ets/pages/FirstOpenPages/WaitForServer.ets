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
      LoadingProgress().width(50)
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
      title: '等待服务器上线',
      subtitle: GlobalStore.serverStatus === ServerLoadStatus.LOADING ? '正在等待服务器上线' : '服务器上线失败',
      footer: () => { this.footer() }
    })
  }
}