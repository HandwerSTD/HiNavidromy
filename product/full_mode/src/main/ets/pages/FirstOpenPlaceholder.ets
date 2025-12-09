import { ImageTitleWelcomeTemplate, SystemImageUtils } from 'hinavi_main'
import { privacyManager } from '@kit.AppGalleryKit'
import { application, common } from '@kit.AbilityKit'
import { WantUtil } from '@pura/harmony-utils'


@Entry
@ComponentV2
struct FinalWelcome {

  @Local useCustomPrivacy: boolean = false

  onGo() {
    SystemImageUtils.updateToCurrentVersion(application.getApplicationContext())
    this.getUIContext().getRouter().replaceUrl({
      url: 'pages/HiNaviEntry'
    })
  }

  build() {
    Column() {
      ImageTitleWelcomeTemplate({
        title: 'HiNavidromy',
        subtitle: '装进口袋里的 Navidrome 服务器',
        image: $r('app.media.startIcon'),
        useButtonFooter: true,
        buttonFooterText: '开始',
        buttonFooterOnClick: () => {
          if (this.useCustomPrivacy) {
            this.getUIContext().showAlertDialog({
              title: '隐私协议',
              message: '请阅读并同意《关于HiNavidromy与隐私的声明》',
              buttonDirection: DialogButtonDirection.VERTICAL,
              buttons: [{
                value: '跳转到隐私协议',
                action: () => {
                  WantUtil.toWebBrowser('https://agreement-drcn.hispace.dbankcloud.cn/index.html?lang=zh&agreementId=1832184674894508416')
                }
              }, {
                value: '同意',
                action: () => {
                  this.onGo()
                }
              }, {
                value: '不同意',
                action: () => {

                }
              }]
            })
          } else {
            this.onGo()
          }
        }
      })
    }.width('100%').height('100%')
    .onAppear(() => {
      privacyManager.requestAppPrivacyConsent(this.getUIContext().getHostContext()! as common.UIAbilityContext)
        .catch(() => {
          this.useCustomPrivacy = true
        })
    })
  }
}