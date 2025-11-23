import { WindowAvoidanceData } from "../utils/WindowUtil"
import { OuterWantDataModel } from "./OuterWantDataModel"
import { PrefDataModel } from "./PreferenceDataModel"
import { common } from "@kit.AbilityKit"
import { ServerLoadStatus } from "../utils/NavidromeServerUtils"


@ObservedV2
class GlobalStore {

  private static _instance?: GlobalStore

  static get instance() {
    if (!GlobalStore._instance) {
      GlobalStore._instance = new GlobalStore()
    }
    return GlobalStore._instance
  }

  pageStack: NavPathStack = new NavPathStack()

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

  @Trace isAgentSupported: boolean = true

  @Trace isFirstOpenFinished: boolean = true

  @Trace serverStatus: ServerLoadStatus = ServerLoadStatus.LOADING

  contextFaker?: common.UIAbilityContext

  get isServerOnline() {
    return this.serverStatus === ServerLoadStatus.SUCCESS
  }
}

export default GlobalStore.instance as GlobalStore