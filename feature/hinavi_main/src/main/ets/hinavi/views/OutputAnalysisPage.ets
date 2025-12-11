import { GuestAgentHelper, ExecResult } from '../../lib/Agent/GuestAgent'
import { pasteboard } from '@kit.BasicServicesKit'
import { promptAction } from '@kit.ArkUI'
import GlobalStore from '../../common/statemgmt/GlobalStore'
import { getBaseCommand } from './CommandExecutePage'
import { CommandHelpParams } from './CommandHelpPage'

/**
 * 输出分析页面参数
 */
export interface OutputAnalysisParams {
  command: string
  output: string
  title: string
}

/**
 * 进程信息
 */
interface ProcessInfo {
  user: string
  pid: string
  cpu: string
  mem: string
  vsz: string
  rss: string
  tty: string
  stat: string
  start: string
  time: string
  command: string
}

/**
 * 磁盘信息
 */
interface DiskInfo {
  filesystem: string
  size: string
  used: string
  available: string
  usePercent: number
  mountPoint: string
}

/**
 * 内存信息
 */
interface MemoryInfo {
  type: string
  total: string
  used: string
  free: string
  shared: string
  buffCache: string
  available: string
}

/**
 * 网络连接信息
 */
interface NetConnectionInfo {
  protocol: string
  recvQ: string
  sendQ: string
  localAddress: string
  foreignAddress: string
  state: string
}

/**
 * 解析输出类型
 */
type AnalysisType = 'process' | 'disk' | 'memory' | 'network' | 'unknown'

@ComponentV2
export struct OutputAnalysisPage {
  pathStack: NavPathStack = new NavPathStack()
  @Local params: OutputAnalysisParams | null = null

  // 解析结果
  @Local analysisType: AnalysisType = 'unknown'
  @Local processes: ProcessInfo[] = []
  @Local disks: DiskInfo[] = []
  @Local memories: MemoryInfo[] = []
  @Local netConnections: NetConnectionInfo[] = []

  // 筛选与排序
  @Local processFilter: string = ''
  @Local processSortBy: string = 'cpu'
  @Local processSortDesc: boolean = true

  // 选中项
  @Local selectedProcess: ProcessInfo | null = null
  @Local showProcessDetail: boolean = false

  aboutToAppear(): void {
    const rawParams = this.pathStack.getParamByIndex(this.pathStack.size() - 1) as OutputAnalysisParams
    if (rawParams) {
      this.params = rawParams
      this.analyzeOutput()
    }
  }

  /**
   * 分析输出内容
   */
  analyzeOutput() {
    if (!this.params) return

    const cmd = this.params.command.toLowerCase()
    const output = this.params.output

    if (cmd.includes('ps aux') || cmd.includes('ps -ef') || cmd.includes('ps -aux')) {
      this.analysisType = 'process'
      this.parseProcessOutput(output)
    } else if (cmd.includes('df')) {
      this.analysisType = 'disk'
      this.parseDiskOutput(output)
    } else if (cmd.includes('free')) {
      this.analysisType = 'memory'
      this.parseMemoryOutput(output)
    } else if (cmd.includes('netstat') || cmd.includes('ss')) {
      this.analysisType = 'network'
      this.parseNetworkOutput(output)
    } else if (cmd.includes('top')) {
      this.analysisType = 'process'
      this.parseTopOutput(output)
    } else {
      this.analysisType = 'unknown'
    }
  }

  /**
   * 解析 ps aux 输出
   */
  parseProcessOutput(output: string) {
    const lines = output.trim().split('\n')
    if (lines.length < 2) return

    this.processes = []
    // 跳过标题行
    for (let i = 1; i < lines.length; i++) {
      const parts = lines[i].trim().split(/\s+/)
      if (parts.length >= 11) {
        this.processes.push({
          user: parts[0],
          pid: parts[1],
          cpu: parts[2],
          mem: parts[3],
          vsz: parts[4],
          rss: parts[5],
          tty: parts[6],
          stat: parts[7],
          start: parts[8],
          time: parts[9],
          command: parts.slice(10).join(' ')
        })
      }
    }
  }

