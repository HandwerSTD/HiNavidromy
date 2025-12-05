import { VMSwitcher } from "../../lib/VMSwitcher"
import { MiscUtils } from "../../common/utils/Misc"
import { ImageTitleWelcomeTemplate, SymbolTitle } from "./CommonTemplate"

@ComponentV2
export struct CompatibilityMode {

  @Builder Title() {

    SymbolTitle({
      icon: $r('sys.symbol.camera_mode_slow'),
      gradientColor: ['#FF9500', '#FF5E3A']
    })
  }

  build() {
    Column() {
      if (VMSwitcher.isTCI) {
        ImageTitleWelcomeTemplate({
          title: '兼容模式运行',
          subtitle: 'HiNavidromy 正在以兼容模式运行，此模式下内部代码会经过一层转译，因此运行速度可能显著变慢。\n\n' +
            '进入兼容模式的原因可能有：\n' +
            '1. 由于权限限制，在 AppGallery 应用市场安装时，仅支持兼容模式运行\n' +
            '2. 您的设备开启了「坚盾守护模式」，此模式下应用运行权限受限，仅能使用兼容模式运行\n\n' +
            '您可以自行构建开源版本，并使用开发者模式安装，可不经过转译高速运行，同时也可提升性能与耗电表现。',
          useButtonFooter: true,
          buttonFooterText: '查看开源仓库',
          buttonFooterOnClick: () => {
            MiscUtils.openSourceRepo(this.getUIContext())
          },
          customImage: this.Title
        })
      }
    }.width('100%').height('100%')
  }
}
