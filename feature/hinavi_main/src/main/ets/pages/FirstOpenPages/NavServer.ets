import { PermissionUtil } from "@pura/harmony-utils";
import { BackgroundTaskManager } from "../../common/utils/BackgroundTaskManager";
import appOption from "../../model/appOption";
import { ImageTitleWelcomeTemplate, SymbolTitle } from "./CommonTemplate";
import { common } from "@kit.AbilityKit";
import { promptAction } from "@kit.ArkUI";
import { geoLocationManager } from "@kit.LocationKit";
import preference from '@ohos.data.preferences';
import GlobalStore from "../../common/statemgmt/GlobalStore";
import { ServiceInitUtils } from "../../../../../Index";

@ComponentV2
export struct NavServer {
  @Builder icon() {
    SymbolTitle({
      icon: $r('sys.symbol.cloud_and_stars'),
      gradientColor: [0x02c1f8, 0x025fea]
    })
  }

  build() {
    ImageTitleWelcomeTemplate({
      customImage: this.icon,
      title: '随身的 Navidrome 服务器',
      subtitle: '你最熟悉的 Navidrome 私有音乐源，现在也能装进口袋，伴你一路随行。\n\n接下来的新手引导，将会帮助你快速上手。\n\n为了保持服务器始终在后台运行，我们需要申请您的模糊位置信息权限。该权限仅用于模拟后台驻留，我们不会收集任何您的隐私信息，所有获取的模糊位置信息将被立即丢弃且不会被发送出应用，最大程度保证您的隐私安全。',
      useButtonFooter: true,
      buttonFooterText: '后台授权',
      buttonFooterOnClick: () => {
        ServiceInitUtils.startSimulateBg(this.getUIContext().getHostContext() as common.UIAbilityContext, true)
      }
    })
  }
}