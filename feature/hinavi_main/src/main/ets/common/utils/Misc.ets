import { WantUtil } from "@pura/harmony-utils"

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
          WantUtil.toWebBrowser('https://gitee.com/handwer/HiNavidromy')
        },
        value: 'Gitee'
      },
      message: "主仓库位于 GitHub，同时提供 Gitee 镜像仓库供国内访问，可任选一个访问"
    })
  }
}