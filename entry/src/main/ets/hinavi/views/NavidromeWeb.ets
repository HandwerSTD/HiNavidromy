import { webview } from "@kit.ArkWeb"
import { SymbolGlyphModifier } from "@kit.ArkUI"
4
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