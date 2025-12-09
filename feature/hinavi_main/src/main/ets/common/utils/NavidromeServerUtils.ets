import GlobalStore from "../statemgmt/GlobalStore";
import { RetryUtil } from "./CommonUtil";
import { http } from "@kit.NetworkKit";
import { buffer } from "@kit.ArkTS";
import { VMSwitcher } from "../../lib/VMSwitcher";
import QemuAgentManager from "../../lib/Agent/AgentManager";
import { GuestAgentHelper } from "../../lib/Agent/GuestAgent";
import { promptAction } from "@kit.ArkUI";
import { GlobalContext } from "@pura/harmony-utils";
import { DialogHelper } from "@pura/harmony-dialog";

export enum ServerLoadStatus {
  LOADING,
  SUCCESS,
  TIMEOUT
}

let isAlreadyStart: boolean = false

export class NavidromeServerUtils {
  static async checkConnectionOnStart() {
    if (isAlreadyStart) return
    isAlreadyStart = true
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
              .then(() => {
                NavidromeServerUtils.afterAgentConnection()
              })
          }
        })
    }, () => {
      return !GlobalStore.isServerOnline
    }, 2000)
  }
  private static async afterAgentConnection() {
    if (GlobalContext.getContext().getObject('upgradeMode')) {
      // 更新，恢复数据库
      const id = DialogHelper.showLoadingDialog()
      await NavidromeServerUtils.recoverBackup('/mnt/share/hinavi_recent_backup.db')
        .then(() => {
          promptAction.showToast({
            message: '升级数据恢复完成'
          })
        })
        .catch(() => {
          promptAction.showToast({
            message: '数据库恢复失败'
          })
        })
        .finally(() => {
          DialogHelper.closeDialog(id)
        })
    } else if (GlobalStore.isFirstOpenFinished) {
      // 非更新，备份一遍数据库
      await NavidromeServerUtils.autoBackupLibraryDB()
        .then(() => {
          promptAction.showToast({
            message: '已自动备份数据库'
          })
        })
        .catch((err: BusinessError<void>) => {
          promptAction.showToast({
            message: '自动备份数据库失败: ' + err.message
          })
        })
    }
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
  static async autoBackupLibraryDB(): Promise<string> {
    // 生成时间戳格式：yyyyMMdd_HHmmss
    const now = new Date()
    const backupFileName = `hinavi_recent_backup.db`
    const backupPath = `/mnt/share/${backupFileName}`

    // 执行备份命令
    const cmd = `rm -f ${backupPath} && sqlite3 /var/lib/navidrome/navidrome.db ".backup ${backupPath}"`
    const result = await GuestAgentHelper.execWithExitCode('/root', cmd)

    if (!result.success) {
      throw new Error(`备份失败，返回码: ${result.exitCode}, 输出: ${result.output}`)
    }
    GlobalStore.todayBackupFinished = true

    return backupPath
  }
  static async recoverBackup(dbPath: string): Promise<void> {
    // 1. 先停止 Navidrome 服务
    const stopResult = await GuestAgentHelper.execWithExitCode('/root', 'rc-service navidrome stop')
    if (!stopResult.success) {
      throw new Error(`停止服务失败，返回码: ${stopResult.exitCode}, 输出: ${stopResult.output}`)
    }

    // 2. 使用 sqlite3 备份当前数据库（以防万一）
    const now = new Date()
    const timestamp = `${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, '0')}${String(now.getDate()).padStart(2, '0')}_${String(now.getHours()).padStart(2, '0')}${String(now.getMinutes()).padStart(2, '0')}${String(now.getSeconds()).padStart(2, '0')}`
    const currentBackup = `/mnt/share/navidrome_before_restore_${timestamp}.db`
    await GuestAgentHelper.execWithExitCode('/root', `sqlite3 /var/lib/navidrome/navidrome.db ".backup ${currentBackup}"`)
    // 备份失败不阻止恢复，只记录警告

    // 3. 使用 sqlite3 从备份文件恢复数据库
    const restoreResult = await GuestAgentHelper.execWithExitCode('/root', `cp ${dbPath} /tmp/backup_${timestamp}.db && sqlite3 /var/lib/navidrome/navidrome.db ".restore /tmp/backup_${timestamp}.db"`)
    if (!restoreResult.success) {
      // 恢复失败，尝试重启服务
      await GuestAgentHelper.execWithExitCode('/root', 'rc-service navidrome start')
      throw new Error(`恢复数据库失败，返回码: ${restoreResult.exitCode}, 输出: ${restoreResult.output}`)
    }

    // 4. 重启 Navidrome 服务
    const startResult = await GuestAgentHelper.execWithExitCode('/root', 'rc-service navidrome start')
    if (!startResult.success) {
      throw new Error(`启动服务失败，返回码: ${startResult.exitCode}, 输出: ${startResult.output}`)
    }
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