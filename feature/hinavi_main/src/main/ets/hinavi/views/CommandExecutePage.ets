import { GuestAgentHelper, ExecResult } from '../../lib/Agent/GuestAgent'
import { pasteboard } from '@kit.BasicServicesKit'
import { promptAction } from '@kit.ArkUI'
import { systemShare } from '@kit.ShareKit'
import { uniformTypeDescriptor as utd } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import GlobalStore from '../../common/statemgmt/GlobalStore'

/**
 * 命令执行参数
 */
export interface CommandExecuteParams {
  /** 要执行的命令 */
  command: string
  /** 页面标题 */
  title: string
  /** 工作目录，默认 /root */
  cwd?: string
}

/**
 * 命令历史记录项（包含完整输出）
 */
export interface CommandHistoryItem {
  /** 唯一ID */
  id: string
  /** 命令 */
  command: string
  /** 标题 */
  title: string
  /** 执行时间 */
  executedAt: number
  /** 是否成功 */
  success: boolean
  /** 返回码 */
  exitCode: number
  /** 执行耗时(ms) */
  duration: number
  /** 命令输出 */
  output: string
  /** 错误信息 */
  errorMessage?: string
}

/**
 * 命令历史管理器
 */
class CommandHistoryManager {
  private static instance: CommandHistoryManager
  private history: CommandHistoryItem[] = []
  private readonly MAX_HISTORY = 50

  static getInstance(): CommandHistoryManager {
    if (!CommandHistoryManager.instance) {
      CommandHistoryManager.instance = new CommandHistoryManager()
    }
    return CommandHistoryManager.instance
  }

  addRecord(item: CommandHistoryItem) {
    // 添加到历史记录开头
    this.history.unshift(item)
    // 限制历史记录数量
    if (this.history.length > this.MAX_HISTORY) {
      this.history = this.history.slice(0, this.MAX_HISTORY)
    }
  }

  getHistory(): CommandHistoryItem[] {
    return [...this.history]
  }

  getById(id: string): CommandHistoryItem | undefined {
    return this.history.find(item => item.id === id)
  }

  clearHistory() {
    this.history = []
  }
}

export const commandHistory = CommandHistoryManager.getInstance()

/**
 * 生成唯一ID
 */
function generateId(): string {
  return Date.now().toString(36) + Math.random().toString(36).substring(2, 9)
}

/**
 * 判断命令输出是否可以被解析为结构化数据
 */
export function canAnalyzeOutput(command: string): boolean {
  const analyzableCommands = [
    'ps aux', 'ps -ef', 'ps -aux',
    'df -h', 'df -H', 'df',
    'free -h', 'free -m', 'free',
    'top -b -n 1', 'top -bn1',
    'netstat -tuln', 'netstat -tulnp',
    'ss -tuln', 'ss -tulnp',
    'lsblk'
  ]
  return analyzableCommands.some(cmd => command.includes(cmd.split(' ')[0]))
}

/**
 * 获取命令的基础名称（用于获取帮助）
 */
export function getBaseCommand(command: string): string {
  // 移除 sudo 前缀
  let cmd = command.replace(/^sudo\s+/, '')
  // 获取第一个命令（管道前的部分）
  cmd = cmd.split('|')[0].trim()
  // 获取命令名（第一个单词）
  return cmd.split(/\s+/)[0]
}

@ComponentV2
export struct CommandExecutePage {
  pathStack: NavPathStack = new NavPathStack()
  @Local params: CommandExecuteParams | null = null

  @Local isExecuting: boolean = false
  @Local output: string = ''
  @Local exitCode: number = -1
  @Local hasExecuted: boolean = false
  @Local errorMessage: string = ''

  // 执行时间统计
  @Local startTime: number = 0
  @Local endTime: number = 0
  @Local duration: number = 0

  // 历史记录显示
  @Local showHistory: boolean = false

  // 当前记录ID
  @Local currentRecordId: string = ''

  aboutToAppear(): void {
    // 从路由参数获取命令信息
    const rawParams = this.pathStack.getParamByIndex(this.pathStack.size() - 1) as CommandExecuteParams
    if (rawParams) {
      this.params = rawParams
      // 自动执行命令
      this.executeCommand()
    }
  }

