import { GuestAgentHelper, ExecResult } from '../../lib/Agent/GuestAgent'
import { pasteboard } from '@kit.BasicServicesKit'
import { promptAction } from '@kit.ArkUI'
import GlobalStore from '../../common/statemgmt/GlobalStore'
import { CommandExecuteParams } from './CommandExecutePage'

/**
 * 命令帮助页面参数
 */
export interface CommandHelpParams {
  command: string
}

/**
 * 帮助类型
 */
type HelpType = 'help' | 'man'

@ComponentV2
export struct CommandHelpPage {
  pathStack: NavPathStack = new NavPathStack()
  @Local params: CommandHelpParams | null = null

  // 帮助内容
  @Local helpContent: string = ''
  @Local manContent: string = ''
  @Local isLoadingHelp: boolean = false
  @Local isLoadingMan: boolean = false
  @Local helpError: string = ''
  @Local manError: string = ''

  // 当前显示的帮助类型
  @Local currentHelpType: HelpType = 'help'

  // 搜索
  @Local searchKeyword: string = ''

  aboutToAppear(): void {
    const rawParams = this.pathStack.getParamByIndex(this.pathStack.size() - 1) as CommandHelpParams
    if (rawParams) {
      this.params = rawParams
      this.loadHelp()
    }
  }

  /**
   * 加载帮助信息
   */
  async loadHelp() {
    if (!this.params) return

    // 并行加载 --help 和 man
    this.loadHelpContent()
    this.loadManContent()
  }

  /**
   * 加载 --help 内容
   */
  async loadHelpContent() {
    if (!this.params) return

    this.isLoadingHelp = true
    this.helpError = ''
    this.helpContent = ''

    try {
      // 尝试 --help
      let result: ExecResult = await GuestAgentHelper.execWithExitCode('/root', `${this.params.command} --help 2>&1`)

      if (!result.output || result.output.trim().length === 0) {
        // 如果 --help 没有输出，尝试 -h
        result = await GuestAgentHelper.execWithExitCode('/root', `${this.params.command} -h 2>&1`)
      }

      if (result.output && result.output.trim().length > 0) {
        this.helpContent = result.output
      } else {
        this.helpError = '此命令不支持 --help 或 -h 选项'
      }
    } catch (e) {
      this.helpError = `获取帮助失败: ${(e as Error).message}`
    } finally {
      this.isLoadingHelp = false
    }
  }

  /**
   * 加载 man 内容
   */
  async loadManContent() {
    if (!this.params) return

    this.isLoadingMan = true
    this.manError = ''
    this.manContent = ''

    try {
      // 尝试获取 man 页面（使用 col -b 去除格式控制字符）
      const result: ExecResult = await GuestAgentHelper.execWithExitCode(
        '/root',
        `man ${this.params.command} 2>&1 | col -b`
      )

      if (result.success && result.output && result.output.trim().length > 0 &&
          !result.output.includes('No manual entry')) {
        this.manContent = result.output
      } else {
        this.manError = '此命令没有 man 手册页'
      }
    } catch (e) {
      this.manError = `获取 man 手册失败: ${(e as Error).message}`
    } finally {
      this.isLoadingMan = false
    }
  }

