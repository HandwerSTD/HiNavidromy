import { ImageTitleWelcomeTemplate, SymbolTitle } from "./CommonTemplate";

@ComponentV2
export struct NavWebPage {
  @Consumer('firstOpenStack') pageStack: NavPathStack = new NavPathStack()

  @Builder icon() {
    SymbolTitle({
      icon: $r('sys.symbol.music_note_list'),
      gradientColor: [0x02c1f8, 0x025fea]
    })
  }

  @Builder footer() {
    Column({space: 12}) {
      Image($r('app.media.scan_library'))
        .borderRadius(12)
        .width('100%').constraintSize({maxWidth: 300})
      Button('打开').width('100%')
        .onClick(() => {
          this.pageStack.pushPathByName('NavidromeWeb', [])
        })
    }
  }

  build() {
    ImageTitleWelcomeTemplate({
      customImage: this.icon,
      title: 'Navidrome 网页管理',
      subtitle: '您可以点击打开 Navidrome 网页，使用功能丰富的网页端进行音乐库管理。\n\n在成功登陆后，您需要在右上角点击按钮，进行音乐库扫描。在音乐库扫描之后，您添加的新音乐才会显示。',
      // buttonFooterText: '打开',
      // useButtonFooter: true,
      // buttonFooterOnClick: () => {
      //   this.pageStack.pushPathByName('NavidromeWeb', [])
      // }
      footer: () => { this.footer() }
    })
  }
}