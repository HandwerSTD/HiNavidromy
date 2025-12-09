import { WindowAvoidanceData } from "../utils/WindowUtil"
import { OuterWantDataModel } from "./OuterWantDataModel"
import { PrefDataModel } from "./PreferenceDataModel"
import { common } from "@kit.AbilityKit"
import { ServerLoadStatus } from "../utils/NavidromeServerUtils"


class MyPageStack extends NavPathStack {
  push(name: string, params: Object) {
    if (this.getAllPathName().length == 1) {
      this.replacePathByName(name, params, true);
      return;
    }
    this.pushPathByName(name, params, true);
  }
}

@ObservedV2
class GlobalStore {

  private static _instance?: GlobalStore
  todayBackupFinished: boolean = false

  static get instance() {
    if (!GlobalStore._instance) {
      GlobalStore._instance = new GlobalStore()
    }
    return GlobalStore._instance
  }

  pageStack: MyPageStack = new MyPageStack()

  @Trace gotUpdateDeviceId?: string

  @Trace isPCMode: boolean = false
  @Trace wd: WindowAvoidanceData = new WindowAvoidanceData(0,0)

  @Trace wbp: string = 'sm'
  @Trace hbp: string = 'lg'

  @Trace appVersion: string = ''

  @Trace isInForeground: boolean = true

  @Trace isDarkMode: boolean = false

  @Trace pref: PrefDataModel = new PrefDataModel()

  @Trace outerWant: OuterWantDataModel = new OuterWantDataModel('', {})

  @Trace initialized: boolean = false

  @Trace isFirstOpenFinished: boolean = false

  @Trace serverStatus: ServerLoadStatus = ServerLoadStatus.LOADING
  @Trace showTerminal: boolean = false
  @Trace developerMode: boolean = false

  @Trace fakeLoadingProgress: number = 0
  @Trace simulateBg: boolean = false

  contextFaker?: common.UIAbilityContext

  get isServerOnline() {
    return this.serverStatus === ServerLoadStatus.SUCCESS
  }
}

export default GlobalStore.instance as GlobalStore