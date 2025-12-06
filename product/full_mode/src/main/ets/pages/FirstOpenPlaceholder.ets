import { ImageTitleWelcomeTemplate } from 'hinavi_main'


@Entry
@ComponentV2
struct FinalWelcome {

  build() {
    Column() {
      ImageTitleWelcomeTemplate({
        title: 'HiNavidromy',
        subtitle: '装进口袋里的 Navidrome 服务器',
        image: $r('app.media.startIcon'),
        useButtonFooter: true,
        buttonFooterText: '开始',
        buttonFooterOnClick: () => {
          this.getUIContext().getRouter().replaceUrl({
            url: 'pages/HiNaviEntry'
          })
        }
      })
    }.width('100%').height('100%')
  }
}