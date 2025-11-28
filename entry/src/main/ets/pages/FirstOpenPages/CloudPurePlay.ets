import { ImageTitleWelcomeTemplate, SymbolTitle } from "./CommonTemplate";
import { common } from "@kit.AbilityKit";
import { AegStrUtil } from "@hw-agconnect/petal-aegis";
import { Base64Util } from "@pura/harmony-utils";
import { NavidromeRequestContext } from "../HiNaviEntry";

@ComponentV2
export struct CloudPurePlay {
  @Builder icon() {
    SymbolTitle({
      icon: $r('sys.symbol.identify_song'),
      gradientColor: [0x02c1f8, 0x025fea]
    })
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
  build() {
    ImageTitleWelcomeTemplate({
      customImage: this.icon,
      title: '云净听 | 生长在光上',
      subtitle: '我们推荐将 HiNavidromy 与《云净听》配合使用，以获得更好看、更智能的音乐播放体验。《云净听》是一款生长在光上的私有云音乐播放器，支持接入主流音乐协议 Navidrome，还有多设备协同、隔空手势、小艺智能体等创新特性。',
      buttonFooterText: '拉起云净听导入配置文件',
      useButtonFooter: true,
      buttonFooterOnClick: () => {
        (this.getUIContext().getHostContext()! as common.UIAbilityContext).openLink(this.sharePlainAPILink())
      }
    })
  }
}