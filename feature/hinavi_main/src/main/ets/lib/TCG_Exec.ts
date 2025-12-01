import napi, { appOptions } from 'libhinavi_main.so'

export class TCG_VM {
  static startVM(appOptions: appOptions) {
    napi.startVM(appOptions)
  }
  static onData(onData: (ArrayBuffer) => void) {
    napi.onData(onData)
  }
  static sendInput(content: ArrayBuffer) {
    napi.sendInput(content)
  }
  static checkPortUsed(port: number) {
    return napi.checkPortUsed(port)
  }
}