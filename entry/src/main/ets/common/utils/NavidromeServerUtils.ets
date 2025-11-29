import GlobalStore from "../statemgmt/GlobalStore";
import { RetryUtil } from "./CommonUtil";
import { http } from "@kit.NetworkKit";
import napi from 'libentry.so'
import { buffer } from "@kit.ArkTS";

export enum ServerLoadStatus {
  LOADING,
  SUCCESS,
  TIMEOUT
}

export class NavidromeServerUtils {
  static checkConnectionOnStart() {
    // 60s 登录时间
    return RetryUtil.retryIf<void>(30, async () => {
      // http
      const cli = http.createHttp()
      return cli.request('localhost:4533')
        .then((val) => {
          if (val.responseCode === 200) {
            GlobalStore.serverStatus = ServerLoadStatus.SUCCESS
          }
        })
    }, () => {
      return !GlobalStore.isServerOnline
    }, 2000)
  }
}
function stringToArrayBuffer(str: string, encoding: buffer.BufferEncoding = 'utf-8'): ArrayBuffer {
  const buf = buffer.from(str, encoding);
  return buf.buffer;
}

export enum ControlCharacters {
  CTRL_C = '\x03',      // 中断进程 (SIGINT)
  CTRL_D = '\x04',      // EOF (End of File)
  CTRL_Z = '\x1a',      // 暂停进程 (SIGTSTP)
  CTRL_L = '\x0c',      // 清屏
  BACKSPACE = '\x08',   // 退格
  ENTER = '\n',         // 换行
  ESC = '\x1b',         // ESC 键
  TAB = '\t',           // 制表符
}
export class VMUtils {
  static send(cmd: string | string[]) {
    const sendInput = (data: string) => {
      let buffer = stringToArrayBuffer(data, 'utf-8');
      napi.sendInput(buffer)
    }
    if (typeof cmd === 'string') {
      sendInput(cmd)
    } else {
      cmd.forEach((v) => { sendInput(v) })
    }
  }
  static breakAndExecuteCommand(cmd: string) {
    cmd += '\n'
    VMUtils.send([ControlCharacters.CTRL_C, cmd])
  }
  static suspendAndExecuteCommand(cmd: string, showTerminal: boolean = true) {
    cmd += '\n'
    VMUtils.send([ControlCharacters.CTRL_Z, ControlCharacters.CTRL_C, cmd, 'fg\n'])
    if (showTerminal) {
      GlobalStore.showTerminal = true
    }
  }
}