  async executeCommand() {
    if (!this.params || this.isExecuting) {
      return
    }

    this.isExecuting = true
    this.hasExecuted = false
    this.output = ''
    this.exitCode = -1
    this.errorMessage = ''
    this.startTime = Date.now()
    this.endTime = 0
    this.duration = 0
    this.currentRecordId = generateId()

    try {
      const cwd = this.params.cwd || '/root'
      const result: ExecResult = await GuestAgentHelper.execWithExitCode(cwd, this.params.command)

      this.endTime = Date.now()
      this.duration = this.endTime - this.startTime

      this.output = result.output
      this.exitCode = result.exitCode
      this.hasExecuted = true

      if (!result.success && result.exitCode === -1) {
        this.errorMessage = '命令执行失败或超时'
      }

      // 添加到历史记录（包含完整输出）
      commandHistory.addRecord({
        id: this.currentRecordId,
        command: this.params.command,
        title: this.params.title,
        executedAt: this.startTime,
        success: result.success,
        exitCode: result.exitCode,
        duration: this.duration,
        output: result.output,
        errorMessage: this.errorMessage || undefined
      })
    } catch (e) {
      this.endTime = Date.now()
      this.duration = this.endTime - this.startTime
      this.errorMessage = `执行异常: ${(e as Error).message}`
      this.hasExecuted = true

      // 记录失败的历史
      commandHistory.addRecord({
        id: this.currentRecordId,
        command: this.params!.command,
        title: this.params!.title,
        executedAt: this.startTime,
        success: false,
        exitCode: -1,
        duration: this.duration,
        output: '',
        errorMessage: this.errorMessage
      })
    } finally {
      this.isExecuting = false
    }
  }