  /**
   * 复制到剪贴板
   */
  copyToClipboard() {
    const content = this.currentHelpType === 'help' ? this.helpContent : this.manContent
    if (!content) return

    const pasteboardData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, content)
    const systemPasteboard = pasteboard.getSystemPasteboard()
    systemPasteboard.setData(pasteboardData)
    promptAction.showToast({ message: '已复制到剪贴板' })
  }

  /**
   * 获取高亮显示的内容
   */
  getHighlightedContent(): string {
    const content = this.currentHelpType === 'help' ? this.helpContent : this.manContent
    if (!content) return ''
    return content
  }

  /**
   * 获取当前内容
   */
  getCurrentContent(): string {
    return this.currentHelpType === 'help' ? this.helpContent : this.manContent
  }

  /**
   * 获取当前错误
   */
  getCurrentError(): string {
    return this.currentHelpType === 'help' ? this.helpError : this.manError
  }

  /**
   * 是否正在加载
   */
  isLoading(): boolean {
    return this.currentHelpType === 'help' ? this.isLoadingHelp : this.isLoadingMan
  }

  /**
   * 执行命令
   */
  executeCommand() {
    if (this.params) {
      GlobalStore.pageStack.pushPathByName('CommandExecute', {
        command: this.params.command,
        title: `执行 ${this.params.command}`
      } as CommandExecuteParams, true)
    }
  }

  @Builder
  TabSelector() {
    Row({ space: 0 }) {
      Button('--help')
        .fontSize(13)
        .height(32)
        .layoutWeight(1)
        .backgroundColor(this.currentHelpType === 'help' ? $r('sys.color.comp_background_emphasize') : $r('sys.color.comp_background_tertiary'))
        .fontColor(this.currentHelpType === 'help' ? Color.White : $r('sys.color.font_secondary'))
        .borderRadius({ topLeft: 8, bottomLeft: 8, topRight: 0, bottomRight: 0 })
        .onClick(() => {
          this.currentHelpType = 'help'
        })

      Button('man 手册')
        .fontSize(13)
        .height(32)
        .layoutWeight(1)
        .backgroundColor(this.currentHelpType === 'man' ? $r('sys.color.comp_background_emphasize') : $r('sys.color.comp_background_tertiary'))
        .fontColor(this.currentHelpType === 'man' ? Color.White : $r('sys.color.font_secondary'))
        .borderRadius({ topLeft: 0, bottomLeft: 0, topRight: 8, bottomRight: 8 })
        .onClick(() => {
          this.currentHelpType = 'man'
        })
    }
    .width('100%')
  }

  @Builder
  ContentView() {
    if (this.isLoading()) {
      Column() {
        LoadingProgress().width(32).height(32)
        Text(this.currentHelpType === 'help' ? '正在获取帮助信息...' : '正在获取 man 手册...')
          .fontSize(14)
          .fontColor($r('sys.color.font_secondary'))
          .margin({ top: 8 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    } else if (this.getCurrentError()) {
      Column({ space: 12 }) {
        SymbolGlyph($r('sys.symbol.exclamationmark_circle'))
          .fontColor([$r('sys.color.font_tertiary')])
          .fontSize(40)

        Text(this.getCurrentError())
          .fontSize(14)
          .fontColor($r('sys.color.font_tertiary'))
          .textAlign(TextAlign.Center)

        Button('重新加载')
          .fontSize(13)
          .height(32)
          .backgroundColor($r('sys.color.comp_background_tertiary'))
          .fontColor($r('sys.color.font'))
          .onClick(() => {
            if (this.currentHelpType === 'help') {
              this.loadHelpContent()
            } else {
              this.loadManContent()
            }
          })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    } else if (this.getCurrentContent()) {
      Scroll() {
        Text(this.getCurrentContent())
          .fontSize(13)
          .fontFamily('monospace')
          .fontColor($r('sys.color.font'))
          .width('100%')
          .padding(12)
          .textAlign(TextAlign.Start)
          .copyOption(CopyOptions.LocalDevice)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
    } else {
      Column() {
        Text('暂无内容')
          .fontSize(14)
          .fontColor($r('sys.color.font_tertiary'))
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
  }

  @Builder
  CommonOptions() {
    if (this.params) {
      Column({ space: 8 }) {
        Text('常用选项速查').fontSize(14).fontColor($r('sys.color.font_secondary')).width('100%')

        Scroll() {
          Column({ space: 6 }) {
            ForEach(this.getCommonOptions(), (option: [string, string]) => {
              Row({ space: 8 }) {
                Text(option[0])
                  .fontSize(12)
                  .fontFamily('monospace')
                  .fontColor($r('sys.color.font'))
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .backgroundColor($r('sys.color.comp_background_tertiary'))
                  .borderRadius(4)

                Text(option[1])
                  .fontSize(12)
                  .fontColor($r('sys.color.font_secondary'))
                  .layoutWeight(1)
              }.width('100%')
            })
          }
        }
        .width('100%')
        .constraintSize({ maxHeight: 150 })
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .padding(12)
      .backgroundColor($r('sys.color.comp_background_tertiary'))
      .borderRadius(8)
    }
  }

  /**
   * 获取常用选项（根据命令类型）
   */
  getCommonOptions(): [string, string][] {
    if (!this.params) return []

    const cmd = this.params.command.toLowerCase()
    const commonOptionsMap: Record<string, [string, string][]> = {
      'ls': [
        ['-l', '详细列表格式'],
        ['-a', '显示隐藏文件'],
        ['-h', '人类可读的文件大小'],
        ['-R', '递归列出子目录'],
        ['-t', '按修改时间排序'],
        ['-S', '按文件大小排序']
      ],
      'ps': [
        ['aux', '显示所有进程详细信息'],
        ['-ef', '显示所有进程'],
        ['-u <user>', '显示指定用户的进程'],
        ['--sort=-%mem', '按内存使用排序'],
        ['--sort=-%cpu', '按 CPU 使用排序']
      ],
      'df': [
        ['-h', '人类可读格式'],
        ['-T', '显示文件系统类型'],
        ['-i', '显示 inode 信息'],
        ['-a', '显示所有文件系统']
      ],
      'du': [
        ['-h', '人类可读格式'],
        ['-s', '只显示总计'],
        ['-a', '显示所有文件'],
        ['--max-depth=N', '显示 N 层深度']
      ],
      'free': [
        ['-h', '人类可读格式'],
        ['-m', '以 MB 为单位'],
        ['-g', '以 GB 为单位'],
        ['-s N', '每 N 秒刷新一次']
      ],
      'top': [
        ['-b', '批处理模式'],
        ['-n N', '刷新 N 次后退出'],
        ['-p PID', '只监控指定进程'],
        ['-u user', '只显示指定用户进程']
      ],
      'grep': [
        ['-i', '忽略大小写'],
        ['-r', '递归搜索'],
        ['-n', '显示行号'],
        ['-v', '反向匹配'],
        ['-E', '使用扩展正则'],
        ['-c', '只显示匹配行数']
      ],
      'find': [
        ['-name', '按名称查找'],
        ['-type f/d', '按类型(文件/目录)'],
        ['-size +10M', '按大小查找'],
        ['-mtime -7', '最近7天修改的'],
        ['-exec cmd {} \\;', '对结果执行命令']
      ],
      'netstat': [
        ['-t', '显示 TCP 连接'],
        ['-u', '显示 UDP 连接'],
        ['-l', '只显示监听端口'],
        ['-n', '显示数字地址'],
        ['-p', '显示进程信息']
      ],
      'ss': [
        ['-t', '显示 TCP'],
        ['-u', '显示 UDP'],
        ['-l', '只显示监听'],
        ['-n', '显示数字'],
        ['-p', '显示进程']
      ],
      'tail': [
        ['-n N', '显示最后 N 行'],
        ['-f', '实时跟踪文件'],
        ['-F', '跟踪并重试'],
        ['--pid=PID', '进程结束时退出']
      ],
      'cat': [
        ['-n', '显示行号'],
        ['-b', '非空行编号'],
        ['-s', '压缩空行'],
        ['-A', '显示所有字符']
      ]
    }

    return commonOptionsMap[cmd] || [
      ['--help', '显示帮助信息'],
      ['--version', '显示版本信息'],
      ['-v', '详细模式'],
      ['-q', '安静模式']
    ]
  }

  build() {
    NavDestination() {
      Column({ space: 12 }) {
        // 命令信息
        Column({ space: 12 }) {
          Row() {
            Text('命令').fontSize(14).fontColor($r('sys.color.font_secondary'))
            Blank()
            Button('执行命令')
              .fontSize(12)
              .height(28)
              .backgroundColor($r('sys.color.comp_background_tertiary'))
              .fontColor($r('sys.color.font'))
              .onClick(() => this.executeCommand())
          }.width('100%')

          Row({ space: 8 }) {
            Text(this.params?.command || '')
              .fontSize(16)
              .fontFamily('monospace')
              .fontWeight(FontWeight.Medium)
              .fontColor($r('sys.color.font'))
              .layoutWeight(1)
          }.width('100%')

          // 常用选项
          this.CommonOptions()
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius(16)

        // 帮助内容区域
        Column({ space: 12 }) {
          Row() {
            Text('帮助文档').fontSize(14).fontColor($r('sys.color.font_secondary'))
            Blank()
            if (this.getCurrentContent()) {
              SymbolGlyph($r('sys.symbol.text_clipboard'))
                .fontColor([$r('sys.color.font_secondary')])
                .fontSize(16)
                .onClick(() => this.copyToClipboard())
            }
          }.width('100%')

          // Tab 选择器
          this.TabSelector()

          // 内容区域
          Column() {
            this.ContentView()
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor($r('sys.color.comp_background_tertiary'))
          .borderRadius(8)
        }
        .width('100%')
        .layoutWeight(1)
        .padding(16)
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius(16)
      }
      .width('100%')
      .height('100%')
      .padding({ top: 12, left: 12, right: 12, bottom: 12 })
    }
    .title(this.params ? `${this.params.command} 帮助` : '命令帮助')
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_secondary'))
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
      const rawParams = this.pathStack.getParamByIndex(this.pathStack.size() - 1) as CommandHelpParams
      if (rawParams && !this.params) {
        this.params = rawParams
        this.loadHelp()
      }
    })
  }
}
