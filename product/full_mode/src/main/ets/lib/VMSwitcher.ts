import { TCI_VM } from "tci"
import { TCG_VM } from "./TCG_Exec"
import napi from 'libentry.so'

type appOptions = {
  argsLines: string
  unixSocket: string
}

export class VMSwitcher {
  static isTCI: boolean = false
  static isSecurityMode() {
    return napi.isSecurityMode()
  }
  static startVM(appOptions: appOptions) {
    if (VMSwitcher.isTCI) TCI_VM.startVM(appOptions)
    else TCG_VM.startVM(appOptions)
  }
  static onData(onData: (ArrayBuffer) => void) {
    if (VMSwitcher.isTCI) TCI_VM.onData(onData)
    else TCG_VM.onData(onData)
  }
  static sendInput(content: ArrayBuffer) {
    if (VMSwitcher.isTCI) TCI_VM.sendInput(content)
    TCG_VM.sendInput(content)
  }
  static checkPortUsed(port: number):boolean {
    if (VMSwitcher.isTCI) return TCI_VM.checkPortUsed(port)
    return TCG_VM.checkPortUsed(port)
  }
}