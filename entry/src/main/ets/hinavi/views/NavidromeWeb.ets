import { webview } from "@kit.ArkWeb"
import { promptAction, SymbolGlyphModifier } from "@kit.ArkUI"
import { pasteboard } from "@kit.BasicServicesKit"
import { MyLogUtil } from "../../common/utils/Logger"


@ComponentV2
export struct NavidromeWeb {
  controller = new webview.WebviewController()
  build() {
    NavDestination() {
      Web({
        src: 'http://127.0.0.1:4533',
        controller: this.controller,
      })
        .fileAccess(true).javaScriptAccess(true).domStorageAccess(true).imageAccess(true).mixedMode(MixedMode.All)
        .onAppear(() => {
          this.controller.loadUrl('http://127.0.0.1:4533/')
        })
        .width('100%').height('100%')
        .expandSafeArea()
        .onLoadIntercept((event) => {
          MyLogUtil.debug(`Navidrome web `, `viewing ${event.data.getRequestUrl()}`)
          if (event.data.getRequestUrl().endsWith('/app/')) {
            this.getUIContext().showAlertDialog({
              title: '管理员账户',
              message: '默认的管理员账户密码分别为：\nCloudPurePlay\nlocalhostPurePlay\n您也可以在《云净听》音乐源配置界面查看该账号密码。',
              primaryButton: {
                value: '复制账号密码',
                action: () => {
                  pasteboard.getSystemPasteboard().setDataSync(pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, 'CloudPurePlay localhostPurePlay'))
                }
              },
              secondaryButton: {
                value: $r('sys.string.general_confirm'),
                action: () => {

                }
              }
            })
          }
          return false
        })
    }
    .title('Navidrome')
    .menus([{
      symbolIcon: new SymbolGlyphModifier($r('sys.symbol.chevron_left_circle')),
      value: '后退',
      action: () => {
        this.controller.backward()
      },
    },{
      symbolIcon: new SymbolGlyphModifier($r('sys.symbol.chevron_right_circle')),
      value: '前进',
      action: () => {
        this.controller.forward()
      },
    }])
  }
}