  /**
   * 解析 top 输出（batch模式）
   */
  parseTopOutput(output: string) {
    const lines = output.trim().split('\n')
    this.processes = []

    let inProcessList = false
    for (const line of lines) {
      if (line.includes('PID') && line.includes('USER') && line.includes('COMMAND')) {
        inProcessList = true
        continue
      }
      if (inProcessList && line.trim()) {
        const parts = line.trim().split(/\s+/)
        if (parts.length >= 12) {
          this.processes.push({
            pid: parts[0],
            user: parts[1],
            cpu: parts[8],
            mem: parts[9],
            vsz: parts[4],
            rss: parts[5],
            tty: parts[6],
            stat: parts[7],
            start: '--',
            time: parts[10],
            command: parts.slice(11).join(' ')
          })
        }
      }
    }
  }

  /**
   * 解析 df -h 输出
   */
  parseDiskOutput(output: string) {
    const lines = output.trim().split('\n')
    if (lines.length < 2) return

    this.disks = []
    for (let i = 1; i < lines.length; i++) {
      const parts = lines[i].trim().split(/\s+/)
      if (parts.length >= 6) {
        const usePercentStr = parts[4].replace('%', '')
        this.disks.push({
          filesystem: parts[0],
          size: parts[1],
          used: parts[2],
          available: parts[3],
          usePercent: parseInt(usePercentStr) || 0,
          mountPoint: parts[5]
        })
      }
    }
  }

  /**
   * 解析 free -h 输出
   */
  parseMemoryOutput(output: string) {
    const lines = output.trim().split('\n')
    if (lines.length < 2) return

    this.memories = []
    for (let i = 1; i < lines.length; i++) {
      const parts = lines[i].trim().split(/\s+/)
      if (parts.length >= 3) {
        this.memories.push({
          type: parts[0].replace(':', ''),
          total: parts[1] || '--',
          used: parts[2] || '--',
          free: parts[3] || '--',
          shared: parts[4] || '--',
          buffCache: parts[5] || '--',
          available: parts[6] || '--'
        })
      }
    }
  }

  /**
   * 解析网络连接输出
   */
  parseNetworkOutput(output: string) {
    const lines = output.trim().split('\n')
    if (lines.length < 2) return

    this.netConnections = []
    for (let i = 1; i < lines.length; i++) {
      const parts = lines[i].trim().split(/\s+/)
      if (parts.length >= 4) {
        this.netConnections.push({
          protocol: parts[0],
          recvQ: parts[1] || '0',
          sendQ: parts[2] || '0',
          localAddress: parts[3] || '--',
          foreignAddress: parts[4] || '--',
          state: parts[5] || 'LISTEN'
        })
      }
    }
  }

  /**
   * 获取筛选后的进程列表
   */
  getFilteredProcesses(): ProcessInfo[] {
    let filtered = this.processes

    // 筛选
    if (this.processFilter) {
      const filter = this.processFilter.toLowerCase()
      filtered = filtered.filter(p =>
        p.command.toLowerCase().includes(filter) ||
        p.user.toLowerCase().includes(filter) ||
        p.pid.includes(filter)
      )
    }

    // 排序
    filtered = filtered.sort((a, b) => {
      let aVal: number = 0
      let bVal: number = 0

      if (this.processSortBy === 'cpu') {
        aVal = parseFloat(a.cpu) || 0
        bVal = parseFloat(b.cpu) || 0
      } else if (this.processSortBy === 'mem') {
        aVal = parseFloat(a.mem) || 0
        bVal = parseFloat(b.mem) || 0
      } else if (this.processSortBy === 'pid') {
        aVal = parseInt(a.pid) || 0
        bVal = parseInt(b.pid) || 0
      }

      return this.processSortDesc ? bVal - aVal : aVal - bVal
    })

    return filtered
  }

  /**
   * 跳转到命令帮助页面
   */
  goToHelp() {
    if (this.params) {
      const baseCmd = getBaseCommand(this.params.command)
      GlobalStore.pageStack.pushPathByName('CommandHelp', {
        command: baseCmd
      } as CommandHelpParams, true)
    }
  }

