import { GlobalStore, ImageTitleWelcomeTemplate, SymbolTitle, SystemImageUtils } from 'hinavi_main'
import { LoadingDialog, promptAction, router } from '@kit.ArkUI';
import appOption from 'hinavi_main/src/main/ets/model/appOption';
import { preferences } from '@kit.ArkData';
import { application, common, Want } from '@kit.AbilityKit';
import { NavidromeServerUtils, ServerLoadStatus,
  VMUtils } from 'hinavi_main/src/main/ets/common/utils/NavidromeServerUtils';
import WebTerminal from 'hinavi_main/src/main/ets/components/WebTerminal';
import { RetryUtil } from 'hinavi_main/src/main/ets/common/utils/CommonUtil';
import { DialogHelper } from '@pura/harmony-dialog';
import fs from '@ohos.file.fs';
import { zlib } from '@kit.BasicServicesKit';
import { picker } from '@kit.CoreFileKit';

@Entry
@ComponentV2
struct UpgradePage {

  @Local isForce: boolean = true
  @Local isFromV0: boolean = false

  backupProgress: CustomDialogController = new CustomDialogController({
    builder: LoadingDialog({
      content: '正在备份音乐库...',
    }),
  })

  private async backupMusicLibrary() {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const musicPath = [context.getApplicationContext().filesDir, 'share', 'music'].join('/');

    // 检查music文件夹是否存在
    try {
      const stat = fs.statSync(musicPath);
      if (!stat.isDirectory()) {
        promptAction.showToast({ message: '音乐库文件夹不存在' });
        return;
      }
    } catch (e) {
      promptAction.showToast({ message: '音乐库文件夹不存在' });
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

      promptAction.showToast({
        message: '音乐库备份成功',
        duration: 5000
      });
      // setTimeout(() => {
      //   (this.getUIContext().getHostContext()! as common.UIAbilityContext).terminateSelf()
      // }, 3000)
    } catch (e) {
      console.log('error backing up music library', e);
      promptAction.showToast({
        message: '备份失败: ' + (e as BusinessError<void>).message,
        duration: 3000
      });
    } finally {
      this.backupProgress.close();
    }
  }

  aboutToAppear(): void {
    this.checkForceUpdate()
    GlobalStore.isFirstOpenFinished = true
    NavidromeServerUtils.checkConnectionOnStart()
      .finally(() => {
        GlobalStore.serverStatus = ServerLoadStatus.SUCCESS
        SystemImageUtils.getStoredVersion(application.getApplicationContext())
          .then((res) => {
            if (res == 0) {
              this.isFromV0 = true
              this.getUIContext().showAlertDialog({
                title: '从 1.x 版本升级',
                message: '由于 2.0 版本对系统底层架构进行了重大变更，因此从 1.x 进行升级可能有数据库损坏无法启动的风险。我们已尽力帮您备份所有数据，确保您的数据不会发生损坏或丢失，但仍建议您提取一份您珍贵的音乐文件数据。\n\n点击下方按钮可以将您的音乐库进行备份导出，以方便您将来再次导入。',
                primaryButton: {
                  value: '导出音乐',
                  action: () => {
                    this.backupMusicLibrary()
                  }
                }
              })
              // V0 版本没有 qemu-ga，无法通过 agent 备份，使用命令行方式
              VMUtils.suspendAndExecuteCommand('rc-service navidrome stop ' +
                '&& cp /var/lib/navidrome/navidrome.db /mnt/share/hinavi_recent_backup.db' +
                '&& cp /var/lib/navidrome/navidrome.db-wal /mnt/share/hinavi_recent_backup.db-wal' +
                '&& cp /var/lib/navidrome/navidrome.db-shm /mnt/share/hinavi_recent_backup.db-shm', false)
              // 通过检查沙箱中备份文件是否存在来判断备份是否完成
              this.waitForV0Backup()
            }
          })
      })
  }

  private async waitForV0Backup() {
    const sharedHost = AppStorage.get(appOption.sharedHost) as string
    const backupFilePath = sharedHost + '/hinavi_recent_backup.db'
    try {
      await RetryUtil.retryIf(40, async () => {
        const exists = fs.accessSync(backupFilePath, fs.AccessModeType.EXIST)
        if (!exists) throw new Error('Backup file not found')
      }, () => {
        return !fs.accessSync(backupFilePath, fs.AccessModeType.EXIST)
      })
      // 备份完成
      GlobalStore.todayBackupFinished = true
      promptAction.showToast({
        message: '1.x 数据备份已完成',
        duration: 5000
      })
    } catch (e) {
      // 备份失败，不设置标志，让用户点击更新时处理
    }
  }

