import { HiNaviEntry as Main} from 'hinavi_main'

@Entry
struct HiNaviEntry {
  build() {
    Column() {
      Main()
    }.width('100%').height('100%')
  }
}