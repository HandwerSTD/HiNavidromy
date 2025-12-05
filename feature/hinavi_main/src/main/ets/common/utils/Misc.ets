import { WantUtil } from "@pura/harmony-utils"
import { common } from "@kit.AbilityKit"
import ServiceInitUtils from "../ServiceInitUtils"
import GlobalStore from "../statemgmt/GlobalStore"

export class MiscUtils {
  static async openSourceRepo(uiContext: UIContext) {
    uiContext.showAlertDialog({
      title: '开源仓库',
      primaryButton: {
        action: () => {
          WantUtil.toWebBrowser('https://github.com/HandwerSTD/hinavidromy')
        },
        value: 'GitHub'
      },
      secondaryButton: {
        action: () => {
          WantUtil.toWebBrowser('https://gitcode.com/handwer/HiNavidromy')
        },
        value: 'GitCode'
      },
      message: "主仓库位于 GitHub，同时提供 GitCode 镜像仓库供国内访问，可任选一个访问"
    })
  }
  static async requestForceBg(uiContext: UIContext, successCallback?: () => void) {
    if (GlobalStore.simulateBg && successCallback) {
      successCallback();
      return;
    }
    uiContext.showAlertDialog({
      title: '强制后台',
      message: '为了保持服务器始终在后台运行，我们需要申请您的模糊位置信息权限。该权限仅用于模拟后台驻留，我们不会收集任何您的隐私信息，所有获取的模糊位置信息将被立即丢弃且不会被发送出应用，最大程度保证您的隐私安全。\n您可以选择不授权，不授权不会影响 HiNavidromy 的正常运行，但无法与《云净听》等外部应用进行联动。',
      primaryButton: {
        value: '授权',
        action: () => {
          ServiceInitUtils.startSimulateBg(uiContext.getHostContext()! as common.UIAbilityContext, true)
          .then((res) => {
            if (res && successCallback) {
              successCallback();
            } 
          })
        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {}
      }
    })
  }
}