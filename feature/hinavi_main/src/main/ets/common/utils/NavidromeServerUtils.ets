import GlobalStore from "../statemgmt/GlobalStore";
import { RetryUtil } from "./CommonUtil";
import { http } from "@kit.NetworkKit";
import { buffer } from "@kit.ArkTS";
import { VMSwitcher } from "../../lib/VMSwitcher";
import QemuAgentManager from "../../lib/Agent/AgentManager";
import { GuestAgentHelper } from "../../lib/Agent/GuestAgent";

export enum ServerLoadStatus {
  LOADING,
  SUCCESS,
  TIMEOUT
}

export class NavidromeServerUtils {
  static checkConnectionOnStart() {
    const timeout = VMSwitcher.isTCI ? 40 : 30
    // 60s 登录时间
    return RetryUtil.retryIf<void>(timeout, async () => {
      // http
      const cli = http.createHttp()
      return cli.request('localhost:4533')
        .then((val) => {
          if (val.responseCode === 200) {
            GlobalStore.serverStatus = ServerLoadStatus.SUCCESS
            QemuAgentManager.acquire()
          }
        })
    }, () => {
      return !GlobalStore.isServerOnline
    }, 2000)
  }
  static async backupLibraryDB(): Promise<string> {
    // 生成时间戳格式：yyyyMMdd_HHmmss
    const now = new Date()
    const timestamp = `${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, '0')}${String(now.getDate()).padStart(2, '0')}_${String(now.getHours()).padStart(2, '0')}${String(now.getMinutes()).padStart(2, '0')}${String(now.getSeconds()).padStart(2, '0')}`
    const backupFileName = `backup_${timestamp}.db`
    const backupPath = `/mnt/share/${backupFileName}`

    // 执行备份命令
    const cmd = `sqlite3 /var/lib/navidrome/navidrome.db ".backup ${backupPath}"`
    const result = await GuestAgentHelper.execWithExitCode('/root', cmd)

    if (!result.success) {
      throw new Error(`备份失败，返回码: ${result.exitCode}, 输出: ${result.output}`)
    }

    return backupPath
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
      VMSwitcher.sendInput(buffer)
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