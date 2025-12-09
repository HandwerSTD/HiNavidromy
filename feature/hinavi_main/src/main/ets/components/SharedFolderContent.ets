import { BusinessError, zlib } from '@kit.BasicServicesKit';
import { Want, common, wantConstant } from "@kit.AbilityKit"
import { fileUri, picker } from '@kit.CoreFileKit';
import { fileIo as fs } from '@kit.CoreFileKit'
import { CustomContentDialog, LoadingDialog, promptAction, PromptAction } from "@kit.ArkUI";
import { pasteboard } from '@kit.BasicServicesKit'
import validateFolderName from '../lib/validateFolderName'
import { util } from "@kit.ArkTS";
import appOption from '../model/appOption';
import { NavidromeServerUtils, VMUtils } from '../common/utils/NavidromeServerUtils';
import { NavidromeRequestUtil } from '../common/utils/NavidromeRequest';

enum Type {
  Folder = 0,
  File = 1,
  Unknown = 2
}

interface Entry {
  name: string
  type: Type
  size: number
  mtime: number
  detail: string
}

@ComponentV2
export struct SharedFolderContent {
  @Local host: string = ''
  @Local guest: string = ''
  @Local files: Entry[] = []
  @Local current: string[] = []
  @Local tempFolderName: string = ''
  importProgress: CustomDialogController = new CustomDialogController({
    builder: LoadingDialog({
      content: $r('app.string.importing_file_to_shared_folder'),
    }),
  })
  exportProgress: CustomDialogController = new CustomDialogController({
    builder: LoadingDialog({
      content: $r('app.string.exporting_file_to_shared_folder'),
    }),
  })
  removeProgress: CustomDialogController = new CustomDialogController({
    builder: LoadingDialog({
      content: '删除文件中',
    }),
  })
  backupProgress: CustomDialogController = new CustomDialogController({
    builder: LoadingDialog({
      content: '正在备份音乐库...',
    }),
  })
  importMusicProgress: CustomDialogController = new CustomDialogController({
    builder: LoadingDialog({
      content: '正在导入音乐库...',
    }),
  })
  restoreDbProgress: CustomDialogController = new CustomDialogController({
    builder: LoadingDialog({
      content: '正在恢复数据库...',
    }),
  })
  createFolderController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.create_folder'),
      contentBuilder: () => {
        this.buildNewFolderContent()
      }
    })
  })
  scroller: Scroller = new ListScroller()
  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();

  async aboutToAppear() {
    this.host = AppStorage.get(appOption.sharedHost) as string
    this.guest = AppStorage.get(appOption.sharedGuest) as string
    this.current = [this.host];
    await this.refreshFileList();
  }

  @Builder
  buildNewFolderContent() {
    Column() {
      TextInput({
        text: this.tempFolderName,
        placeholder: $r('app.string.input_folder_name')
      })
        .onChange((value) => {
          this.tempFolderName = value;
        })
      Button($r('app.string.SettingComplete_label'))
        .margin({ top: 10 })
        .width('100%')
        .enabled(validateFolderName(this.tempFolderName))
        .onClick(async () => {
          await this.createFolderToCurrent()
        })
    }
  }

  @Builder
  buildFileList() {
    List({ scroller: this.scroller }) {
      if (this.current.length > 1) {
        ListItem() {
          Row() {
            SymbolGlyph($r('sys.symbol.arrowshape_turn_up_left'))
              .fontSize(24)
              .fontColor([$r('sys.color.icon_secondary')])
              .margin({ right: 4 })

            Text('..')
              .fontSize(16)
          }
          .height(56)
          .width('100%')
          .clickEffect({ level: ClickEffectLevel.MIDDLE })
          .onClick(() => this.backToParent())
        }
      }

      ForEach(this.files, (item: Entry) => {
        ListItem() {
          Row() {
            SymbolGlyph(item.type === Type.Folder ?
              $r('sys.symbol.folder_fill') : $r('sys.symbol.doc'))
              .fontSize(24)
              .fontColor([$r('sys.color.icon_secondary')])
              .margin({ right: 8 })

            Column() {
              Text(item.name)
                .fontSize(16)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .ellipsisMode(EllipsisMode.END)
                .maxLines(1)
              Text(item.detail)
                .fontSize(11)
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            if (item.type === Type.File) {
              SymbolGlyph($r('sys.symbol.dot_grid_1x2'))
                .fontSize(24)
                .fontColor([$r('sys.color.icon_secondary')])
                .margin({ right: 8 })
                .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.8 })
                .bindMenu(this.getFileMenuItems(item))
            } else if (item.type == Type.Folder) {
              SymbolGlyph($r('sys.symbol.dot_grid_1x2'))
                .fontSize(24)
                .fontColor([$r('sys.color.icon_secondary')])
                .margin({ right: 8 })
                .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.8 })
                .bindMenu([{
                  value: $r('app.string.copy_guest_path'),
                  action: () => this.copyGuestPath(item.name)
                }, {
                  value: '删除文件夹',
                  action: () => {
                    const guest = [this.guest, ...this.current.slice(1), item.name].join('/')
                    if (guest === ('/mnt/share/music')) {
                      this.clearMusicFolder()
                    } else {
                      this.deleteFileOrFolder(item.name, Type.Folder)
                    }
                  }
                }])
            }
          }
          .height(56)
          .width('100%')
          .clickEffect(item.type !== Type.File ? { level: ClickEffectLevel.MIDDLE } : null)
          .onClick(() => this.openFileEntry(item))
        }
      }, (item: Entry) => item.name)
    }
    .divider({
      strokeWidth: 0.1,
      color: $r('sys.color.icon_secondary'),
      startMargin: 5,
      endMargin: 5
    })
    .layoutWeight(1)
    .borderRadius(12)
    .margin({ left: 8, right: 4, bottom: 8 })
    .scrollBarWidth(1)
  }

  openFile(name: string): void {
    const srcPath = [...this.current, decodeURI(name)].join('/')
    const uri = fileUri.getUriFromPath(srcPath)
    let want: Want = {
      action: 'ohos.want.action.viewData',
      uri: uri,
      flags: wantConstant.Flags.FLAG_AUTH_WRITE_URI_PERMISSION
    }
    let context = this.getUIContext().getHostContext() as common.UIAbilityContext
    context.startAbility(want)
      .then(() => {
        console.info('Succeed to invoke startAbility.');
      })
      .catch((err: BusinessError) => {
        console.error(`Failed to invoke startAbility, code: ${err.code}, message: ${err.message}`);
      });
  }

  async copyGuestPath(name: string): Promise<void> {
    const guest = [this.guest, ...this.current.slice(1), name].join('/')
    try {
      const board = pasteboard.getSystemPasteboard()
      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, guest)
      await board.setData(pasteData)

      const promptFormat = this.uiContext
        .getHostContext()?.resourceManager.getStringByNameSync('guest_path_copied_prompt')
      const prompt = util.format(promptFormat, guest)
      this.promptAction.showToast({
        message: prompt,
        duration: 4000
      })
    } catch (e) {
      console.log('error copy to clipboard ' + guest, e)
    }
  }

  build() {
    Column() {
      // 路径栏增强
      Row() {
        SymbolGlyph($r('sys.symbol.externaldrive_fill'))
          .fontSize(24)
          .fontColor([$r('sys.color.icon_secondary')])
          .margin({ left: 4 })

        Text(this.getGuestPath())
          .fontSize(16)
          .padding({ left: 4, right: 8 })
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .ellipsisMode(EllipsisMode.END)
          .maxLines(1)
          .layoutWeight(1)

        SymbolGlyph($r('sys.symbol.arrow_clockwise'))
          .fontSize(24)
          .fontColor([$r('sys.color.icon_secondary')])
          .padding(4)
          .borderRadius(4)
          .hoverEffect(HoverEffect.Highlight)
          .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.8 })
          .margin({ right: 5 })
          .onClick(() => this.refreshFileList())

        SymbolGlyph($r('sys.symbol.add_songlist'))
          .fontSize(24)
          .fontColor([$r('sys.color.icon_secondary')])
          .padding(4)
          .borderRadius(4)
          .hoverEffect(HoverEffect.Highlight)
          .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.8 })
          .margin({ right: 5 })
          .bindMenu([{
            value: $r('app.string.create_folder'),
            action: () => {
              this.tempFolderName = ''
              this.createFolderController.open()
            }
          }, {
            value: $r('app.string.import_file_to_shared_folder'),
            action: () => {
              this.importFileToCurrent()
            }
          }, {
            value: $r('app.string.import_file_to_music'),
            action: () => {
              this.importFileToCurrent(true)
            }
          }, {
            value: '备份音乐库',
            action: () => {
              this.backupMusicLibrary()
            }
          }, {
            value: '导入音乐库 (ZIP)',
            action: () => {
              this.importMusicLibrary()
            }
          }])
      }
      .height(56)

      // 文件列表区域
      if (this.current.length === 1 && this.files.length === 0) {
        Column() {
          Text($r('app.string.empty_shared_folder_prompt'))
            .textAlign(TextAlign.Center)
            .fontColor($r('sys.color.icon_secondary'))
            .fontSize($r('sys.float.Body_M'))
            .height('100%')
        }
        .layoutWeight(1)
      } else {
        this.buildFileList()
      }
    }
    .margin({ left: 5, right: 5 })
  }

  private getGuestPath() {
    let parts = [this.guest, ...this.current.slice(1)];
    let path = parts.join('/');
    if (path.startsWith('//')) {
      return path.substring(1)
    } else {
      return path
    }
  }

  private async saveFile(name: string) {

    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;

    const options = new picker.DocumentSaveOptions()
    options.newFileNames = [name];

    const savePicker = new picker.DocumentViewPicker(context)
    const uris = await savePicker.save(options)

    if (uris.length == 0) {
      return
    }

    const srcPath = [...this.current, decodeURI(name)].join('/')
    const destUri = uris[0]
    this.exportProgress.open()
    try {
      await copyFile(srcPath, destUri);
    } catch (e) {
      console.log('error copy file', srcPath, destUri, e)
    } finally {
      this.exportProgress.close()
    }
  }

  async importFileToCurrent(forceMusicFolder?: boolean) {
    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;

    let options = new picker.DocumentSelectOptions();
    options.maxSelectNumber = 500;

    let documentPicker = new picker.DocumentViewPicker(context);
    let uris = await documentPicker.select(options);

    if (uris.length == 0) {
      return
    }

    this.importProgress.open()
    for (let i = 0; i < uris.length; ++i) {
      const srcUri = uris[i]
      let destPath = [...this.current, decodeURI(srcUri.split('/').reverse()[0])].join('/')
      if (forceMusicFolder) {
        destPath = [this.host, 'music', decodeURI(srcUri.split('/').reverse()[0])].join('/')
      }
      try {
        await copyFile(srcUri, destPath);
        this.refreshFileList()
        this.promptAction.showToast({
          message: `完成 (${i+1}/${uris.length})`
        })
      } catch (e) {
        console.log('error copy file', srcUri, destPath, e)
      }
    }
    this.importProgress.close()
    VMUtils.suspendAndExecuteCommand('chmod -R o+rwx /mnt/share', false)
    if (forceMusicFolder) {
      setTimeout(async () => {
        await NavidromeRequestUtil.refreshLibrary()
        promptAction.showToast({
          message: '已通知 Navidrome 扫描音乐库'
        })
      }, 2000)
    }
  }

  async createFolderToCurrent(dest_name?: string) {
    const name = dest_name ?? this.tempFolderName
    const destPath = [...this.current, name].join('/')
    try {
      fs.mkdirSync(destPath)
    } catch (e) {
      console.log('error creating folder ' + destPath, e)
    }
    this.tempFolderName = ''
    this.createFolderController.close()
    this.refreshFileList()
  }

  private async openFileEntry(e: Entry) {
    if (e.type === Type.Folder) {
      this.current.push(e.name)
      await this.refreshFileList()
    } else if(e.type == Type.File) {
      this.openFile(e.name)
    }
  }

  private async backToParent() {
    this.current.splice(this.current.length - 1, 1)
    this.refreshFileList()
  }

  private clearMusicFolder() {
    this.getUIContext().showAlertDialog({
      title: '清空音乐库',
      message: '确认要清空音乐库吗？此操作不可逆',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '确认',
        fontColor: $r('sys.color.warning'),
        action: async () => {
          await this.performDelete('music')
          await this.createFolderToCurrent('music')
          promptAction.showToast({
            message: '清空音乐库完成'
          })
          // TODO: send request to navidrome for re-scan
        }
      }
    })
  }

  private async backupMusicLibrary() {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const musicPath = [this.host, 'music'].join('/');

    // 检查music文件夹是否存在
    try {
      const stat = fs.statSync(musicPath);
      if (!stat.isDirectory()) {
        this.promptAction.showToast({ message: '音乐库文件夹不存在' });
        return;
      }
    } catch (e) {
      this.promptAction.showToast({ message: '音乐库文件夹不存在' });
      return;
    }

    // 生成带时间戳的zip文件名
    const timestamp = new Date();
    const dateStr = `${timestamp.getFullYear()}${String(timestamp.getMonth() + 1).padStart(2, '0')}${String(timestamp.getDate()).padStart(2, '0')}_${String(timestamp.getHours()).padStart(2, '0')}${String(timestamp.getMinutes()).padStart(2, '0')}${String(timestamp.getSeconds()).padStart(2, '0')}`;
    const zipFileName = `music_backup_${dateStr}.zip`;

    // 拉起picker选择保存位置
    const options = new picker.DocumentSaveOptions();
    options.newFileNames = [zipFileName];

    const savePicker = new picker.DocumentViewPicker(context);
    let uris: string[];
    try {
      uris = await savePicker.save(options);
    } catch (e) {
      console.log('error saving file', e);
      return;
    }

    if (uris.length === 0) {
      return;
    }

    const destUri = uris[0];

    this.backupProgress.open();
    try {
      // 在临时目录创建zip文件
      const tempZipPath = context.tempDir + '/' + zipFileName;

      // 使用zlib压缩music文件夹
      const zipOptions: zlib.Options = {
        level: zlib.CompressLevel.COMPRESS_LEVEL_DEFAULT_COMPRESSION
      };

      await zlib.compressFile(musicPath, tempZipPath, zipOptions);

      // 将临时zip文件复制到用户选择的位置
      await copyFile(tempZipPath, destUri);

      // 删除临时文件
      try {
        await fs.unlink(tempZipPath);
      } catch (e) {
        console.log('error deleting temp zip file', e);
      }

      this.promptAction.showToast({
        message: '音乐库备份成功',
        duration: 3000
      });
    } catch (e) {
      console.log('error backing up music library', e);
      this.promptAction.showToast({
        message: '备份失败: ' + (e as BusinessError).message,
        duration: 3000
      });
    } finally {
      this.backupProgress.close();
    }
  }

  private async importMusicLibrary() {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;

    // 选择 ZIP 文件
    const options = new picker.DocumentSelectOptions();
    options.maxSelectNumber = 1;
    options.fileSuffixFilters = ['zip']

    const documentPicker = new picker.DocumentViewPicker(context);
    let uris: string[];
    try {
      uris = await documentPicker.select(options);
    } catch (e) {
      console.log('error selecting file', e);
      return;
    }

    if (uris.length === 0) {
      return;
    }

    const srcUri = uris[0];
    const fileName = decodeURI(srcUri.split('/').reverse()[0]);

    // 检查是否为 ZIP 文件
    if (!fileName.toLowerCase().endsWith('.zip')) {
      this.promptAction.showToast({
        message: '请选择 ZIP 文件',
        duration: 3000
      });
      return;
    }

    this.importMusicProgress.open();
    try {
      // 生成时间戳文件夹名
      const timestamp = new Date();
      const dateStr = `${timestamp.getFullYear()}${String(timestamp.getMonth() + 1).padStart(2, '0')}${String(timestamp.getDate()).padStart(2, '0')}_${String(timestamp.getHours()).padStart(2, '0')}${String(timestamp.getMinutes()).padStart(2, '0')}${String(timestamp.getSeconds()).padStart(2, '0')}`;

      // 创建目标文件夹 /mnt/share/music/yyyyMMdd_HHmmss/
      const destFolderPath = [this.host, 'music', dateStr].join('/');
      fs.mkdirSync(destFolderPath);

      // 复制 ZIP 文件到临时目录
      const tempZipPath = context.tempDir + '/' + fileName;
      await copyFile(srcUri, tempZipPath);

      // 解压 ZIP 文件到目标文件夹
      await zlib.decompressFile(tempZipPath, destFolderPath);

      // 删除临时 ZIP 文件
      try {
        await fs.unlink(tempZipPath);
      } catch (e) {
        console.log('error deleting temp zip file', e);
      }

      // 修改权限
      VMUtils.suspendAndExecuteCommand('chmod -R o+rwx /mnt/share', false);

      this.promptAction.showToast({
        message: '音乐库导入成功',
        duration: 3000
      });

      // 刷新文件列表
      await this.refreshFileList();

      // 通知 Navidrome 扫描
      setTimeout(async () => {
        await NavidromeRequestUtil.refreshLibrary();
        promptAction.showToast({
          message: '已通知 Navidrome 扫描音乐库'
        });
      }, 2000);
    } catch (e) {
      console.log('error importing music library', e);
      this.promptAction.showToast({
        message: '导入失败: ' + (e as BusinessError).message,
        duration: 3000
      });
    } finally {
      this.importMusicProgress.close();
    }
  }

  private deleteFileOrFolder(name: string, type: Type) {
    const typeStr = type === Type.File ? '文件' : '文件夹'
    this.getUIContext().showAlertDialog({
      title: '确认删除',
      message: `${typeStr}: ${name}`,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        fontColor: $r('sys.color.warning'),
        action: async () => {
          await this.performDelete(name)
        }
      }
    })
  }

  private async performDelete(name: string) {
    const fullPath = [...this.current, name].join('/')
    this.removeProgress.open()
    try {
      const stat = fs.statSync(fullPath)
      if (stat.isDirectory()) {
        await fs.rmdir(fullPath)
      } else if (stat.isFile()) {
        await fs.unlink(fullPath)
      }
      this.promptAction.showToast({
        message: '删除成功'
      })
      await this.refreshFileList()
    } catch (e) {
      console.log('error deleting file/folder ' + fullPath, e)
      this.promptAction.showToast({
        message: '删除失败'
      })
    } finally {
      this.removeProgress.close()
    }
  }

  private async refreshFileList() {
    const dir = this.current.join('/');
    const names = await fs.listFile(dir);
    this.files = names
      .filter(it => {
        return it !== '.virtfs_metadata' && it !== '.virtfs_metadata_root' && it !== '.hinavi_tmp'
      })
      .map((it) => {
        const full = dir + '/' + it;
        const stat = fs.statSync(full);
        let type: Type;
        if (stat.isDirectory()) {
          type = Type.Folder
        } else if (stat.isFile()) {
          type = Type.File
        } else {
          type = Type.Unknown
        }
        const e = {
          name: it,
          type,
          size: stat.size,
          mtime: stat.mtime
        } as Entry;
        e.detail = formatDetail(e)
        return e
      })
      .sort((a, b) => comparator(a, b));
    this.scroller.scrollTo({ yOffset: 0, xOffset: 0 })
  }

  private getFileMenuItems(item: Entry): MenuElement[] {
    const menuItems: MenuElement[] = [{
      value: $r('app.string.open_file'),
      action: () => this.openFile(item.name)
    }, {
      value: $r('app.string.export_file_from_shared_folder'),
      action: () => this.saveFile(item.name)
    }, {
      value: $r('app.string.copy_guest_path'),
      action: () => this.copyGuestPath(item.name)
    }, {
      value: '删除文件',
      action: () => this.deleteFileOrFolder(item.name, Type.File)
    }]

    // 如果是 .db 文件，添加恢复数据库选项
    if (item.name.toLowerCase().endsWith('.db')) {
      menuItems.push({
        value: '恢复 Navidrome 数据库',
        action: () => this.confirmRestoreDb(item.name)
      })
    }

    return menuItems
  }

  private confirmRestoreDb(name: string) {
    const guestPath = [this.guest, ...this.current.slice(1), name].join('/')
    this.getUIContext().showAlertDialog({
      title: '恢复数据库',
      message: `确认要使用 "${name}" 恢复 Navidrome 数据库吗？\n此操作将：\n1. 停止 Navidrome 服务\n2. 备份当前数据库\n3. 用选中的文件替换数据库\n4. 重启 Navidrome 服务`,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '确认恢复',
        fontColor: $r('sys.color.warning'),
        action: () => {
          this.restoreNavidromeDb(guestPath)
        }
      }
    })
  }

  private async restoreNavidromeDb(dbPath: string) {
    this.restoreDbProgress.open()
    try {
      await NavidromeServerUtils.recoverBackup(dbPath)
      this.promptAction.showToast({
        message: '数据库恢复成功',
        duration: 3000
      })
    } catch (e) {
      this.promptAction.showToast({
        message: `恢复失败: ${(e as Error).message}`,
        duration: 3000
      })
    } finally {
      this.restoreDbProgress.close()
    }
  }
}