  /**
   * 显示进程详情
   */
  showProcessInfo(process: ProcessInfo) {
    this.selectedProcess = process
    this.showProcessDetail = true
  }

  /**
   * 获取使用率的颜色
   */
  getUsageColor(percent: number): ResourceColor {
    if (percent >= 90) {
      return $r('sys.color.warning')
    } else if (percent >= 70) {
      return '#FFA500' // Orange
    } else {
      return $r('sys.color.multi_color_09')
    }
  }

  @Builder
  ProcessListView() {
    Column({ space: 12 }) {
      // 搜索和排序
      Row({ space: 8 }) {
        Search({ placeholder: '搜索进程...', value: this.processFilter })
          .layoutWeight(1)
          .height(36)
          .onChange((value) => {
            this.processFilter = value
          })

        Button(this.processSortBy === 'cpu' ? 'CPU' : (this.processSortBy === 'mem' ? 'MEM' : 'PID'))
          .fontSize(12)
          .height(36)
          .backgroundColor($r('sys.color.comp_background_tertiary'))
          .fontColor($r('sys.color.font'))
          .onClick(() => {
            if (this.processSortBy === 'cpu') {
              this.processSortBy = 'mem'
            } else if (this.processSortBy === 'mem') {
              this.processSortBy = 'pid'
            } else {
              this.processSortBy = 'cpu'
            }
          })

        Button({ type: ButtonType.Circle }) {
          SymbolGlyph(this.processSortDesc ? $r('sys.symbol.arrow_down') : $r('sys.symbol.arrow_up'))
            .fontColor([$r('sys.color.font_secondary')])
            .fontSize(14)
        }
        .width(36)
        .height(36)
        .backgroundColor($r('sys.color.comp_background_tertiary'))
        .onClick(() => {
          this.processSortDesc = !this.processSortDesc
        })
      }.width('100%')

      // 统计信息
      Row({ space: 16 }) {
        Text(`共 ${this.processes.length} 个进程`)
          .fontSize(12)
          .fontColor($r('sys.color.font_tertiary'))
        if (this.processFilter) {
          Text(`筛选结果: ${this.getFilteredProcesses().length}`)
            .fontSize(12)
            .fontColor($r('sys.color.font_tertiary'))
        }
      }.width('100%')

      // 进程列表
      List({ space: 8 }) {
        ForEach(this.getFilteredProcesses(), (process: ProcessInfo) => {
          ListItem() {
            Row({ space: 12 }) {
              // 进程信息
              Column({ space: 4 }) {
                Row({ space: 8 }) {
                  Text(process.command)
                    .fontSize(14)
                    .fontColor($r('sys.color.font'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1)
                  Text(`PID: ${process.pid}`)
                    .fontSize(11)
                    .fontColor($r('sys.color.font_tertiary'))
                }

                Row({ space: 16 }) {
                  Row({ space: 4 }) {
                    Text('CPU').fontSize(10).fontColor($r('sys.color.font_tertiary'))
                    Text(`${process.cpu}%`)
                      .fontSize(12)
                      .fontColor(parseFloat(process.cpu) > 50 ? $r('sys.color.warning') : $r('sys.color.font_secondary'))
                  }
                  Row({ space: 4 }) {
                    Text('MEM').fontSize(10).fontColor($r('sys.color.font_tertiary'))
                    Text(`${process.mem}%`)
                      .fontSize(12)
                      .fontColor(parseFloat(process.mem) > 50 ? $r('sys.color.warning') : $r('sys.color.font_secondary'))
                  }
                  Text(`用户: ${process.user}`)
                    .fontSize(11)
                    .fontColor($r('sys.color.font_tertiary'))
                }
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              // 查看详情
              SymbolGlyph($r('sys.symbol.chevron_right'))
                .fontColor([$r('sys.color.font_tertiary')])
                .fontSize(14)
            }
            .width('100%')
            .padding(12)
            .backgroundColor($r('sys.color.comp_background_tertiary'))
            .borderRadius(8)
            .onClick(() => this.showProcessInfo(process))
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  DiskListView() {
    Column({ space: 12 }) {
      // 磁盘列表
      List({ space: 12 }) {
        ForEach(this.disks, (disk: DiskInfo) => {
          ListItem() {
            Column({ space: 12 }) {
              Row() {
                Text(disk.mountPoint)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('sys.color.font'))
                Blank()
                Text(disk.filesystem)
                  .fontSize(12)
                  .fontColor($r('sys.color.font_tertiary'))
              }.width('100%')

              // 使用率进度条
              Column({ space: 4 }) {
                Progress({ value: disk.usePercent, total: 100, type: ProgressType.Linear })
                  .style({ strokeWidth: 8 })
                  .color(this.getUsageColor(disk.usePercent))
                  .width('100%')

                Row() {
                  Text(`已用: ${disk.used}`)
                    .fontSize(12)
                    .fontColor($r('sys.color.font_secondary'))
                  Blank()
                  Text(`${disk.usePercent}%`)
                    .fontSize(12)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.getUsageColor(disk.usePercent))
                  Blank()
                  Text(`可用: ${disk.available}`)
                    .fontSize(12)
                    .fontColor($r('sys.color.font_secondary'))
                }.width('100%')
              }

              Row({ space: 16 }) {
                Text(`总容量: ${disk.size}`)
                  .fontSize(11)
                  .fontColor($r('sys.color.font_tertiary'))
              }.width('100%')
            }
            .width('100%')
            .padding(16)
            .backgroundColor($r('sys.color.comp_background_tertiary'))
            .borderRadius(12)
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  MemoryView() {
    Column({ space: 12 }) {
      ForEach(this.memories, (mem: MemoryInfo) => {
        Column({ space: 12 }) {
          Row() {
            Text(mem.type)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('sys.color.font'))
          }.width('100%')

          Grid() {
            GridItem() {
              Column({ space: 4 }) {
                Text('总量').fontSize(12).fontColor($r('sys.color.font_tertiary'))
                Text(mem.total).fontSize(14).fontColor($r('sys.color.font'))
              }
            }
            GridItem() {
              Column({ space: 4 }) {
                Text('已用').fontSize(12).fontColor($r('sys.color.font_tertiary'))
                Text(mem.used).fontSize(14).fontColor($r('sys.color.warning'))
              }
            }
            GridItem() {
              Column({ space: 4 }) {
                Text('空闲').fontSize(12).fontColor($r('sys.color.font_tertiary'))
                Text(mem.free).fontSize(14).fontColor($r('sys.color.multi_color_09'))
              }
            }
            if (mem.available !== '--') {
              GridItem() {
                Column({ space: 4 }) {
                  Text('可用').fontSize(12).fontColor($r('sys.color.font_tertiary'))
                  Text(mem.available).fontSize(14).fontColor($r('sys.color.font'))
                }
              }
            }
          }
          .columnsTemplate(mem.available !== '--' ? '1fr 1fr 1fr 1fr' : '1fr 1fr 1fr')
          .rowsTemplate('1fr')
          .width('100%')
          .height(60)
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('sys.color.comp_background_tertiary'))
        .borderRadius(12)
      })
    }
    .width('100%')
  }

  @Builder
  NetworkView() {
    Column({ space: 12 }) {
      // 统计
      Text(`共 ${this.netConnections.length} 个连接`)
        .fontSize(12)
        .fontColor($r('sys.color.font_tertiary'))
        .width('100%')

      List({ space: 8 }) {
        ForEach(this.netConnections, (conn: NetConnectionInfo) => {
          ListItem() {
            Row({ space: 12 }) {
              // 协议标签
              Text(conn.protocol.toUpperCase())
                .fontSize(10)
                .fontColor(Color.White)
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .backgroundColor(conn.protocol.includes('tcp') ? '#007AFF' : '#34C759')
                .borderRadius(4)

              Column({ space: 4 }) {
                Text(conn.localAddress)
                  .fontSize(13)
                  .fontFamily('monospace')
                  .fontColor($r('sys.color.font'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Row({ space: 8 }) {
                  Text(conn.state)
                    .fontSize(11)
                    .fontColor(conn.state === 'LISTEN' ? $r('sys.color.multi_color_09') : $r('sys.color.font_tertiary'))
                  if (conn.foreignAddress && conn.foreignAddress !== '--' && conn.foreignAddress !== '*:*') {
                    Text(`→ ${conn.foreignAddress}`)
                      .fontSize(11)
                      .fontColor($r('sys.color.font_tertiary'))
                  }
                }
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .padding(12)
            .backgroundColor($r('sys.color.comp_background_tertiary'))
            .borderRadius(8)
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  UnknownView() {
    Column({ space: 16 }) {
      SymbolGlyph($r('sys.symbol.questionmark_circle'))
        .fontColor([$r('sys.color.font_tertiary')])
        .fontSize(48)

      Text('无法解析此命令的输出')
        .fontSize(16)
        .fontColor($r('sys.color.font_secondary'))

      Text('当前支持解析的命令类型:')
        .fontSize(14)
        .fontColor($r('sys.color.font_tertiary'))
        .margin({ top: 16 })

      Column({ space: 8 }) {
        Text('• ps aux / ps -ef（进程列表）').fontSize(13).fontColor($r('sys.color.font_tertiary'))
        Text('• df -h（磁盘使用）').fontSize(13).fontColor($r('sys.color.font_tertiary'))
        Text('• free -h（内存使用）').fontSize(13).fontColor($r('sys.color.font_tertiary'))
        Text('• netstat / ss（网络连接）').fontSize(13).fontColor($r('sys.color.font_tertiary'))
        Text('• top -b -n 1（进程监控）').fontSize(13).fontColor($r('sys.color.font_tertiary'))
      }
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  ProcessDetailSheet() {
    if (this.selectedProcess) {
      Column({ space: 16 }) {
        // 标题
        Row() {
          Text('进程详情').fontSize(18).fontWeight(FontWeight.Bold)
          Blank()
          Button({ type: ButtonType.Circle }) {
            SymbolGlyph($r('sys.symbol.xmark'))
              .fontColor([$r('sys.color.font_secondary')])
              .fontSize(14)
          }
          .width(32)
          .height(32)
          .backgroundColor($r('sys.color.comp_background_tertiary'))
          .onClick(() => {
            this.showProcessDetail = false
          })
        }.width('100%')

        // 命令
        Column({ space: 8 }) {
          Text('命令').fontSize(14).fontColor($r('sys.color.font_secondary'))
          Text(this.selectedProcess.command)
            .fontSize(13)
            .fontFamily('monospace')
            .fontColor($r('sys.color.font'))
            .width('100%')
            .padding(12)
            .backgroundColor($r('sys.color.comp_background_tertiary'))
            .borderRadius(8)
            .copyOption(CopyOptions.LocalDevice)
        }.width('100%').alignItems(HorizontalAlign.Start)

        // 详细信息网格
        Grid() {
          GridItem() {
            Column({ space: 4 }) {
              Text('PID').fontSize(12).fontColor($r('sys.color.font_tertiary'))
              Text(this.selectedProcess.pid).fontSize(14).fontColor($r('sys.color.font'))
            }
          }
          GridItem() {
            Column({ space: 4 }) {
              Text('用户').fontSize(12).fontColor($r('sys.color.font_tertiary'))
              Text(this.selectedProcess.user).fontSize(14).fontColor($r('sys.color.font'))
            }
          }
          GridItem() {
            Column({ space: 4 }) {
              Text('CPU').fontSize(12).fontColor($r('sys.color.font_tertiary'))
              Text(`${this.selectedProcess.cpu}%`)
                .fontSize(14)
                .fontColor(parseFloat(this.selectedProcess.cpu) > 50 ? $r('sys.color.warning') : $r('sys.color.font'))
            }
          }
          GridItem() {
            Column({ space: 4 }) {
              Text('内存').fontSize(12).fontColor($r('sys.color.font_tertiary'))
              Text(`${this.selectedProcess.mem}%`)
                .fontSize(14)
                .fontColor(parseFloat(this.selectedProcess.mem) > 50 ? $r('sys.color.warning') : $r('sys.color.font'))
            }
          }
          GridItem() {
            Column({ space: 4 }) {
              Text('VSZ').fontSize(12).fontColor($r('sys.color.font_tertiary'))
              Text(this.selectedProcess.vsz).fontSize(14).fontColor($r('sys.color.font'))
            }
          }
          GridItem() {
            Column({ space: 4 }) {
              Text('RSS').fontSize(12).fontColor($r('sys.color.font_tertiary'))
              Text(this.selectedProcess.rss).fontSize(14).fontColor($r('sys.color.font'))
            }
          }
          GridItem() {
            Column({ space: 4 }) {
              Text('TTY').fontSize(12).fontColor($r('sys.color.font_tertiary'))
              Text(this.selectedProcess.tty).fontSize(14).fontColor($r('sys.color.font'))
            }
          }
          GridItem() {
            Column({ space: 4 }) {
              Text('状态').fontSize(12).fontColor($r('sys.color.font_tertiary'))
              Text(this.selectedProcess.stat).fontSize(14).fontColor($r('sys.color.font'))
            }
          }
          GridItem() {
            Column({ space: 4 }) {
              Text('启动时间').fontSize(12).fontColor($r('sys.color.font_tertiary'))
              Text(this.selectedProcess.start).fontSize(14).fontColor($r('sys.color.font'))
            }
          }
          GridItem() {
            Column({ space: 4 }) {
              Text('CPU时间').fontSize(12).fontColor($r('sys.color.font_tertiary'))
              Text(this.selectedProcess.time).fontSize(14).fontColor($r('sys.color.font'))
            }
          }
        }
        .columnsTemplate('1fr 1fr')
        .rowsTemplate('1fr 1fr 1fr 1fr 1fr')
        .columnsGap(16)
        .rowsGap(12)
        .width('100%')
        .height(250)
      }
      .width('100%')
      .padding(20)
    }
  }

  build() {
    NavDestination() {
      Column({ space: 12 }) {
        // 命令信息
        Column({ space: 8 }) {
          Row() {
            Text('分析命令').fontSize(14).fontColor($r('sys.color.font_secondary'))
            Blank()
            Button('命令帮助')
              .fontSize(12)
              .height(28)
              .backgroundColor($r('sys.color.comp_background_tertiary'))
              .fontColor($r('sys.color.font'))
              .onClick(() => this.goToHelp())
          }.width('100%')

          Text(this.params?.command || '')
            .fontSize(13)
            .fontFamily('monospace')
            .fontColor($r('sys.color.font'))
            .width('100%')
            .padding(10)
            .backgroundColor($r('sys.color.comp_background_tertiary'))
            .borderRadius(8)
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius(16)

        // 分析结果
        Column({ space: 8 }) {
          Row() {
            Text('分析结果').fontSize(14).fontColor($r('sys.color.font_secondary'))
            Blank()
            Text(this.analysisType === 'process' ? '进程列表' :
              this.analysisType === 'disk' ? '磁盘使用' :
              this.analysisType === 'memory' ? '内存信息' :
              this.analysisType === 'network' ? '网络连接' : '未知类型')
              .fontSize(12)
              .fontColor($r('sys.color.font_tertiary'))
          }.width('100%')

          if (this.analysisType === 'process') {
            this.ProcessListView()
          } else if (this.analysisType === 'disk') {
            this.DiskListView()
          } else if (this.analysisType === 'memory') {
            this.MemoryView()
          } else if (this.analysisType === 'network') {
            this.NetworkView()
          } else {
            this.UnknownView()
          }
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
    .title(this.params?.title ? `${this.params.title} - 分析` : '输出分析')
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_secondary'))
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
      const rawParams = this.pathStack.getParamByIndex(this.pathStack.size() - 1) as OutputAnalysisParams
      if (rawParams && !this.params) {
        this.params = rawParams
        this.analyzeOutput()
      }
    })
    .bindSheet(this.showProcessDetail, this.ProcessDetailSheet(), {
      height: SheetSize.FIT_CONTENT,
      showClose: false,
      onDisappear: () => {
        this.showProcessDetail = false
      }
    })
  }
}
