import { CommonItemContainer, CommonListItem } from '../../components/component_library/CommonListItem'
import { NavidromeServerUtils, VMUtils } from '../../common/utils/NavidromeServerUtils'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
import GlobalStore from '../../common/statemgmt/GlobalStore'
import { CommandExecuteParams } from './CommandExecutePage'

@ComponentV2
export struct UsefulTerminalView {
  scroller = new Scroller()
  backupDbProgress: CustomDialogController = new CustomDialogController({
    builder: LoadingDialog({
      content: '正在备份数据库...',
    }),
  })

  /**
   * 执行命令并跳转到结果页面
   */
  executeCommand(title: string, command: string) {
    const params: CommandExecuteParams = {
      command: command,
      title: title
    }
    GlobalStore.pageStack.pushPathByName('CommandExecute', params, true)
  }

  async backupNavidromeDb() {
    this.backupDbProgress.open()
    try {
      const backupPath = await NavidromeServerUtils.backupLibraryDB()
      promptAction.showToast({
        message: `备份成功: ${backupPath}`,
        duration: 3000
      })
    } catch (e) {
      promptAction.showToast({
        message: `备份失败: ${(e as Error).message}`,
        duration: 3000
      })
    } finally {
      this.backupDbProgress.close()
    }
  }

  build() {
    NavDestination() {
      List({ space: 12, scroller: this.scroller }) {
        // 系统管理
        ListItem() {
          CommonItemContainer() {
            CommonListItem({
              // icon: $r('sys.symbol.gearshape'),
              title: '系统管理',
              isCompose: true
            }) {}
            // CommonListItem({
            //   icon: $r('sys.symbol.moon_fill'),
            //   title: '关闭系统',
            //   subtitle: 'poweroff',
            //   isCompose: true
            // }).onClick(() => {
            //   VMUtils.suspendAndExecuteCommand('poweroff')
            // })
            CommonListItem({
              icon: $r('sys.symbol.clock'),
              title: '查看系统时间',
              subtitle: 'date',
              isCompose: true
            }).onClick(() => {
              this.executeCommand('查看系统时间', 'date')
            })
            CommonListItem({
              icon: $r('sys.symbol.timer'),
              title: '查看系统运行时间',
              subtitle: 'uptime',
              isCompose: true
            }).onClick(() => {
              this.executeCommand('查看系统运行时间', 'uptime')
            })
            CommonListItem({
              icon: $r('sys.symbol.info_circle'),
              title: '系统信息',
              subtitle: 'uname -a',
              isCompose: true
            }).onClick(() => {
              this.executeCommand('系统信息', 'uname -a')
            })
          }
        }

        // 进程管理
        ListItem() {
          CommonItemContainer() {
            CommonListItem({
              // icon: $r('sys.symbol.line_3_horizontal'),
              title: '进程管理',
              isCompose: true
            }) {}
            CommonListItem({
              icon: $r('sys.symbol.list_bullet'),
              title: '查看所有进程',
              subtitle: 'ps aux',
              isCompose: true
            }).onClick(() => {
              this.executeCommand('查看所有进程', 'ps aux')
            })
            CommonListItem({
              icon: $r('sys.symbol.monitor_fill'),
              title: '实时进程监控',
              subtitle: 'top -b -n 1',
              isCompose: true
            }).onClick(() => {
              this.executeCommand('实时进程监控', 'top -b -n 1')
            })
            CommonListItem({
              icon: $r('sys.symbol.application_projection'),
              title: '交互式进程查看器',
              subtitle: 'htop',
              isCompose: true
            }).onClick(() => {
              VMUtils.suspendAndExecuteCommand('htop')
            })
            // CommonListItem({
            //   icon: $r('sys.symbol.xmark_circle'),
            //   title: '按名称结束进程',
            //   subtitle: 'pkill [进程名]',
            //   isCompose: true
            // }).onClick(() => {
            //   // 这个命令需要用户输入参数，保留空实现或者提示用户
            // })
          }
        }

        // 文件操作
        ListItem() {
          CommonItemContainer() {
            CommonListItem({
              // icon: $r('sys.symbol.folder'),
              title: '文件操作',
              isCompose: true
            }) {}
            // CommonListItem({
            //   icon: $r('sys.symbol.list_bullet'),
            //   title: '详细列出文件',
            //   subtitle: 'ls -lah',
            //   isCompose: true
            // }).onClick(() => {
            //   this.executeCommand('详细列出文件', 'ls -lah')
            // })
            // CommonListItem({
            //   icon: $r('sys.symbol.folder'),
            //   title: '当前目录路径',
            //   subtitle: 'pwd',
            //   isCompose: true
            // }).onClick(() => {
            //   this.executeCommand('当前目录路径', 'pwd')
            // })
            CommonListItem({
              icon: $r('sys.symbol.archivebox'),
              title: '磁盘使用情况',
              subtitle: 'df -h',
              isCompose: true
            }).onClick(() => {
              this.executeCommand('磁盘使用情况', 'df -h')
            })
            CommonListItem({
              icon: $r('sys.symbol.hard_disk'),
              title: '音乐库目录大小',
              subtitle: 'du -sh /mnt/share/',
              isCompose: true
            }).onClick(() => {
              this.executeCommand('音乐库目录大小', 'du -sh /mnt/share/')
            })
            // CommonListItem({
            //   icon: $r('sys.symbol.magnifyingglass'),
            //   title: '查找文件',
            //   subtitle: 'find . -name [文件名]',
            //   isCompose: true
            // }).onClick(() => {
            //   // 这个命令需要用户输入参数，保留空实现
            // })
            // CommonListItem({
            //   icon: $r('sys.symbol.lock_fill'),
            //   title: '修改文件权限',
            //   subtitle: 'chmod [权限] [文件]',
            //   isCompose: true
            // }).onClick(() => {
            //   // 这个命令需要用户输入参数，保留空实现
            // })
            // CommonListItem({
            //   icon: $r('sys.symbol.person_2'),
            //   title: '修改文件所有者',
            //   subtitle: 'chown [用户]:[组] [文件]',
            //   isCompose: true
            // }).onClick(() => {
            //   // 这个命令需要用户输入参数，保留空实现
            // })
          }
        }

        // 网络管理
        ListItem() {
          CommonItemContainer() {
            CommonListItem({
              // icon: $r('sys.symbol.worldclock'),
              title: '网络管理',
              isCompose: true
            }) {}
            CommonListItem({
              icon: $r('sys.symbol.wifi'),
              title: '网络接口信息',
              subtitle: 'ip addr',
              isCompose: true
            }).onClick(() => {
              this.executeCommand('网络接口信息', 'ip addr')
            })
            CommonListItem({
              icon: $r('sys.symbol.dot_radiowaves_left_and_right'),
              title: 'Ping 测试网络',
              subtitle: 'ping -c 4 www.baidu.com',
              isCompose: true
            }).onClick(() => {
              this.executeCommand('Ping 测试网络', 'ping -c 4 www.baidu.com')
            })
            CommonListItem({
              icon: $r('sys.symbol.arrow_clockwise'),
              title: '网络连接状态',
              subtitle: 'netstat -tuln',
              isCompose: true
            }).onClick(() => {
              this.executeCommand('网络连接状态', 'netstat -tuln')
            })
            CommonListItem({
              icon: $r('sys.symbol.robot'),
              title: '监听端口',
              subtitle: 'ss -tuln',
              isCompose: true
            }).onClick(() => {
              this.executeCommand('监听端口', 'ss -tuln')
            })
          }
        }

        // 服务管理
        ListItem() {
          CommonItemContainer() {
            CommonListItem({
              // icon: $r('sys.symbol.service'),
              title: '服务管理',
              isCompose: true
            }) {}
            CommonListItem({
              icon: $r('sys.symbol.star_badge_list'),
              title: '查看所有服务',
              subtitle: 'rc-status -a',
              isCompose: true
            }).onClick(() => {
              this.executeCommand('查看所有服务', 'rc-status -a')
            })
            CommonListItem({
              icon: $r('sys.symbol.play_fill'),
              title: '启动 Navidrome 服务',
              subtitle: 'rc-service navidrome start',
              isCompose: true
            }).onClick(() => {
              this.executeCommand('启动 Navidrome 服务', 'rc-service navidrome start')
            })
            CommonListItem({
              icon: $r('sys.symbol.stop_circle'),
              title: '停止 Navidrome 服务',
              subtitle: 'rc-service navidrome stop',
              isCompose: true
            }).onClick(() => {
              this.executeCommand('停止 Navidrome 服务', 'rc-service navidrome stop')
            })
            CommonListItem({
              icon: $r('sys.symbol.arrow_clockwise'),
              title: '重启 Navidrome 服务',
              subtitle: 'rc-service navidrome restart',
              isCompose: true
            }).onClick(() => {
              this.executeCommand('重启 Navidrome 服务', 'rc-service navidrome restart')
            })
            CommonListItem({
              icon: $r('sys.symbol.checkmark_circle'),
              title: '查看服务状态',
              subtitle: 'rc-service navidrome status',
              isCompose: true
            }).onClick(() => {
              this.executeCommand('查看服务状态', 'rc-service navidrome status')
            })
            CommonListItem({
              icon: $r('sys.symbol.list_checkmask'),
              title: '查看 Navidrome 配置文件',
              subtitle: 'cat /etc/navidrome/navidrome.toml',
              isCompose: true
            }).onClick(() => {
              this.executeCommand('查看 Navidrome 配置文件', 'cat /etc/navidrome/navidrome.toml')
            })
            // 编辑配置文件功能已移除（QGA 不支持交互式编辑）
            CommonListItem({
              icon: $r('sys.symbol.externaldrive'),
              title: '备份 Navidrome 数据库',
              subtitle: '备份到 /mnt/share/',
              isCompose: true
            }).onClick(() => {
              this.backupNavidromeDb()
            })
          }
        }

        // 日志查看
        ListItem() {
          CommonItemContainer() {
            CommonListItem({
              // icon: $r('sys.symbol.doc_text'),
              title: '日志查看',
              isCompose: true
            }) {}
            CommonListItem({
              icon: $r('sys.symbol.book'),
              title: 'Navidrome 日志',
              subtitle: 'tail /var/log/navidrome.log',
              isCompose: true
            }).onClick(() => {
              this.executeCommand('Navidrome 日志', 'tail -n 50 /var/log/navidrome.log')
            })
            CommonListItem({
              icon: $r('sys.symbol.clock_arrow_2_circlepath'),
              title: '查看最新日志（100行）',
              subtitle: 'tail -n 100 /var/log/navidrome.log',
              isCompose: true
            }).onClick(() => {
              this.executeCommand('Navidrome 最新日志', 'tail -n 100 /var/log/navidrome.log')
            })
            // CommonListItem({
            //   icon: $r('sys.symbol.doc_text'),
            //   title: '查看文件末尾',
            //   subtitle: 'tail -f [文件]',
            //   isCompose: true
            // }).onClick(() => {
            //   // 这个命令需要用户输入参数，保留空实现
            // })
            // CommonListItem({
            //   icon: $r('sys.symbol.doc_plaintext'),
            //   title: '查看文件开头',
            //   subtitle: 'head -n 20 [文件]',
            //   isCompose: true
            // }).onClick(() => {
            //   // 这个命令需要用户输入参数，保留空实现
            // })
          }
        }

        // 用户管理
        // ListItem() {
        //   CommonItemContainer() {
        //     CommonListItem({
        //       icon: $r('sys.symbol.person_3'),
        //       title: '用户管理',
        //       isCompose: true
        //     }) {}
        //     CommonListItem({
        //       icon: $r('sys.symbol.person'),
        //       title: '当前用户',
        //       subtitle: 'whoami',
        //       isCompose: true
        //     }).onClick(() => {})
        //     CommonListItem({
        //       icon: $r('sys.symbol.person_2_fill'),
        //       title: '在线用户',
        //       subtitle: 'who',
        //       isCompose: true
        //     }).onClick(() => {})
        //     CommonListItem({
        //       icon: $r('sys.symbol.person_badge_plus'),
        //       title: '添加用户',
        //       subtitle: 'useradd [用户名]',
        //       isCompose: true
        //     }).onClick(() => {})
        //     CommonListItem({
        //       icon: $r('sys.symbol.key'),
        //       title: '修改密码',
        //       subtitle: 'passwd [用户名]',
        //       isCompose: true
        //     }).onClick(() => {})
        //     CommonListItem({
        //       icon: $r('sys.symbol.shield_checkered'),
        //       title: '切换到 root',
        //       subtitle: 'sudo su -',
        //       isCompose: true
        //     }).onClick(() => {})
        //   }
        // }

        // 软件包管理
        ListItem() {
          CommonItemContainer() {
            CommonListItem({
              // icon: $r('sys.symbol.storagebox'),
              title: '软件包管理',
              isCompose: true
            }) {}
            // CommonListItem({
            //   icon: $r('sys.symbol.loading'),
            //   title: '已安装软件包',
            //   subtitle: 'apk info',
            //   isCompose: true
            // }).onClick(() => {
            //   VMUtils.suspendAndExecuteCommand('apk info')
            // })
            CommonListItem({
              icon: $r('sys.symbol.loading'),
              title: '更新软件源',
              subtitle: 'apk update',
              isCompose: true
            }).onClick(() => {
              this.executeCommand('更新软件源', 'apk update')
            })
            CommonListItem({
              icon: $r('sys.symbol.arrow_up_circle'),
              title: '升级软件包',
              subtitle: 'apk upgrade',
              isCompose: true
            }).onClick(() => {
              this.executeCommand('升级软件包', 'apk upgrade')
            })
            // CommonListItem({
            //   icon: $r('sys.symbol.download_1'),
            //   title: '安装软件',
            //   subtitle: 'apk add [软件名]',
            //   isCompose: true
            // }).onClick(() => {
            //   // 这个命令需要用户输入参数，保留空实现
            // })
            // CommonListItem({
            //   icon: $r('sys.symbol.trash'),
            //   title: '卸载软件',
            //   subtitle: 'apk remove [软件名]',
            //   isCompose: true
            // }).onClick(() => {
            //   // 这个命令需要用户输入参数，保留空实现
            // })
            // CommonListItem({
            //   icon: $r('sys.symbol.magnifyingglass_circle'),
            //   title: '搜索软件包',
            //   subtitle: 'apk search [关键词]',
            //   isCompose: true
            // }).onClick(() => {
            //   // 这个命令需要用户输入参数，保留空实现
            // })
            // CommonListItem({
            //   icon: $r('sys.symbol.info_circle'),
            //   title: '软件包信息',
            //   subtitle: 'apk info [软件名]',
            //   isCompose: true
            // }).onClick(() => {
            //   // 这个命令需要用户输入参数，保留空实现
            // })
          }
        }

        // 系统资源
        ListItem() {
          CommonItemContainer() {
            CommonListItem({
              // icon: $r('sys.symbol.gauge_with_dots_needle_33percent'),
              title: '系统资源',
              isCompose: true
            }) {}
            CommonListItem({
              icon: $r('sys.symbol.memory_module'),
              title: '内存使用情况',
              subtitle: 'free -h',
              isCompose: true
            }).onClick(() => {
              this.executeCommand('内存使用情况', 'free -h')
            })
            CommonListItem({
              icon: $r('sys.symbol.strolling_machine'),
              title: 'CPU 信息',
              subtitle: 'cat /proc/cpuinfo',
              isCompose: true
            }).onClick(() => {
              this.executeCommand('CPU 信息', 'cat /proc/cpuinfo')
            })
            CommonListItem({
              icon: $r('sys.symbol.average_speed'),
              title: 'I/O 统计',
              subtitle: 'iostat',
              isCompose: true
            }).onClick(() => {
              this.executeCommand('I/O 统计', 'iostat')
            })
            // CommonListItem({
            //   icon: $r('sys.symbol.shock_load_rate_fill'),
            //   title: '系统负载',
            //   subtitle: 'w',
            //   isCompose: true
            // }).onClick(() => {
            //   VMUtils.suspendAndExecuteCommand('w')
            // })
          }
        }

        // 压缩解压
        // ListItem() {
        //   CommonItemContainer() {
        //     CommonListItem({
        //       icon: $r('sys.symbol.doc_zipper'),
        //       title: '压缩解压',
        //       isCompose: true
        //     }) {}
        //     CommonListItem({
        //       icon: $r('sys.symbol.externaldrive'),
        //       title: '解压 tar.gz',
        //       subtitle: 'tar -xzvf [文件.tar.gz]',
        //       isCompose: true
        //     }).onClick(() => {})
        //     CommonListItem({
        //       icon: $r('sys.symbol.arrow_up_house'),
        //       title: '压缩为 tar.gz',
        //       subtitle: 'tar -czvf [文件.tar.gz] [目录]',
        //       isCompose: true
        //     }).onClick(() => {})
        //     CommonListItem({
        //       icon: $r('sys.symbol.arrow_left_to_line'),
        //       title: '解压 zip',
        //       subtitle: 'unzip [文件.zip]',
        //       isCompose: true
        //     }).onClick(() => {})
        //     CommonListItem({
        //       icon: $r('sys.symbol.arrow_up_to_line'),
        //       title: '压缩为 zip',
        //       subtitle: 'zip -r [文件.zip] [目录]',
        //       isCompose: true
        //     }).onClick(() => {})
        //   }
        // }

        // 文本处理
        // ListItem() {
        //   CommonItemContainer() {
        //     CommonListItem({
        //       icon: $r('sys.symbol.textformat'),
        //       title: '文本处理',
        //       isCompose: true
        //     }) {}
        //     CommonListItem({
        //       icon: $r('sys.symbol.doc_text_magnifyingglass_fill'),
        //       title: '搜索文本内容',
        //       subtitle: 'grep [关键词] [文件]',
        //       isCompose: true
        //     }).onClick(() => {})
        //     CommonListItem({
        //       icon: $r('sys.symbol.line_3_horizontal'),
        //       title: '统计行数',
        //       subtitle: 'wc -l [文件]',
        //       isCompose: true
        //     }).onClick(() => {})
        //     CommonListItem({
        //       icon: $r('sys.symbol.sort'),
        //       title: '排序文件内容',
        //       subtitle: 'sort [文件]',
        //       isCompose: true
        //     }).onClick(() => {})
        //     CommonListItem({
        //       icon: $r('sys.symbol.natural_saturation_slash'),
        //       title: '去重',
        //       subtitle: 'uniq [文件]',
        //       isCompose: true
        //     }).onClick(() => {})
        //     CommonListItem({
        //       icon: $r('sys.symbol.edit_badge_star'),
        //       title: '文本编辑器',
        //       subtitle: 'nano [文件]',
        //       isCompose: true
        //     }).onClick(() => {})
        //   }
        // }
      }
      .padding({ left: 12, right: 12})
      .expandSafeArea()
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      .width('100%')
      .height('100%')
    }.title('常用功能')
    .width('100%').height('100%')
    .backgroundColor($r('sys.color.background_secondary'))
  }
}