function formatSize(entry: Entry) {
  let size: string;
  if (entry.size > 1024 * 1024 * 1024) {
    size = (entry.size / 1024 / 1024 / 1024).toFixed(1) + 'GB';
  } else if (entry.size > 1024 * 1024) {
    size = (entry.size / 1024 / 1024).toFixed(1) + 'MB';
  } else if (entry.size > 1024) {
    size = (entry.size / 1024).toFixed(1) + 'KB';
  } else {
    size = entry.size.toString() + 'B';
  }
  return size;
}

function comparator(a: Entry, b: Entry): number {
  const ka = a.type + '-' + a.name;
  const kb = b.type + '-' + b.name;
  return ka.localeCompare(kb)
}

function formatTimestamp(timestamp: number) {
  const date = new Date(timestamp);
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const hours = String(date.getHours()).padStart(2, '0');
  const minutes = String(date.getMinutes()).padStart(2, '0');
  const seconds = String(date.getSeconds()).padStart(2, '0');
  return `${year}/${month}/${day} ${hours}:${minutes}:${seconds}`;
}

function formatDetail(entry: Entry): string {
  try {
    let size: string = formatSize(entry);
    let mtime = formatTimestamp(entry.mtime * 1000)
    return `${mtime} - ${size}`
  } catch (e) {
    return '--'
  }
}

async function copyFile(srcPathOrUri: string, destPathOrUri: string) {

  const srcFile = await fs.open(srcPathOrUri, fs.OpenMode.READ_ONLY);
  const destFile = await fs.open(destPathOrUri, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);

  await fs.copyFile(srcFile.fd, destFile.fd)

  await fs.close(srcFile.fd);
  await fs.close(destFile.fd);
}