  /**
   * 复制输出到剪贴板
   */
  copyToClipboard() {
    const pasteboardData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.output)
    const systemPasteboard = pasteboard.getSystemPasteboard()
    systemPasteboard.setData(pasteboardData)
    promptAction.showToast({ message: '已复制到剪贴板' })
  }

  /**
   * 分享输出内容
   */
  async shareOutput(context: common.UIAbilityContext) {
    const shareContent = `命令: ${this.params?.command}\n` +
      `执行时间: ${this.formatTime(this.startTime)}\n` +
      `耗时: ${this.formatDuration(this.duration)}\n` +
      `返回码: ${this.exitCode}\n` +
      `---输出---\n${this.output}`

    const shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.PLAIN_TEXT,
      content: shareContent,
      title: `命令执行结果: ${this.params?.title}`
    })

    const shareController = new systemShare.ShareController(shareData)
    shareController.show(context, {
      selectionMode: systemShare.SelectionMode.SINGLE
    })
  }

  /**
   * 跳转到输出分析页面
   */
  goToAnalysis() {
    if (this.output && this.params) {
      GlobalStore.pageStack.push('OutputAnalysis', {
        command: this.params.command,
        output: this.output,
        title: this.params.title
      } as CommandHistoryItem)
    }
  }

  /**
   * 跳转到命令帮助页面
   */
  goToHelp() {
    if (this.params) {
      const baseCmd = getBaseCommand(this.params.command)
      GlobalStore.pageStack.pushPathByName('CommandHelp', {
        command: baseCmd
      } as CommandExecuteParams, true)
    }
  }

  /**
   * 跳转到历史详情页面
   */
  goToHistoryDetail(item: CommandHistoryItem) {
    GlobalStore.pageStack.pushPathByName('HistoryDetail', {
      "historyId": item.id
    } as Record<string, Object>, true)
    this.showHistory = false
  }

  /**
   * 格式化时间戳
   */
  formatTime(timestamp: number): string {
    if (!timestamp) return '--'
    const date = new Date(timestamp)
    return `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}:${date.getSeconds().toString().padStart(2, '0')}`
  }

  /**
   * 格式化耗时
   */
  formatDuration(ms: number): string {
    if (ms < 1000) {
      return `${ms} ms`
    } else if (ms < 60000) {
      return `${(ms / 1000).toFixed(2)} s`
    } else {
      const minutes = Math.floor(ms / 60000)
      const seconds = ((ms % 60000) / 1000).toFixed(1)
      return `${minutes} 分 ${seconds} 秒`
    }
  }

  /**
   * 格式化日期时间
   */
  formatDateTime(timestamp: number): string {
    const date = new Date(timestamp)
    const month = (date.getMonth() + 1).toString().padStart(2, '0')
    const day = date.getDate().toString().padStart(2, '0')
    const hours = date.getHours().toString().padStart(2, '0')
    const minutes = date.getMinutes().toString().padStart(2, '0')
    return `${month}-${day} ${hours}:${minutes}`
  }

  @Builder
  StatusBadge() {
    if (this.isExecuting) {
      Row({ space: 8 }) {
        LoadingProgress().width(16).height(16)
        Text('执行中...').fontSize(14).fontColor($r('sys.color.font_secondary'))
      }
    } else if (this.hasExecuted) {
      if (this.exitCode === 0) {
        Row({ space: 4 }) {
          SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
            .fontColor([$r('sys.color.multi_color_09')])
            .fontSize(16)
          Text('执行成功').fontSize(14).fontColor($r('sys.color.multi_color_09'))
        }
      } else {
        Row({ space: 4 }) {
          SymbolGlyph($r('sys.symbol.xmark_circle_fill'))
            .fontColor([$r('sys.color.warning')])
            .fontSize(16)
          Text(`返回码: ${this.exitCode}`).fontSize(14).fontColor($r('sys.color.warning'))
        }
      }
    }
  }

  @Builder
  TimeStats() {
    if (this.startTime > 0) {
      Column({ space: 8 }) {
        Row() {
          Text('执行统计').fontSize(14).fontColor($r('sys.color.font_secondary'))
        }.width('100%')

        Row({ space: 16 }) {
          Column({ space: 4 }) {
            Text('开始时间').fontSize(12).fontColor($r('sys.color.font_tertiary'))
            Text(this.formatTime(this.startTime)).fontSize(13).fontColor($r('sys.color.font'))
          }.alignItems(HorizontalAlign.Start)

          Column({ space: 4 }) {
            Text('结束时间').fontSize(12).fontColor($r('sys.color.font_tertiary'))
            Text(this.endTime > 0 ? this.formatTime(this.endTime) : '--').fontSize(13).fontColor($r('sys.color.font'))
          }.alignItems(HorizontalAlign.Start)

          Column({ space: 4 }) {
            Text('执行耗时').fontSize(12).fontColor($r('sys.color.font_tertiary'))
            Text(this.duration > 0 ? this.formatDuration(this.duration) : '--')
              .fontSize(13)
              .fontColor(this.duration > 5000 ? $r('sys.color.warning') : $r('sys.color.font'))
          }.alignItems(HorizontalAlign.Start)
        }.width('100%')
      }
      .width('100%')
      .padding(16)
      .backgroundColor($r('sys.color.comp_background_primary'))
      .borderRadius(16)
    }
  }

  @Builder
  HistoryList() {
    Column({ space: 12 }) {
      Row() {
        Text('执行历史').fontSize(16).fontWeight(FontWeight.Medium)
        Blank()
        if (commandHistory.getHistory().length > 0) {
          Text('清空')
            .fontSize(14)
            .fontColor($r('sys.color.warning'))
            .onClick(() => {
              commandHistory.clearHistory()
              this.showHistory = false
            })
        }
      }.width('100%')

      if (commandHistory.getHistory().length === 0) {
        Text('暂无历史记录')
          .fontSize(14)
          .fontColor($r('sys.color.font_tertiary'))
          .padding(32)
      } else {
        List({ space: 8 }) {
          ForEach(commandHistory.getHistory(), (item: CommandHistoryItem) => {
            ListItem() {
              Row({ space: 12 }) {
                // 状态图标
                SymbolGlyph(item.success ? $r('sys.symbol.checkmark_circle') : $r('sys.symbol.xmark_circle'))
                  .fontColor([item.success ? $r('sys.color.multi_color_09') : $r('sys.color.warning')])
                  .fontSize(20)

                Column({ space: 4 }) {
                  Text(item.title)
                    .fontSize(14)
                    .fontColor($r('sys.color.font'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Text(item.command)
                    .fontSize(12)
                    .fontFamily('monospace')
                    .fontColor($r('sys.color.font_secondary'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Row({ space: 8 }) {
                    Text(this.formatDateTime(item.executedAt))
                      .fontSize(11)
                      .fontColor($r('sys.color.font_tertiary'))
                    Text(`耗时 ${this.formatDuration(item.duration)}`)
                      .fontSize(11)
                      .fontColor($r('sys.color.font_tertiary'))
                  }
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                // 查看详情
                SymbolGlyph($r('sys.symbol.chevron_right'))
                  .fontColor([$r('sys.color.font_tertiary')])
                  .fontSize(16)
              }
              .width('100%')
              .padding(12)
              .backgroundColor($r('sys.color.comp_background_tertiary'))
              .borderRadius(8)
              .onClick(() => {
                this.goToHistoryDetail(item)
              })
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .padding(16)
  }

  @Builder
  QuickActions() {
    if (this.hasExecuted && !this.isExecuting && this.output) {
      Row({ space: 8 }) {
        // 数据分析按钮
        if (canAnalyzeOutput(this.params?.command || '')) {
          Button('数据分析')
            .fontSize(12)
            .height(28)
            .backgroundColor($r('sys.color.comp_background_tertiary'))
            .fontColor($r('sys.color.font'))
            .onClick(() => {
              this.goToAnalysis()
            })
        }

        // 命令帮助按钮
        Button('命令帮助')
          .fontSize(12)
          .height(28)
          .backgroundColor($r('sys.color.comp_background_tertiary'))
          .fontColor($r('sys.color.font'))
          .onClick(() => {
            this.goToHelp()
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
      .padding({ right: 16, bottom: 8 })
    }
  }

  build() {
    NavDestination() {
      Column({ space: 12 }) {
        // 命令信息卡片
        Column({ space: 12 }) {
          Row() {
            Text('执行命令').fontSize(14).fontColor($r('sys.color.font_secondary'))
            Blank()
            this.StatusBadge()
          }.width('100%')

          // 命令显示
          Text(this.params?.command || '')
            .fontSize(14)
            .fontFamily('monospace')
            .fontColor($r('sys.color.font'))
            .width('100%')
            .padding(12)
            .backgroundColor($r('sys.color.comp_background_tertiary'))
            .borderRadius(8)
            .textAlign(TextAlign.Start)
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius(16)

        // 执行时间统计
        this.TimeStats()

        // 快捷操作
        this.QuickActions()

        // 输出区域
        Column({ space: 12 }) {
          Row() {
            Text('命令输出').fontSize(14).fontColor($r('sys.color.font_secondary'))
            Blank()
            if (this.output) {
              Row({ space: 12 }) {
                Text(`${this.output.split('\n').length} 行`)
                  .fontSize(12)
                  .fontColor($r('sys.color.font_tertiary'))

                // 复制按钮
                SymbolGlyph($r('sys.symbol.text_clipboard'))
                  .fontColor([$r('sys.color.font_secondary')])
                  .fontSize(16)
                  .onClick(() => {
                    this.copyToClipboard()
                  })
              }
            }
          }.width('100%')

          Scroll() {
            if (this.isExecuting) {
              Column() {
                LoadingProgress().width(32).height(32)
                Text('正在执行命令...').fontSize(14).fontColor($r('sys.color.font_secondary')).margin({ top: 8 })
              }
              .width('100%')
              .padding(32)
              .justifyContent(FlexAlign.Center)
            } else if (this.errorMessage) {
              Text(this.errorMessage)
                .fontSize(14)
                .fontFamily('monospace')
                .fontColor($r('sys.color.warning'))
                .width('100%')
                .padding(12)
            } else if (this.output) {
              Text(this.output)
                .fontSize(13)
                .fontFamily('monospace')
                .fontColor($r('sys.color.font'))
                .width('100%')
                .padding(12)
                .textAlign(TextAlign.Start)
                .copyOption(CopyOptions.LocalDevice)
            } else if (this.hasExecuted) {
              Text('命令已执行，无输出')
                .fontSize(14)
                .fontColor($r('sys.color.font_tertiary'))
                .width('100%')
                .padding(12)
                .textAlign(TextAlign.Center)
            } else {
              Text('等待执行...')
                .fontSize(14)
                .fontColor($r('sys.color.font_tertiary'))
                .width('100%')
                .padding(12)
                .textAlign(TextAlign.Center)
            }
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor($r('sys.color.comp_background_tertiary'))
          .borderRadius(8)
          .scrollBar(BarState.Auto)
          .edgeEffect(EdgeEffect.Spring)
        }
        .width('100%')
        .layoutWeight(1)
        .padding(16)
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius(16)

        // 操作按钮
        Row({ space: 12 }) {
          Button('历史记录')
            .layoutWeight(1)
            .backgroundColor($r('sys.color.comp_background_tertiary'))
            .fontColor($r('sys.color.font'))
            .onClick(() => {
              this.showHistory = true
            })

          Button('分享')
            .layoutWeight(1)
            .backgroundColor($r('sys.color.comp_background_tertiary'))
            .fontColor($r('sys.color.font'))
            .enabled(this.hasExecuted && !this.isExecuting)
            .onClick(() => {
              const context = this.getUIContext().getHostContext() as common.UIAbilityContext
              this.shareOutput(context)
            })

          Button('重新执行')
            .layoutWeight(1)
            .enabled(!this.isExecuting)
            .onClick(() => {
              this.executeCommand()
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 16 })
      }
      .width('100%')
      .height('100%')
      .padding({ top: 12, left: 12, right: 12 })
    }
    .title(this.params?.title || '命令执行')
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_secondary'))
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
      // 重新获取参数
      const rawParams = this.pathStack.getParamByIndex(this.pathStack.size() - 1) as CommandExecuteParams
      if (rawParams && !this.params) {
        this.params = rawParams
        this.executeCommand()
      }
    })
    .bindSheet(this.showHistory, this.HistoryList(), {
      height: SheetSize.MEDIUM,
      showClose: true,
      title: { title: '命令历史' },
      onDisappear: () => {
        this.showHistory = false
      }
    })
  }
}
