import { ImageTitleWelcomeTemplate, SymbolTitle } from "./CommonTemplate";

@ComponentV2
export struct ImportMusic {
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
      title: '导入音乐文件',
      subtitle: 'HiNavidromy 本身不提供音乐资源，但可以帮您方便地管理与收藏您的音乐库，点击下方按钮开始导入您的音乐文件。',
      buttonFooterText: '导入音乐',
      useButtonFooter: true,
      buttonFooterOnClick: () => {
        this.pageStack.pushPathByName('SharedFolder',[])
      }
    })
  }
}