  private async checkForceUpdate() {
    const context = this.getUIContext().getHostContext()!.getApplicationContext()
    this.isForce = await SystemImageUtils.hasForceUpdateTillNow(context)
  }

  @Builder Title() {
    SymbolTitle({
      icon: $r('sys.symbol.arrowshape_up_frame_fill'),
      gradientColor: ['#317af7', '#0a59f7']
    })
  }

  @Builder Footer() {
    if (GlobalStore.serverStatus !== ServerLoadStatus.LOADING) {
      Column({ space: 12 }) {
        if (!this.isForce) {
          Button('跳过更新')
            .onClick(() => {
              this.onSkipClick()
            })
            .width('100%')
            .constraintSize({
              maxWidth: 640
            })
            .buttonStyle(ButtonStyleMode.NORMAL)
        }

        Button('立即更新')
          .onClick(() => {
            this.onUpgradeClick()
          })
          .width('100%')
          .constraintSize({
            maxWidth: 640
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    } else {
      LoadingProgress().height(40)
    }
  }

  private async onUpgradeClick() {
    const id = DialogHelper.showLoadingDialog({
      content: '请等待数据库备份完成'
    })
    RetryUtil.retryIf(30, async () => {
      if (!GlobalStore.todayBackupFinished) throw Error()
    }, () => { return !GlobalStore.todayBackupFinished})
      .then(async () => {
        const context = this.getUIContext().getHostContext()!.getApplicationContext()
        const pref = await preferences.getPreferences(context, appOption.preferenceName)
        // 标记重置 Linux
        await pref.put(appOption.resetLinuxFlag, true)
        // 更新系统版本号
        await SystemImageUtils.updateToCurrentVersionByPref(pref)
        await pref.flush()
        this.restartApp()
      })
      .catch(() => {
        DialogHelper.closeDialog(id)
        this.getUIContext().showAlertDialog({
          message: '等待数据库备份失败，请点击退出程序，等待一分钟后再打开应用尝试',
          primaryButton: {
            value: '退出程序',
            action: () => {
              (this.getUIContext().getHostContext()! as common.UIAbilityContext).terminateSelf()
            }
          }
        })
      })
  }
  private restartApp() {
    const applicationContext = this.getUIContext().getHostContext()!.getApplicationContext()
    const want: Want = {
      bundleName: 'top.handwer.hish.hinavidromy',
      abilityName: 'EntryAbility',
      parameters: {
        "upgrade": true
      }
    }
    applicationContext.restartApp(want)
  }

  private async onSkipClick() {
    const context = this.getUIContext().getHostContext()!.getApplicationContext()
    await SystemImageUtils.ignoreCurrentVersionUpdate(context)
    this.getUIContext().getRouter().replaceUrl({
      url: 'pages/HiNaviEntry'
    })
  }

  private getSubtitle(): string {
    let baseText = 'HiNavidromy 的系统软件包有重大升级，升级新版本可以获得更流畅、更稳定的体验。新版本包含性能优化和问题修复，建议您立即更新以获得最佳使用体验。'
    if (!this.isForce) {
      baseText += '\n\n本次更新为可选更新，您可以选择忽略此更新，忽略更新不会影响您的正常使用。'
    } else {
      baseText += '\n\n本次更新为强制更新，这意味着应用引入了重大、与前代版本不兼容的升级优化，您必须更新才能继续正常使用。'
    }
    return baseText + '\n\n软件更新不会导致您的音乐库、听歌数据发生损坏或丢失，在更新完成后，您可以像往常一样继续使用。'
  }

  build() {
    Column() {
      ImageTitleWelcomeTemplate({
        title: '系统更新',
        customImage: () => { this.Title() },
        subtitle: this.getSubtitle(),
        footer: () => { this.Footer() }
      })
      WebTerminal().height(1).opacity(0)
    }
    .height('100%')
    .width('100%')
  }
}

async function copyFile(srcPathOrUri: string, destPathOrUri: string) {

  const srcFile = await fs.open(srcPathOrUri, fs.OpenMode.READ_ONLY);
  const destFile = await fs.open(destPathOrUri, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);

  await fs.copyFile(srcFile.fd, destFile.fd)

  await fs.close(srcFile.fd);
  await fs.close(destFile.fd);
}
