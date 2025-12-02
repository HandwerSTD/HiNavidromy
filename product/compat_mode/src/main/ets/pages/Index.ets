import { HiNaviEntry } from 'hinavi_main'

@Entry
@Component
struct Index {

  build() {
    Column() {
      HiNaviEntry()
    }.width('100%').height('100%')
  }
}