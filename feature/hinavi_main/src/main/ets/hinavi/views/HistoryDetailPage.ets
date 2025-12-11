import { pasteboard } from '@kit.BasicServicesKit'
import { promptAction } from '@kit.ArkUI'
import { systemShare } from '@kit.ShareKit'
import { uniformTypeDescriptor as utd } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import GlobalStore from '../../common/statemgmt/GlobalStore'
import { commandHistory, CommandHistoryItem, canAnalyzeOutput, getBaseCommand,
  CommandExecuteParams } from './CommandExecutePage'
import { CommandHelpParams } from './CommandHelpPage'

/**
 * 历史记录详情页面参数
 */
export interface HistoryDetailParams {
  historyId: string
}

@ComponentV2
export struct HistoryDetailPage {
  pathStack: NavPathStack = new NavPathStack()
  @Local params: HistoryDetailParams | null = null
  @Local historyItem: CommandHistoryItem | null = null

  aboutToAppear(): void {
    const rawParams = this.pathStack.getParamByIndex(this.pathStack.size() - 1) as HistoryDetailParams
    if (rawParams) {
      this.params = rawParams
      this.historyItem = commandHistory.getById(rawParams.historyId) || null
    }
  }

  /**
   * 复制输出到剪贴板
   */
  copyToClipboard() {
    if (!this.historyItem) return
    const pasteboardData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.historyItem.output)
    const systemPasteboard = pasteboard.getSystemPasteboard()
    systemPasteboard.setData(pasteboardData)
    promptAction.showToast({ message: '已复制到剪贴板' })
  }

  /**
   * 复制命令到剪贴板
   */
  copyCommand() {
    if (!this.historyItem) return
    const pasteboardData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.historyItem.command)
    const systemPasteboard = pasteboard.getSystemPasteboard()
    systemPasteboard.setData(pasteboardData)
    promptAction.showToast({ message: '已复制命令' })
  }

  /**
   * 分享输出内容
   */
  async shareOutput(context: common.UIAbilityContext) {
    if (!this.historyItem) return

    const shareContent = `命令: ${this.historyItem.command}\n` +
      `执行时间: ${this.formatDateTime(this.historyItem.executedAt)}\n` +
      `耗时: ${this.formatDuration(this.historyItem.duration)}\n` +
      `返回码: ${this.historyItem.exitCode}\n` +
      `状态: ${this.historyItem.success ? '成功' : '失败'}\n` +
      `---输出---\n${this.historyItem.output}`

    const shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.PLAIN_TEXT,
      content: shareContent,
      title: `命令执行结果: ${this.historyItem.title}`
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
    if (this.historyItem?.output) {
      GlobalStore.pageStack.push('OutputAnalysis', {
        command: this.historyItem.command,
        output: this.historyItem.output,
        title: this.historyItem.title
      } as CommandHistoryItem)
    }
  }

  /**
   * 跳转到命令帮助页面
   */
  goToHelp() {
    if (this.historyItem) {
      const baseCmd = getBaseCommand(this.historyItem.command)
      GlobalStore.pageStack.push('CommandHelp', {
        command: baseCmd
      } as CommandExecuteParams)
    }
  }

  /**
   * 重新执行命令
   */
  reExecuteCommand() {
    if (this.historyItem) {
      GlobalStore.pageStack.push('CommandExecute', {
        command: this.historyItem.command,
        title: this.historyItem.title
      } as CommandHistoryItem)
    }
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
    const year = date.getFullYear()
    const month = (date.getMonth() + 1).toString().padStart(2, '0')
    const day = date.getDate().toString().padStart(2, '0')
    const hours = date.getHours().toString().padStart(2, '0')
    const minutes = date.getMinutes().toString().padStart(2, '0')
    const seconds = date.getSeconds().toString().padStart(2, '0')
    return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`
  }

  @Builder
  StatusBadge() {
    if (this.historyItem) {
      if (this.historyItem.success) {
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
          Text(`返回码: ${this.historyItem.exitCode}`).fontSize(14).fontColor($r('sys.color.warning'))
        }
      }
    }
  }

  @Builder
  InfoSection() {
    if (this.historyItem) {
      Column({ space: 12 }) {
        // 命令信息
        Row() {
          Text('执行命令').fontSize(14).fontColor($r('sys.color.font_secondary'))
          Blank()
          this.StatusBadge()
        }.width('100%')

        Row({ space: 8 }) {
          Text(this.historyItem.command)
            .fontSize(14)
            .fontFamily('monospace')
            .fontColor($r('sys.color.font'))
            .layoutWeight(1)
            .padding(12)
            .backgroundColor($r('sys.color.comp_background_tertiary'))
            .borderRadius(8)
            .textAlign(TextAlign.Start)

          // 复制命令按钮
          Button({ type: ButtonType.Circle }) {
            SymbolGlyph($r('sys.symbol.text_clipboard'))
              .fontColor([$r('sys.color.font_secondary')])
              .fontSize(16)
          }
          .width(36)
          .height(36)
          .backgroundColor($r('sys.color.comp_background_tertiary'))
          .onClick(() => this.copyCommand())
        }.width('100%')

        // 执行统计
        Divider().color($r('sys.color.comp_divider'))

        Column({ space: 8 }) {
          Row() {
            Text('执行统计').fontSize(14).fontColor($r('sys.color.font_secondary'))
          }.width('100%')

          Grid() {
            GridItem() {
              Column({ space: 4 }) {
                Text('执行时间').fontSize(12).fontColor($r('sys.color.font_tertiary'))
                Text(this.formatDateTime(this.historyItem.executedAt))
                  .fontSize(12)
                  .fontColor($r('sys.color.font'))
              }.alignItems(HorizontalAlign.Start)
            }

            GridItem() {
              Column({ space: 4 }) {
                Text('执行耗时').fontSize(12).fontColor($r('sys.color.font_tertiary'))
                Text(this.formatDuration(this.historyItem.duration))
                  .fontSize(13)
                  .fontColor(this.historyItem.duration > 5000 ? $r('sys.color.warning') : $r('sys.color.font'))
              }.alignItems(HorizontalAlign.Start)
            }

            GridItem() {
              Column({ space: 4 }) {
                Text('返回码').fontSize(12).fontColor($r('sys.color.font_tertiary'))
                Text(`${this.historyItem.exitCode}`)
                  .fontSize(13)
                  .fontColor(this.historyItem.exitCode === 0 ? $r('sys.color.multi_color_09') : $r('sys.color.warning'))
              }.alignItems(HorizontalAlign.Start)
            }

            GridItem() {
              Column({ space: 4 }) {
                Text('输出行数').fontSize(12).fontColor($r('sys.color.font_tertiary'))
                Text(`${this.historyItem.output ? this.historyItem.output.split('\n').length : 0} 行`)
                  .fontSize(13)
                  .fontColor($r('sys.color.font'))
              }.alignItems(HorizontalAlign.Start)
            }
          }
          .columnsTemplate('1fr 1fr')
          .rowsTemplate('1fr 1fr')
          .columnsGap(12)
          .rowsGap(12)
          .width('100%')
          .height(90)
        }

        // 错误信息（如果有）
        if (this.historyItem.errorMessage) {
          Divider().color($r('sys.color.comp_divider'))

          Column({ space: 8 }) {
            Row({ space: 4 }) {
              SymbolGlyph($r('sys.symbol.exclamationmark_triangle_fill'))
                .fontColor([$r('sys.color.warning')])
                .fontSize(14)
              Text('错误信息').fontSize(14).fontColor($r('sys.color.warning'))
            }

            Text(this.historyItem.errorMessage)
              .fontSize(13)
              .fontColor($r('sys.color.warning'))
              .width('100%')
              .padding(12)
              .backgroundColor($r('sys.color.comp_background_tertiary'))
              .borderRadius(8)
          }.width('100%').alignItems(HorizontalAlign.Start)
        }
      }
      .width('100%')
      .padding(16)
      .backgroundColor($r('sys.color.comp_background_primary'))
      .borderRadius(16)
    }
  }

  @Builder
  QuickActions() {
    if (this.historyItem?.output) {
      Row({ space: 8 }) {
        // 数据分析按钮
        if (canAnalyzeOutput(this.historyItem.command)) {
          Button('数据分析')
            .fontSize(12)
            .height(28)
            .backgroundColor($r('sys.color.comp_background_tertiary'))
            .fontColor($r('sys.color.font'))
            .onClick(() => this.goToAnalysis())
        }

        // 命令帮助按钮
        Button('命令帮助')
          .fontSize(12)
          .height(28)
          .backgroundColor($r('sys.color.comp_background_tertiary'))
          .fontColor($r('sys.color.font'))
          .onClick(() => this.goToHelp())
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
      .padding({ right: 16, bottom: 8 })
    }
  }

  @Builder
  OutputSection() {
    Column({ space: 12 }) {
      Row() {
        Text('命令输出').fontSize(14).fontColor($r('sys.color.font_secondary'))
        Blank()
        if (this.historyItem?.output) {
          Row({ space: 12 }) {
            Text(`${this.historyItem.output.split('\n').length} 行`)
              .fontSize(12)
              .fontColor($r('sys.color.font_tertiary'))

            // 复制按钮
            SymbolGlyph($r('sys.symbol.text_clipboard'))
              .fontColor([$r('sys.color.font_secondary')])
              .fontSize(16)
              .onClick(() => this.copyToClipboard())
          }
        }
      }.width('100%')

      Scroll() {
        if (this.historyItem?.output) {
          Text(this.historyItem.output)
            .fontSize(13)
            .fontFamily('monospace')
            .fontColor($r('sys.color.font'))
            .width('100%')
            .padding(12)
            .textAlign(TextAlign.Start)
            .copyOption(CopyOptions.LocalDevice)
        } else if (this.historyItem?.errorMessage) {
          Text(this.historyItem.errorMessage)
            .fontSize(14)
            .fontFamily('monospace')
            .fontColor($r('sys.color.warning'))
            .width('100%')
            .padding(12)
        } else {
          Text('无输出内容')
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
  }

  build() {
    NavDestination() {
      if (this.historyItem) {
        Column({ space: 12 }) {
          // 信息区域
          this.InfoSection()

          // 快捷操作
          this.QuickActions()

          // 输出区域
          this.OutputSection()

          // 操作按钮
          Row({ space: 12 }) {
            Button('分享')
              .layoutWeight(1)
              .backgroundColor($r('sys.color.comp_background_tertiary'))
              .fontColor($r('sys.color.font'))
              .onClick(() => {
                const context = this.getUIContext().getHostContext() as common.UIAbilityContext
                this.shareOutput(context)
              })

            Button('重新执行')
              .layoutWeight(1)
              .onClick(() => this.reExecuteCommand())
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 16 })
        }
        .width('100%')
        .height('100%')
        .padding({ top: 12, left: 12, right: 12 })
      } else {
        Column() {
          SymbolGlyph($r('sys.symbol.text_badge_questionmark'))
            .fontColor([$r('sys.color.font_tertiary')])
            .fontSize(48)
          Text('找不到历史记录')
            .fontSize(16)
            .fontColor($r('sys.color.font_tertiary'))
            .margin({ top: 16 })
          Text('该记录可能已被清除')
            .fontSize(14)
            .fontColor($r('sys.color.font_tertiary'))
            .margin({ top: 8 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
    }
    .title(this.historyItem?.title || '历史详情')
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_secondary'))
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
      const rawParams = this.pathStack.getParamByIndex(this.pathStack.size() - 1) as HistoryDetailParams
      if (rawParams && !this.params) {
        this.params = rawParams
        this.historyItem = commandHistory.getById(rawParams.historyId) || null
      }
    })
  }
}
