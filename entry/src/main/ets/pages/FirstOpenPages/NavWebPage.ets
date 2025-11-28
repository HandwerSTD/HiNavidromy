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

  build() {
    ImageTitleWelcomeTemplate({
      customImage: this.icon,
      title: 'Navidrome 网页管理',
      subtitle: '您可以点击打开 Navidrome 网页，使用功能丰富的网页端进行音乐库管理。\n\n在成功登陆后，您可以在右上角点击扫描音乐库，或修改语言等个性化设置。',
      buttonFooterText: '打开',
      useButtonFooter: true,
      buttonFooterOnClick: () => {
        this.pageStack.pushPathByName('NavidromeWeb', [])
      }
    })
  }
}